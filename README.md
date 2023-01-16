# Overview

- [Installation](#installation)
  - [cnquery](#cnquery)
  - [cnspec](#cnspec)
- [Scan your target platform](#scan-your-target-platform)
- [Package Information](#package-information)
- [Kubernetes](#kubernetes)

# Installation

## cnquery

### via Shell Script (Linux and macOS)

[`https://install.mondoo.com/sh/cnquery`](https://install.mondoo.com/sh/cnquery)

```bash
bash -c "$(curl -sSL https://install.mondoo.com/sh/cnquery)"
```

### via Powershell (Windows)

[`https://install.mondoo.com/ps1/cnquery`](https://install.mondoo.com/ps1/cnquery)

```powershell
Set-ExecutionPolicy Unrestricted -Scope Process -Force;
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
iex ((New-Object System.Net.WebClient).DownloadString('https://install.mondoo.com/ps1/cnquery'));
Install-Mondoo -Product cnquery;
```

## cnspec

### via Shell Script (Linux and macOS)

[`https://install.mondoo.com/sh/cnspec`](https://install.mondoo.com/sh/cnspec)

```bash
bash -c "$(curl -sSL https://install.mondoo.com/sh/cnspec)"
```

### via Powershell (Windows)

[`https://install.mondoo.com/ps1/cnspec`](https://install.mondoo.com/ps1/cnspec)

```powershell
Set-ExecutionPolicy Unrestricted -Scope Process -Force;
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
iex ((New-Object System.Net.WebClient).DownloadString('https://install.mondoo.com/ps1/cnspec'));
Install-Mondoo -Product cnspec;
```

# Scan your target platform

Scan your [target platform](https://github.com/mondoohq/cnspec/#supported-targets):

```
# query system information with incident and inventory query pack
cnquery scan aws
# scan the platform for security vulnerabilities
cnspec scan aws
```

Sign up for free [Mondoo Platform account](https://mondoo.com/docs/tutorials/mondoo/account-setup/) to access more policies and store reports:

```bash
cnspec login -t 'eyJh...llZ4BW'
```

cnquery & cnspec support local, and remote targets including servers (Linux, Windows, macOS), Cloud (AWS, Azure, Google, VMware), Kubernetes (EKS, GKE, AKS, self-managed), containers, container registries, SaaS products (MS365, GitHub, GitLab), and more.

Run a scan:

```bash
# scan your local host
cnspec scan local

# scan a cloud environment
cnspec scan aws
cnspec scan gcp
cnspec scan azure

# scan a kubernetes cluster
cnspec scan k8s

# scan a docker image from remote registry
cnspec scan docker image centos:7

# scan a docker container (get ids from docker ps)
cnspec scan docker container 00fa961d6b6a

# scan a system over ssh
cnspec scan ssh ec2-user@54.76.229.223
```

# Package Information

`https://install.mondoo.com/package/mondoo/{platform}/{arch}/{filetype}/{version}/{method}`

The arguments support the following values:

| Argument   | Values                                               |
| ---------- | ---------------------------------------------------- |
| `platform` | `linux`, `windows`, `darwin`                         |
| `arch`     | `amd64`, `arm64`, `armv7`, `armv6`, `386`, `ppc64le` |
| `filetype` | `tar.gz`, `deb`, `rpm`, `zip`, `pkg`, `msi`          |
| `version`  | `latest` or specific number                          |
| `method`   | `download`, `filename`, `version`, `sha256`          |

```bash
# Download the latest version
https://install.mondoo.com/package/mondoo/linux/arm64/rpm/latest/download
```

```bash
# Get the filename for the latest Mondoo Client
https://install.mondoo.com/package/mondoo/linux/arm64/rpm/latest/filename
```

```bash
# Get the version for the latest Mondoo Client
https://install.mondoo.com/package/mondoo/linux/arm64/rpm/latest/version
```

```bash
# Get the sha256 for the latest Mondoo Client
https://install.mondoo.com/package/mondoo/linux/arm64/rpm/latest/sha256
```

```bash
# Download a specific version of Mondoo Client
https://install.mondoo.com/package/mondoo/linux/arm64/rpm/5.21.1/download
```

```
# Get the sha256 for a specific version of Mondoo Client
https://install.mondoo.com/package/mondoo/linux/arm64/rpm/5.21.1/sha256
```

# Kubernetes

## Kubernetes Manifests to install the operator

[`https://install.mondoo.com/k8s/operator`](https://install.mondoo.com/k8s/operator)

```bash
kubectl apply -f https://install.mondoo.com/k8s/operator
```

## Kubernetes Manifest to configure the MondooAuditConfig

[`https://install.mondoo.com/k8s/auditconfig?nodes=true&kubernetesResources=true`](https://install.mondoo.com/k8s/auditconfig?nodes=true&kubernetesResources=true)

```bash
kubectl apply -f https://install.mondoo.com/k8s/auditconfig?nodes=true&kubernetesResources=true
```

To browse all releases, please visit [https://releases.mondoo.com](https://releases.mondoo.com)

# References

**Install Scripts Sources**

- [install.sh](https://github.com/mondoohq/installer/blob/main/install.ps1) - `cnquery` & `cnspec` Bash Installer
- [download.sh](https://github.com/mondoohq/installer/blob/main/download.sh) - `cnquery` & `cnspec` Bash Binary Downloader
- [install.ps1](https://github.com/mondoohq/installer/blob/main/install.ps1) - `cnquery` & `cnspec` Powershell Installer
- [download.ps1](https://github.com/mondoohq/installer/blob/main/download.ps1) - `cnquery` & `cnspec` Powershell Binary Downloader

**Config Management**

- [cnquery & cnspec Ansible Role](https://github.com/mondoohq/ansible-mondoo)
- [cnquery & cnspec Chef Cookbook](https://github.com/mondoohq/chef-mondoo)

**Docker Containers**

- [https://hub.docker.com/r/mondoo/cnquery](https://hub.docker.com/r/mondoo/cnquery)
- [https://hub.docker.com/r/mondoo/cnspec](https://hub.docker.com/r/mondoo/cnspec)

**Releases**

- [Release Notes](https://mondoo.com/releases)
- [Package Downloads](https://releases.mondoo.com)
