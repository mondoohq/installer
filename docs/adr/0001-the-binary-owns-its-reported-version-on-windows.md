# 0001. The binary owns its reported version on Windows

- **Status:** Accepted
- **Date:** 2026-09-13
- **Deciders:** @chris-rock
- **Consulted / Informed:** Mondoo Engineering

## Context

cnspec updates itself. On Windows that update replaces the running executable
in place, including the copy the MSI installed into `C:\Program Files\Mondoo`.
Windows Installer is not told, and cannot be: its cached `ProductVersion` is
part of the installation database and only an install, patch or upgrade
changes it.

So a machine carries two version records that disagree the moment an update
lands. Measured on Windows 11 ARM64 with the released 14.0.0-rc.5 package:

| record | reads | who writes it |
|---|---|---|
| `Uninstall\{ProductCode}\DisplayVersion` | what Add/Remove Programs and registry inventory show | Windows Installer at install; now also the binary |
| MSI cached `ProductVersion` | what `MsiGetProductInfo`, `Win32_Product` and `Get-Package` return | Windows Installer only |

A second, smaller drift exists before any update. `ProductVersion` accepts
four numeric fields and nothing else, so a pre-release installs under its
semver core: `14.0.0-rc.5` registers as `14.0.0`. Every release candidate in a
series is therefore identical as far as Windows Installer is concerned.

That has a consequence we measured rather than assumed. Installing one release
candidate over another returns exit code 0, runs `WixExitEarlyWithSuccess`,
and changes nothing — the ProductCode on disk is unchanged afterwards. An
operator or a deployment tool sees success while the machine keeps the old
build.

The drift is not cosmetic. Our own Windows package resource enumerates the
Uninstall keys and reports `DisplayVersion`, so before this work a scan of a
Windows host misreported Mondoo's own version.

## Decision

We will treat the installed binary as the authority on which version is
present, and the MSI as a delivery vehicle rather than a version manager.

Three things follow.

**The binary corrects `DisplayVersion` after it updates itself.** It finds the
Add/Remove entry through `HKLM\SOFTWARE\Mondoo\ProductCode`, published by the
MSI because the ProductCode is regenerated on every build and cannot be
compiled in. The correction is reconciled on every update check, not only when
an update lands, because a repair rewrites the value from `ProductVersion`.

**The MSI does not silently walk the version backwards.** It already exited
early when a newer version was installed; that stays the default. `ALLOWDOWNGRADE=1`
overrides it, matching the property name and behaviour of Chrome's enterprise
MSI. Because release candidates share a `ProductVersion`, this is also the only
way to move between them.

**We do not give the MSI its own version number space.** Chrome maps its
four-part version into MSI's three comparable fields and runs a lookup service
for the mapping. We do not need one: our `ProductVersion` is the semver core,
and GA versions are already three-field and monotonic. Collisions occur only
within a single pre-release series, never between GA releases.

## Security implications

- **Threat model:** Unchanged in kind, widened slightly in reach. The binary
  now writes to `HKLM\...\Uninstall\{ProductCode}\DisplayVersion`, which
  requires administrative rights it already needed to replace a file under
  `C:\Program Files`. It writes only to the ProductCode the installer
  published, and only a version string; it does not enumerate or modify other
  products' entries. An attacker who can make the binary write a false
  `DisplayVersion` can already replace the binary itself, which is the larger
  problem.
- **Data handling:** One version string. No credentials, tokens, or customer
  data. `UPDATECHANNEL` writes a machine environment variable whose value is
  `stable` or `preview`.
- **Authentication and authorization:** Writing the Add/Remove entry needs
  local administrator. A non-elevated `cnspec update` fails the write and logs
  a warning; the update itself still succeeds, so the failure mode is a stale
  version record rather than a broken install.
- **Supply chain:** No new dependencies. `golang.org/x/sys/windows/registry`
  was already in use for read-only registry access elsewhere.
- **Residual risk:** `DisplayVersion` becomes a value the application controls
  rather than one only Windows Installer sets. Inventory tooling that treats it
  as installer-authoritative is now reading an application-authoritative value.
  We accept this: it is the value that is *correct*, and MSI-native detection
  (`MsiGetProductInfo`) still reports the installer's own number, verified on a
  live machine.

## Performance implications

None measurable. The reconcile is one registry read per update check — at most
once per refresh interval, not per invocation — and a write only when the
value disagrees. No scan path, build step, or runtime hot path is touched.

## Consequences

### Positive

- Add/Remove Programs, registry inventory, and `cnspec` itself report the
  version that is actually installed.
- Release candidates can be installed over one another, which was not possible
  before and failed silently when attempted.
- An administrator can put a machine on the preview channel at install time
  with `UPDATECHANNEL=preview`, rather than editing `mondoo.yml` afterwards.

### Negative

- Two version records still exist and can disagree. `DisplayVersion` tracks the
  binary; `MsiGetProductInfo` tracks the package. Anyone comparing the two will
  find a difference and needs this document to know which is which.
- A deployment tool that detects compliance by reading `DisplayVersion` will
  see a machine that self-updated past the deployed version as non-compliant,
  and may reinstall. That reinstall is now a silent no-op unless
  `ALLOWDOWNGRADE=1` is passed, so it does not downgrade the machine, but it
  also does not stop the tool reporting drift. Fleet version control belongs in
  the update settings, not in MSI version pinning.
- `msiexec /f` rewrites `DisplayVersion` from `ProductVersion`, undoing the
  correction until the next update check reconciles it. Measured: a repair
  returns 0 and reverts `14.0.0-rc.5` to `14.0.0`.
- `ALLOWDOWNGRADE` is a footgun by design. It removes the installed product
  before installing the incoming one, whatever their relative versions.

### Follow-up

- Verify on the x64 package and the enterprise SKU. Both were reasoned about
  and neither was built or installed during this work; only ARM64 standard was.
- Decide whether `UPDATECHANNEL` should also be settable on Linux and macOS
  packages, which have no equivalent today.
- Revisit if a deployment tool turns out to reinstall in a loop against
  `DisplayVersion`; the alternative is to stop correcting it and expose the
  running version only through `HKLM\SOFTWARE\Mondoo`.

## Alternatives considered

### Option A - Leave DisplayVersion alone and report the true version elsewhere

Write the running version only to `HKLM\SOFTWARE\Mondoo`, leaving Add/Remove
showing the packaged version. Nothing that reads `DisplayVersion` changes
behaviour, so no deployment tool is surprised. Rejected because it leaves the
place everyone actually looks — Add/Remove Programs, and every inventory tool
including our own — showing a version that is not installed, which is the
problem we set out to fix.

### Option B - Give the MSI its own version number space, as Chrome does

Encode the full version into MSI's comparable fields so every build has a
distinct `ProductVersion`, the way Chrome maps `98.0.4758.82` to `68.165.32870`.
Rejected: Chrome needs it because a four-part version does not fit, and ours
does. GA versions are already three-field and monotonic, and collisions occur
only inside one pre-release series. The mapping adds a translation between two
version spaces and, in Chrome's case, a service to reverse it.

### Option C - Disable self-update for MSI-managed installs

Let the MSI own the version outright, as the package manager does on Linux
where Chrome has no updater at all. Coherent, and it removes the drift rather
than reconciling it. Rejected because it would remove auto-update from the
majority of Windows installs, which is the mechanism that gets fixes onto
machines quickly.

### Option D - Accept the rollback and document it

Let an older MSI downgrade a self-updated binary; it updates itself again
within the refresh interval. Rejected because the window is real, is permanent
on a machine that is offline or has auto-update disabled, and recurs on every
deployment cycle.

## References

- [Chromium CL 749133003 — "Add fixing of MSI DisplayVersion to Chrome installs/updates"](https://codereview.chromium.org/749133003/)
- [Chromium issue 40497739 — MSI DisplayVersion to match Chrome version](https://issues.chromium.org/issues/40497739)
- [Chrome Enterprise — downgrade with ALLOWDOWNGRADE](https://support.google.com/chrome/a/answer/7125792)
- [Windows Installer — Uninstall registry key](https://learn.microsoft.com/en-us/windows/win32/msi/uninstall-registry-key)
