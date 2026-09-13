# 0003. How MSI changes are verified

- **Status:** Accepted
- **Date:** 2026-09-13
- **Deciders:** @chris-rock
- **Consulted / Informed:** Mondoo Engineering

## Context

MSI defects fall into two classes with different detection costs.

The first is build-time. WiX splits compilation from linking: `candle` compiles
a `.wxs` in isolation, and `light` resolves references across the whole product
and runs the ICE validation suite. Errors of this class are therefore invisible
to `candle` and surface only under `light`. Two such errors have reached `main`
and left the repository unable to build a package: `LGHT0094`, an unresolved
action reference, and `ICE18`, a keypath violation. No pull-request check ran
`light`; the only job that did was the packaging job, which requires the
release binaries and runs at release time or by manual dispatch.

The second class is runtime and no build detects it. Whether an installer
replaces an existing product or installs a second one beside it, whether an
install-time property reaches the machine, and whether a self-updating binary
corrects the version Windows reports are all properties of an installation
rather than of a package.

## Decision

We will verify MSI changes at two levels, and treat them as answering different
questions.

**Every pull request runs `candle` and `light` with ICE validation.** The
`Lint: WiX MSI sources` job stubs the payload binaries, because `light` needs
them to exist but never inspects them, and links both architectures. Both are
linted because they take different preprocessor branches, and one can link
while the other does not. It runs after the cheap lints, since it needs a
Windows runner and there is no sense starting one for a branch that fails
shellcheck.

**Behaviour is verified by installing on a Windows machine**, and the following
scenarios are the ones that have actually caught something. A change touching
installation, upgrade or properties should walk them.

| # | Scenario | What it answers |
|---|---|---|
| 1 | Fresh install on a clean machine | The package installs, the service registers, the registry values the binary depends on are written |
| 2 | Upgrade from the previous **stable** release | The common path. The old product is removed, exactly one entry remains in Add/Remove |
| 3 | Upgrade from a release **without** the feature under test | The real rollout: most machines are running something older than the change |
| 4 | Install one pre-release over another | Release candidates share a `ProductVersion`, so they are indistinguishable to Windows Installer |
| 5 | Repair, `msiexec /i <msi> REINSTALL=ALL REINSTALLMODE=vomus` | Repair rewrites registration from the package, undoing anything the binary corrected |
| 6 | Uninstall | Registry keys and environment variables are removed, nothing leaks |
| 7 | Install an older package, then let the binary self-update | The binary and the package disagree about the version from then on |
| 8 | Install-time properties, set and unset | A property that defaults to doing nothing has to actually do nothing |

Four of these have non-obvious outcomes, measured on Windows 11 ARM64:

- **4** returns exit code 0 and changes nothing. `WixExitEarlyWithSuccess`
  runs and the installed ProductCode is unchanged, so the result is reported as
  success while the machine keeps the earlier build.
- **5** returns 0 and reverts `DisplayVersion` from the value the binary wrote
  to the package's `ProductVersion`. The correction is therefore reconciled on
  every update check rather than once after an update.
- **7** leaves the version record uncorrected on a machine whose package
  predates the registry key the correction depends on, because a self-update
  replaces the binary and never runs an installer.
- **3** is the state of every machine already in the field at the time a
  packaging change ships.

**A scenario that has not been run is reported as not run.** A passing build is
evidence about the package, not about an installation.

## Security implications

None - this decision describes how changes are tested and adds no runtime
component. It reduces risk indirectly: an installer that fails to replace an
older product, or leaves credentials-adjacent registry state behind on
uninstall, is a security-relevant defect, and scenarios 2, 4 and 6 exist to
catch exactly that.

- **Threat model:** Unchanged.
- **Data handling:** Test machines should not be registered against a
  production space. Use a throwaway registration or none.
- **Residual risk:** The verification machine is a single architecture. An
  error specific to the other one is caught by the linter at build time but not
  at runtime.

## Performance implications

The pull-request lint adds roughly 25 seconds and one Windows runner, and only
when `packages/msi/**` changed. That is set against a multi-minute packaging
run that previously had to be dispatched by hand to learn the same thing.

Runtime verification is manual and takes 20-30 minutes for the full set. It is
not on any automated path.

## Consequences

### Positive

- Link and ICE errors are caught on the pull request rather than by a release.
- The scenarios are recorded, so verification does not depend on recall.
- The distinction between "it builds" and "it behaves" is explicit, which makes
  an unverified change visible rather than implied.

### Negative

- Runtime verification is manual and therefore skippable.
- One test machine covers one architecture and one Windows version.
- The scenario list holds only as long as new outcomes are added to it.

### Follow-up

- Automate what can be automated: scenarios 1, 2, 4 and 6 are scriptable
  against a Windows runner with stub payloads.
- Cover the x64 package and the enterprise SKU, neither of which has been
  installed.

## Alternatives considered

### Option A - Rely on the packaging job

It already builds an MSI, so both build-time errors would surface there.
Rejected: it runs at release time or by manual dispatch, so the signal arrives
after merge rather than before it.

### Option B - Run the ICE suite with `smoke.exe` on a built MSI

Equivalent validation, but it still needs a built MSI and therefore the release
binaries. The stubbed link gives the same signal without them.

### Option C - Automate the runtime scenarios now

The right end state. Rejected as a first step because several scenarios need
two packages of different versions, and building those on demand is a larger
piece of work than the linter that prevents the more common failure.

## References

- [ADR 0001 - The binary owns its reported version on Windows](0001-the-binary-owns-its-reported-version-on-windows.md)
- [ADR 0002 - The release pipeline](0002-the-release-pipeline.md)
- [Windows Installer ICE reference](https://learn.microsoft.com/en-us/windows/win32/msi/ice-reference)
