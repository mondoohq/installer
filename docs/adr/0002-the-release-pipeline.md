# 0002. The release pipeline runs mql, then cnspec, then this repository

- **Status:** Accepted
- **Date:** 2026-09-13
- **Deciders:** @chris-rock
- **Consulted / Informed:** Mondoo Engineering

## Context

A release is produced by four repositories acting in sequence. The steps are
defined across workflows in `mondoohq/mql`, `mondoohq/cnspec`, this repository
and the publishing tooling, and no single document describes the order or the
handoffs between them.

The repositories differ in visibility. `mondoohq/mql` and `mondoohq/cnspec` are
public. The tooling that writes to the bucket behind `releases.mondoo.com` is
private. This repository is public and already invokes that tooling, which is
why the publishing half of the pipeline lives here rather than in the product
repositories.

Releases are cut on two lines concurrently: `main` produces the current major,
and a `v{major}` branch produces the previous one. Both use the same pipeline.

## Decision

We will release in this order, with one manual step.

**1. Tag mql.** A human pushes a lightweight tag, `vMAJOR.MINOR.PATCH` or a
pre-release such as `v14.0.0-rc.6`. Everything downstream derives from that tag.

**2. mql builds and classifies.** `goreleaser.yml` derives the release channel
from the tag's semver pre-release segment: a segment present means `preview`,
absent means `stable`. Build metadata is not a pre-release segment, so
`8.4.0+41` is stable. The channel decides what is promoted, never whether the
release happens. mql publishes its own GitHub release and dispatches to cnspec.

**3. cnspec bumps its mql pin.** `mql-update.yml` receives the dispatch and
opens a pull request moving `go.mod` and `VERSION` to the released mql. Where
mql's module path carries no major suffix, the tag is resolved to a commit and
pinned as a pseudo-version, because Go rejects a v2+ semver reference against
an unsuffixed path.

**4. A human merges that pull request.** This is the only manual step, and it
is deliberate: it is the point where someone confirms the two projects are
compatible before a release is cut.

**5. cnspec tags itself.** `auto-tag-after-mql-bump.yml` fires on the merge,
reads the version out of the bump branch name, and tags **the commit the pull
request produced** rather than wherever the branch has since moved. It pushes
with an app token, because a push authenticated by `GITHUB_TOKEN` does not
trigger further workflows.

**6. cnspec builds and dispatches here.** Same channel derivation as mql. It
publishes its GitHub release and dispatches to this repository.

**7. This repository publishes.** The channel is derived again from the version
rather than taken from the dispatch payload, so a caller that sends no channel
still gets the right answer. Then:

- the binaries for **both** mql and cnspec are copied from their GitHub
  releases into the bucket behind `releases.mondoo.com`, and the indexes are
  regenerated. This runs for every channel.
- the Windows MSI and the macOS pkg are built, signed and published for every
  channel, because each publishes a versioned artifact and nothing else.
- apt, yum, Chocolatey, Homebrew and AUR are **stable only**. Each has a single
  distribution with no notion of a channel, so a release candidate published
  there would reach every machine that never asked for one.

**8. The channel documents move.** Membership is computed from each version's
semver, not declared: `latest.json` points at the highest version with no
pre-release segment, `preview.json` at the highest version overall. So preview
is never behind stable, and a preview client is not downgraded when a GA lands
over the release candidate it is running.

## Security implications

- **Threat model:** Unchanged by writing this down. The pipeline's trust
  boundaries are the cross-repository dispatches and the credentials that
  publish to the bucket. A dispatch is accepted only from the expected sender,
  and publishing credentials live in this repository rather than in the public
  product repositories, which is why this repository is the seam.
- **Data handling:** No customer data. The artifacts are public releases.
- **Authentication and authorization:** Tagging mql requires push access.
  Merging the bump pull request requires review. The app token that tags cnspec
  is scoped to that repository. Nothing in the chain can publish without one of
  those three.
- **Supply chain:** The chain is the supply chain. Each hop is a signed commit
  or a scoped token, and the artifacts published to the bucket come from the
  GitHub releases rather than being rebuilt, so what is served is what was
  built and signed.
- **Residual risk:** Step 4 is the only human gate in the chain. Merging the
  bump pull request releases whatever mql tagged. We accept this; the
  alternative is a second approval on a step that is already reviewed.

## Performance implications

None - this records an existing pipeline and changes no runtime path. For
reference, a release takes roughly twenty minutes end to end, dominated by
signing and notarization.

## Consequences

### Positive

- The path is written down once, in the repository that sits at the seam, so
  "where did the release stop" is answerable without reading three repositories'
  workflows.
- The channel is derived at every hop rather than passed along, so a stale
  caller cannot publish a release candidate to the stable channel.
- Only one step needs a person, and it is the step where judgement is wanted.

### Negative

- The dispatch payload and the bump branch name are contracts between
  repositories. A change to either has to land in both, and nothing enforces
  that beyond review.
- A release stalls silently at step 4. mql is tagged and published, and no
  signal is raised that the bump pull request is open.
- Providers are not part of this pipeline. They publish into a single
  namespace with no channel, so a pre-release does not start a provider
  release.

### Follow-up

- Give providers a channel, so a pre-release can publish them without reaching
  stable clients.
- Consider notifying when a bump pull request has been open long enough to be
  forgotten.

## Alternatives considered

### Option A - Drive the whole chain from one repository

A single workflow that tags mql, waits, bumps cnspec, tags it and publishes.
Rejected: it needs write access to every repository from one place, and it
turns a chain that can be resumed at any hop into one that restarts from the
beginning.

### Option B - Let cnspec and mql publish to the bucket directly

Fewer hops. Rejected because both are public and the publishing tools are not;
the credentials and the tool names would have to live in public repositories.

### Option C - Automate the bump merge as well

Fully hands-off. Rejected for now: the merge is the point at which the two
projects are confirmed compatible. Removing it makes an incorrect mql tag
propagate to a cnspec release without review.

## References

- [ADR 0001 - The binary owns its reported version on Windows](0001-the-binary-owns-its-reported-version-on-windows.md)
- [SemVer 9 and 10 - pre-release and build metadata](https://semver.org/#spec-item-9)
