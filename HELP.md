# Overview

- [Installation](#installation)
  - [cnquery](#cnquery)
  - [cnspec](#cnspec)
- [Package Information](#package-information)
- [Kubernetes](#kubernetes)

# Installation

## cnquery

###  via Shell Script (Linux and macOS)

[`https://install.mondoo.com/sh/cnquery`](https://install.mondoo.com/sh/cnquery)

```bash
bash -c "$(curl -sSL https://install.mondoo.com/sh/cnquery)"
```

To login with Mondoo Platform:

```bash
cnquery login -t 'eyJh...llZ4BW'
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

###  via Shell Script (Linux and macOS)

[`https://install.mondoo.com/sh/cnspec`](https://install.mondoo.com/sh/cnspec)

```bash
bash -c "$(curl -sSL https://install.mondoo.com/sh/cnspec)"
```

To login with Mondoo Platform:

```bash
cnspec login -t 'eyJh...llZ4BW'
```

### via Powershell (Windows)

[`https://install.mondoo.com/ps1/cnspec`](https://install.mondoo.com/ps1/cnspec)

```powershell
Set-ExecutionPolicy Unrestricted -Scope Process -Force;
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
iex ((New-Object System.Net.WebClient).DownloadString('https://install.mondoo.com/ps1/cnspec'));
Install-Mondoo -Product cnspec;
```

# Package Information

`https://install.mondoo.com/package/mondoo/{platform}/{arch}/{filetype}/{version}/{method}`

The arguments support the following values
  - **platform**: linux, windows, darwin
  - **arch**:     amd64, arm64, armv7, armv6, 386
  - **filetype**: tar.gz, deb, rpm, zip, pkg, msi
  - **version**:  latest, or specific number
  - **method**:   download, filename, version, sha256    

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