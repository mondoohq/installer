# Linux Packaging Tests

This package tests mondoo metapackage installation, package upgrades, auto-update, and binary self-upgrade across Linux distributions using Docker.

## Requirements

- Docker (with `linux/amd64` support)
- Python 3.10+
- pytest (`pip install pytest`)
- Network access to `releases.mondoo.love` / `releases.mondoo.com`

## Test Suites

| Suite | Marker | What it tests |
|---|---|---|
| **auto-update** | `auto_update` | Installs binaries with `auto_update: true` config, triggers `mql run local`, checks version output |
| **mondoo-pkg** | `mondoo_pkg` | Downloads and installs mql + cnspec + mondoo packages, verifies versions |
| **upgrade** | `upgrade` | Installs a stable base version, upgrades to target version, verifies cnquery was removed |
| **self-upgrade** | `self_upgrade` | Installs older binaries, triggers in-process self-upgrade, verifies binary was replaced |
| **install.sh** | `install_sh` | Installs cnquery, upgrades to mql via install.sh, verifies old package removed |
| **AUR** | `aur` | Tests Arch Linux AUR package installation via makepkg and yay |

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
├── __main__.py           # Entry point
├── cli.py                # Legacy CLI (backwards compatibility)
├── conftest.py           # pytest fixtures and configuration
├── constants.py          # Default URLs and versions
├── distros.py            # Distro dataclass and DISTROS list
├── docker.py             # DockerRunner class
├── runners.py            # Legacy runner functions
├── scripts.py            # ScriptBuilder class
├── utils.py              # Helper functions
├── test_auto_update.py   # Auto-update tests
├── test_mondoo_pkg.py    # Mondoo metapackage tests
├── test_upgrade.py       # Upgrade tests
├── test_install_sh.py    # install.sh upgrade tests
├── test_aur.py           # AUR tests (Arch Linux)
├── package_managers/
│   ├── __init__.py       # Exports PackageManager + registry
│   ├── base.py           # PackageManager ABC
│   ├── apt.py            # Debian/Ubuntu
│   ├── dnf.py            # RHEL/Rocky/Alma/CentOS
│   ├── zypper.py         # SUSE
│   └── pacman.py         # Arch Linux
└── README.md
```

## Usage (pytest)

### Run all tests

```bash
pytest test/auto_update -v --install-version 13.0.0
```

### Run specific test suites

```bash
# Auto-update tests only
pytest test/auto_update -m auto_update -v --install-version 13.0.0

# Mondoo metapackage tests only
pytest test/auto_update -m mondoo_pkg -v --install-version 13.0.0

# Upgrade tests only
pytest test/auto_update -m upgrade -v --install-version 13.0.0

# Multiple suites
pytest test/auto_update -m "mondoo_pkg or upgrade" -v --install-version 13.0.0
```

### Filter to specific distros

```bash
# Arch Linux only
pytest test/auto_update -v --install-version 13.0.0 --distro arch

# Rocky Linux only
pytest test/auto_update -v --install-version 13.0.0 --distro rocky

# Multiple distros
pytest test/auto_update -v --install-version 13.0.0 --distro ubuntu --distro debian
```

### Run specific tests

```bash
# AUR mql makepkg test
pytest test/auto_update/test_aur.py::test_aur_mql_makepkg -v --install-version 13.0.0

# install.sh upgrade test
pytest test/auto_update/test_install_sh.py -v \
  --install-version 13.0.0 \
  --install-sh-upgrade-from 12.0.0

# Self-upgrade test
pytest test/auto_update -m self_upgrade -v \
  --install-version 13.0.0 \
  --self-upgrade-from 13.0.0-rc5
```

### Test local install.sh changes

```bash
pytest test/auto_update/test_install_sh.py -v \
  --install-version 13.0.0 \
  --install-sh-upgrade-from 12.0.0 \
  --use-local-install-sh
```

### Use custom releases URL

```bash
pytest test/auto_update -v \
  --install-version 13.0.0-rc9 \
  --releases-url https://releases.mondoo.love
```

### Debug failures interactively

```bash
pytest test/auto_update -v \
  --install-version 13.0.0 \
  --distro debian:11 \
  --shell-on-failure
```

## Options

| Flag | Default | Description |
|---|---|---|
| `--install-version` | *(required)* | Version to install/test, e.g. `13.0.0` |
| `--releases-url` | `https://releases.mondoo.love` | Base URL for packages under test |
| `--stable-releases-url` | `https://releases.mondoo.com` | Base URL for stable base packages |
| `--distro FILTER` | all | Only run distros matching FILTER (repeatable) |
| `--base-versions LIST` | `11.0.0,12.0.0` | Comma-separated base versions for upgrade tests |
| `--self-upgrade-from` | *(empty)* | Version for self-upgrade tests |
| `--install-sh-upgrade-from` | *(empty)* | Version for install.sh upgrade tests |
| `--use-local-install-sh` | false | Use local install.sh instead of install.mondoo.com |
| `--shell-on-failure` | false | Drop into interactive shell on failure |

## Legacy CLI (backwards compatible)

The old CLI syntax is still supported:

```bash
PYTHONPATH=test python -m auto_update \
  --install-version 13.0.0 \
  --tests mondoo-pkg,upgrade

PYTHONPATH=test python -m auto_update \
  --install-version 13.0.0 \
  --tests all --skip-tests aur
```

## CI Workflows

### test_linux_packaging.yml

Runs packaging tests in parallel jobs:

| Job | Tests run |
|---|---|
| `test-mondoo-pkg-and-upgrade` | mondoo-pkg + upgrade |
| `test-auto-update` | auto-update |
| `test-self-upgrade` | self-upgrade (if `self-upgrade-from` set) |

### test-released-install-sh.yaml

Tests install.sh upgrades. Triggers on:
- PR/push to `install.sh` or `test/auto_update/**` (uses local install.sh)
- workflow_dispatch/workflow_call (uses remote install.sh)

### test-released-archlinux.yaml

Tests AUR packages on Arch Linux:
- mql installation via makepkg
- cnspec installation via yay
- cnquery → mql upgrade
