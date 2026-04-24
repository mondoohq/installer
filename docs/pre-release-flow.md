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

## 3. Copy Artifacts to GCS Buckets

After GoReleaser completes, copy the release artifacts to the GCS buckets using the `github_copy.yaml` workflow.

Run the workflow for each bucket you want to populate. Replace `<repository>`, `<version>`, and `<bucket>` with the appropriate values.

### For mql

```bash
# Test bucket (releases.mondoo.love)
gh workflow run github_copy.yaml --ref main \
  -f repository=mql \
  -f version=v13.0.0-rc4 \
  -f bucket=releases-com-test

# Production bucket (releases.mondoo.io)
gh workflow run github_copy.yaml --ref main \
  -f repository=mql \
  -f version=v13.0.0-rc4 \
  -f bucket=releases-us.mondoo.io
```

### For cnspec

```bash
# Test bucket (releases.mondoo.love)
gh workflow run github_copy.yaml --ref main \
  -f repository=cnspec \
  -f version=v13.0.0-rc4 \
  -f bucket=releases-com-test

# Production bucket (releases.mondoo.io)
gh workflow run github_copy.yaml --ref main \
  -f repository=cnspec \
  -f version=v13.0.0-rc4 \
  -f bucket=releases-us.mondoo.io
```

> **Note:** The `github_copy.yaml` workflow lives in the installer repository (`go.mondoo.com/installer`). The `repository` field must match the product name used in the release URL (`mql` or `cnspec`).
