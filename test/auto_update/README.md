# Linux Packaging Tests

`test_auto_update.py` tests mondoo metapackage installation, package upgrades, auto-update, and binary self-upgrade across DEB- and RPM-based Linux distributions using Docker.

## Requirements

- Docker (with `linux/amd64` support)
- Python 3
- Network access to `releases.mondoo.love` / `releases.mondoo.com`

## Test Suites

| Suite | What it tests |
|---|---|
| **mondoo-pkg** | Downloads and installs mql + cnspec + mondoo `.deb`/`.rpm`, verifies versions |
| **upgrade** | Installs a stable base version (default: 11.0.0, 12.0.0), upgrades to `--install-version`, verifies versions |
| **auto-update** | Installs binaries from tarballs with `auto_update: true` config, triggers `mql run local`, checks version output |
| **self-upgrade** | Installs `--self-upgrade-from` binaries, triggers in-process self-upgrade, verifies binary was replaced |

## Distros

| Name | Image | Package manager |
|---|---|---|
| Ubuntu 22.04 | `ubuntu:22.04` | apt |
| Debian 12 | `debian:12` | apt |
| AlmaLinux 9 | `almalinux:9` | dnf |
| Rocky Linux 9 | `rockylinux:9` | dnf |

## Usage

### Run all tests

```bash
python3 test/auto_update/test_auto_update.py \
  --install-version 13.0.0-rc9 \
  --releases-url https://releases.mondoo.love
```

### Run all tests including self-upgrade

```bash
python3 test/auto_update/test_auto_update.py \
  --install-version 13.0.0-rc9 \
  --releases-url https://releases.mondoo.love \
  --self-upgrade-from 13.0.0-rc8
```

### Filter to specific distros

```bash
# Rocky Linux 9 only
python3 test/auto_update/test_auto_update.py \
  --install-version 13.0.0-rc9 \
  --distro rocky

# Multiple distros
python3 test/auto_update/test_auto_update.py \
  --install-version 13.0.0-rc9 \
  --distro ubuntu --distro debian
```

### Skip suites

```bash
# Only mondoo-pkg and upgrade tests (skip auto-update and self-upgrade)
python3 test/auto_update/test_auto_update.py \
  --install-version 13.0.0-rc9 \
  --skip-auto-update \
  --skip-self-upgrade

# Only self-upgrade test
python3 test/auto_update/test_auto_update.py \
  --install-version 13.0.0-rc9 \
  --self-upgrade-from 13.0.0-rc8 \
  --skip-auto-update \
  --skip-mondoo-pkg \
  --skip-upgrade
```

### Custom base versions for upgrade tests

```bash
python3 test/auto_update/test_auto_update.py \
  --install-version 13.0.0-rc9 \
  --base-versions 11.0.0,12.23.1
```

### Stop on first failure

```bash
python3 test/auto_update/test_auto_update.py \
  --install-version 13.0.0-rc9 \
  --fail-fast
```

## Options

| Flag | Default | Description |
|---|---|---|
| `--install-version` | *(required)* | Version to install/test, e.g. `13.0.0-rc9` |
| `--releases-url` | `https://releases.mondoo.love` | Base URL for packages under test |
| `--stable-releases-url` | `https://releases.mondoo.com` | Base URL for stable base packages used in upgrade tests |
| `--distro FILTER` | all | Only run distros matching FILTER in name or image (case-insensitive, repeatable) |
| `--skip-auto-update` | false | Skip auto-update suite |
| `--skip-mondoo-pkg` | false | Skip mondoo metapackage suite |
| `--skip-upgrade` | false | Skip upgrade suite |
| `--skip-self-upgrade` | false | Skip self-upgrade suite |
| `--self-upgrade-from VERSION` | *(empty)* | Version to upgrade from in self-upgrade tests |
| `--base-versions LIST` | `11.0.0,12.0.0` | Comma-separated base versions for upgrade tests |
| `--fail-fast` | false | Stop after first failure |

## CI Workflow

The `.github/workflows/test_linux_packaging.yml` workflow runs these tests in three parallel jobs:

| Job | Suites run |
|---|---|
| `test-mondoo-pkg-and-upgrade` | mondoo-pkg + upgrade |
| `test-auto-update` | auto-update |
| `test-self-upgrade` | self-upgrade (only if `self-upgrade-from` input is set) |

Trigger manually via **Actions → Test Linux Packaging → Run workflow**.
