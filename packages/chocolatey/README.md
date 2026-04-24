# Chocolatey Packages

Chocolatey is a popular package manager for Windows, similar to Homebrew. This directory generates and publishes NuGet packages for Chocolatey.

- [View the Mondoo Overview on Chocolatey](https://community.chocolatey.org/profiles/mondoo)
- [View our published packages](https://community.chocolatey.org/packages?q=mondoo)
- [View our packages pending moderation](https://community.chocolatey.org/packages?q=tag%3Amondoo&moderatorQueue=true&moderationStatus=all-statuses&prerelease=false&sortOrder=relevance')

## Packages

| Package | Type | Description |
|---------|------|-------------|
| **mql** | Binary | Mondoo MQL — cloud-native infrastructure query tool |
| **cnspec** | Binary | Mondoo cnspec — security and compliance scanner (depends on mql) |
| **cnquery** | Transitional | Meta-package that installs mql (cnquery was renamed to mql) |

## Directory Structure

```
packages/chocolatey/
├── Makefile                 # Build, validate, pack, and publish targets
├── README.md
├── mql-generate.sh          # Generates the mql .nuspec and install script
├── cnspec-generate.sh        # Generates the cnspec .nuspec and install script
└── cnquery-generate.sh       # Generates the cnquery transitional .nuspec
```

Each `*-generate.sh` script produces a subdirectory (`mql/`, `cnspec/`, `cnquery/`) containing the `.nuspec` and, for binary packages, a `tools/chocolateyInstall.ps1`.

## Usage

All commands require `VERSION` to be set.

```shell
# Generate, validate, and pack all packages
make all VERSION=13.0.1

# Generate and validate only (no Docker required)
make generate validate VERSION=13.0.1

# Pack using the chocolatey/choco Docker image
make pack VERSION=13.0.1

# Publish to Chocolatey (requires API key)
make publish VERSION=13.0.1 CHOCO_API_KEY=your-key

# Work with a single package
make generate-mql validate-mql pack-mql VERSION=13.0.1

# Clean generated directories
make clean VERSION=13.0.1
```

### Validation

The `validate` target checks that generated automation scripts (`.ps1`/`.psm1`) do not contain forbidden Chocolatey commands (`cinst`, `choco install`, `choco upgrade`, `choco uninstall`, `choco list`). Chocolatey's automated review rejects packages that call these commands directly in scripts — use `.nuspec` `<dependencies>` instead.

### Docker

The `pack` and `publish` targets use the `chocolatey/choco:latest` Docker image (amd64 only) to run `choco pack` and `choco push`. On Apple Silicon Macs, Docker must run the image under Rosetta/QEMU, which may cause mono crashes. In that case, use `make generate validate` locally and let CI handle packing.

## Package Lifecycle

1. A NuGet package is generated and submitted to the Chocolatey API
2. Automated checks are carried out — the new version appears in the [Version History](https://community.chocolatey.org/packages/mql#versionhistory) but is not yet listed
3. If all checks pass, it waits for a human moderator to approve (this can take hours to days)
4. Once approved, the package is listed and accessible

To learn more, review the Chocolatey [Package Review Process](https://docs.chocolatey.org/en-us/community-repository/moderation/#package-review-process) documentation.

## About the API Key

Our packages are owned and published by the ['mondoo'](https://community.chocolatey.org/profiles/mondoo) user, with the email/login of 'hello@mondoo.com'. The password is in BitWarden's 'Development' Collection entitled: "Chocolatey Mondoo User & API Key". You can find the API Key here: https://community.chocolatey.org/account

If you rotate the API key, be sure to update the `CHOCOLATEY_API_KEY` secret in this repo.

## Learn More

* [Chocolatey Guide: Running on Non-Windows Systems](https://docs.chocolatey.org/en-us/guides/non-windows)
* [Chocolatey Guide: Package Creation](https://docs.chocolatey.org/en-us/create/)
