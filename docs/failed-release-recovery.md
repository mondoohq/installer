# Recovering from a Failed Release

This document is for when `PKG: Package, Release, Reindex` has failed partway through a release. The pipeline itself is described in [ADR 0002](adr/0002-the-release-pipeline.md).

## What a failed release looks like

The Linux, macOS and MSI builds run independently of each other. If one fails, the others may already have uploaded their files to `mondoo/<version>/` in the bucket.

`reindex` waits for all three, so it is skipped, and so is everything after it: Arch, Chocolatey, Homebrew and the container image. `latest.json` does not move.

The GitHub release for the version exists and looks published, but the version is partial. If the Linux build failed before its upload step, the GitHub release has no assets.

If the Linux build itself succeeded, the apt and yum repositories may already have been told about the version, because that dispatch happens inside the Linux job.

## Recommended: cut a patch release

Merge the fix to `main`, then run the normal chain from ADR 0002 for a new patch version. The new tag carries the fixed workflow, and nothing that was already published gets replaced.

The folder of the partial version can stay in the bucket. Channel documents point at the highest version (ADR 0002, step 8), so it is never offered.

## Why re-running the failed run does not help

A re-run uses the workflow from the commit of the tag. A fix merged to `main` is not in that commit, so the re-run fails the same way.

## If you must keep the same version

Dispatch `PKG: Package, Release, Reindex` from `main`, with the same `version`. This uses the fixed workflow. Keep these constraints in mind:

- It rebuilds and re-signs macOS and MSI, and overwrites the files in the bucket with a plain `gsutil cp`. There is no "already published" guard. Expect new hashes, because signing and notarization add timestamps. This is expected, not measured. The Linux packages are rebuilt and overwritten the same way.
- Only do this for a version that never reached `reindex`.
- Never do this for a fully released version. The Homebrew cask pins the SHA-256 of the file at its exact `releases.mondoo.com` URL, taken from `latest.json`. Replacing the pkg breaks `brew install` with a checksum mismatch.
- If a run got past `reindex` and has to be repeated, set the `reindex-path` input (for example `mondoo/14.11.0`). It removes `artifacts.json` and `index.html` at that path before reindexing.

## Linux-only recovery

These steps have not been run end to end. They are derived from the workflows, so check each one against `release_mondoo_pkgs.yaml` and the `reindex` job in `pkg_published_trigger_build_release.yaml` before you run it.

This path avoids replacing the macOS and MSI files, which already uploaded.

1. Dispatch `Build & Release mondoo Meta-Package` from `main`. Give `version` without a leading `v`, for example `14.11.0`.
2. Run `releasr release cp` for the mql and cnspec GitHub releases of that version, copying them into the bucket (as the `reindex` job does).
3. Run `releasr idx "gs://<bucket>" --app "mondoo/<v>,mql/<v>,cnspec/<v>" --update-parent`.
4. Restart the `minstaller` Cloud Run service, and invalidate the `releases-mondoo-io` CDN cache. The invalidation takes about 10 minutes.
5. Confirm that `https://releases.mondoo.com/mondoo/latest.json?ignoreCache=1` shows the version.
6. Dispatch the remaining workflows for the version:
   - Homebrew: `Update for Release` in `mondoohq/homebrew-mondoo`
   - `PKG: Chocolatey NuGet Release`
   - `PKG: Archlinux AUR Release`
   - `Release Mondoo Container Image`

`releasr` and `minstaller` are internal tools. The `reindex` job is the reference for the exact commands and credentials.

## `skip-publish` is not a complete no-op

`skip-publish` blocks the uploads. On the full workflow, the CDN invalidation and the Slack notifications still run, and `minstaller-dev` is restarted.
