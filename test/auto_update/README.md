# Linux Packaging Tests

This package tests mondoo metapackage installation, package upgrades, auto-update, and binary self-upgrade across Linux distributions using Docker.

## Requirements

- Docker (with `linux/amd64` support)
- Python 3.10+
- Network access to `releases.mondoo.love` / `releases.mondoo.com`

## Test Suites

| Suite | What it tests |
|---|---|
| **mondoo-pkg** | Downloads and installs mql + cnspec + mondoo packages, verifies versions |
| **upgrade** | Installs a stable base version (default: 11.0.0, 12.0.0), upgrades to `--install-version`, verifies versions and that cnquery was removed |
| **auto-update** | Installs binaries from tarballs with `auto_update: true` config, triggers `mql run local`, checks version output |
| **self-upgrade** | Installs `--self-upgrade-from` binaries, triggers in-process self-upgrade, verifies binary was replaced |

## Distros

| Name | Image | Package manager |
|---|---|---|
| Debian 11 | `debian:11` | apt |
| Debian 12 | `debian:12` | apt |
| Ubuntu 20.04 | `ubuntu:20.04` | apt |
| Ubuntu 22.04 | `ubuntu:22.04` | apt |
| Ubuntu 24.04 | `ubuntu:24.04` | apt |
| AlmaLinux 9 | `almalinux:9` | dnf |
| Rocky Linux 8 | `rockylinux:8` | dnf |
| Rocky Linux 9 | `rockylinux:9` | dnf |
| CentOS Stream 9 | `quay.io/centos/centos:stream9` | dnf |
| Oracle Linux 8 | `oraclelinux:8` | dnf |
| Oracle Linux 9 | `oraclelinux:9` | dnf |
| SUSE SLE 15.6 | `registry.suse.com/suse/sle15:15.6` | zypper |
| Arch Linux | `archlinux:latest` | pacman |

## Package Structure

```
test/auto_update/
├── __init__.py           # Package exports
├── __main__.py           # Entry point (python -m auto_update)
├── cli.py                # Argument parsing and main()
├── constants.py          # Default URLs and versions
├── distros.py            # Distro dataclass and DISTROS list
├── docker.py             # DockerRunner class
├── runners.py            # Test runner functions
├── scripts.py            # ScriptBuilder class
├── utils.py              # Helper functions
├── package_managers/
│   ├── __init__.py       # Exports PackageManager + registry
│   ├── base.py           # PackageManager ABC
│   ├── apt.py            # Debian/Ubuntu
│   ├── dnf.py            # RHEL/Rocky/Alma/CentOS
│   ├── zypper.py         # SUSE
│   └── pacman.py         # Arch Linux
└── README.md
```

## Usage

### Run all tests

```bash
PYTHONPATH=test python -m auto_update \
  --install-version 13.0.0-rc9 \
  --releases-url https://releases.mondoo.love
```

### Run all tests including self-upgrade

```bash
PYTHONPATH=test python -m auto_update \
  --install-version 13.0.0-rc9 \
  --releases-url https://releases.mondoo.love \
  --self-upgrade-from 13.0.0-rc8
```

### Filter to specific distros

```bash
# Arch Linux only
PYTHONPATH=test python -m auto_update \
  --install-version 13.0.0-rc9 \
  --distro arch

# Rocky Linux only
PYTHONPATH=test python -m auto_update \
  --install-version 13.0.0-rc9 \
  --distro rocky

# Multiple distros
PYTHONPATH=test python -m auto_update \
  --install-version 13.0.0-rc9 \
  --distro ubuntu --distro debian
```

### Skip suites

```bash
# Only mondoo-pkg and upgrade tests (skip auto-update and self-upgrade)
PYTHONPATH=test python -m auto_update \
  --install-version 13.0.0-rc9 \
  --skip-auto-update \
  --skip-self-upgrade

# Only upgrade tests
PYTHONPATH=test python -m auto_update \
  --install-version 13.0.0-rc9 \
  --skip-auto-update \
  --skip-mondoo-pkg \
  --skip-self-upgrade

# Only self-upgrade test
PYTHONPATH=test python -m auto_update \
  --install-version 13.0.0-rc9 \
  --self-upgrade-from 13.0.0-rc8 \
  --skip-auto-update \
  --skip-mondoo-pkg \
  --skip-upgrade
```

### Custom base versions for upgrade tests

```bash
PYTHONPATH=test python -m auto_update \
  --install-version 13.0.0-rc9 \
  --base-versions 11.0.0,12.23.1
```

### Stop on first failure

```bash
PYTHONPATH=test python -m auto_update \
  --install-version 13.0.0-rc9 \
  --fail-fast
```

### Debug failures interactively

```bash
PYTHONPATH=test python -m auto_update \
  --install-version 13.0.0-rc9 \
  --distro arch \
  --shell-on-failure
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
| `--shell-on-failure` | false | Drop into interactive shell on failure |

## CI Workflow

The `.github/workflows/test_linux_packaging.yml` workflow runs these tests in three parallel jobs:

| Job | Suites run |
|---|---|
| `test-mondoo-pkg-and-upgrade` | mondoo-pkg + upgrade |
| `test-auto-update` | auto-update |
| `test-self-upgrade` | self-upgrade (only if `self-upgrade-from` input is set) |

Trigger manually via **Actions → Test Linux Packaging → Run workflow**.
