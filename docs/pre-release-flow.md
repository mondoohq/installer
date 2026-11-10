# Pre-Release Flow for mql and cnspec

This document describes the steps required to publish a pre-release (RC) for `mql` and/or `cnspec`.

## 1. Create a GitHub Release

1. Go to the **Releases** page of the relevant GitHub repository:
   - `mql`: https://github.com/mondoohq/cnquery/releases/new
   - `cnspec`: https://github.com/mondoohq/cnspec/releases/new
2. Enter the tag name, e.g. `v13.0.0-rc4`, and choose the appropriate branch.
3. **Check** the **"Set as a pre-release"** checkbox.
4. **Uncheck** the **"Set as the latest release"** checkbox.
5. Click **Publish release**.

## 2. Run the GoReleaser Pipeline

Trigger the GoReleaser GitHub Actions workflow for the repository. This builds all binaries, packages, and container images and attaches them to the GitHub release created in step 1.

The unstable/RC pipeline uses `.github/.goreleaser-unstable.yml`.

## 3. Copy Artifacts to the Bucket

This step is automatic. Once cnspec dispatches to this repository, the installer GitHub release for the version is created, and publishing it triggers `PKG: Package, Release, Reindex` in this repository (see [ADR 0002](adr/0002-the-release-pipeline.md), step 7). Its `reindex` job copies the mql and cnspec binaries from their GitHub releases into the bucket and regenerates the indexes for every channel, pre-releases included.

To redo it, dispatch that workflow with `version` (for example `v13.0.0-rc4`) and `bucket`:

```bash
gh workflow run pkg_published_trigger_build_release.yaml --ref main \
  -f version=v13.0.0-rc4 \
  -f bucket=releases-com-test
```

Use `releases-com-test` to try it, and `releases-us.mondoo.io` for production.

The workflow also rebuilds the Linux, macOS and MSI packages for the version. See [Recovering from a Failed Release](failed-release-recovery.md) before dispatching it for a version that is already published.
