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

# Code Signature Verification

Mondoo signs Microsoft Windows executables, PowerShell scripts, Linux packages and code signs Apple macOS executables. The public code signing certificate and public GPG key ist store in the [Installer Repo](https://github.com/mondoohq/installer).

- Public certificate for code signing `public-code-signing.cer`
- Public GPG key for package signing `public-package-signing.gpg`

## Microsoft

To verify the integrity of the Mondoo executable, please use Microsoft's Get-AuthenticodeSignature PowerShell command and compare the Thumbprint.

```powershell
$file = "mondoo_7.10.0_windows_amd64.msi"
(Get-AuthenticodeSignature -FilePath $file).SignerCertificate | Format-List

Subject      : CN="Mondoo, Inc", O="Mondoo, Inc", L=Cary, S=North Carolina, C=US
Issuer       : CN=DigiCert Global G3 Code Signing ECC SHA384 2021 CA1, O="DigiCert, Inc.", C=US
Thumbprint   : EE97D1E3C6CD96E06C47B0233DD7C6CE2684FA50
FriendlyName :
NotBefore    : 7/26/2022 12:00:00 AM
NotAfter     : 8/23/2023 11:59:59 PM
Extensions   : {System.Security.Cryptography.Oid, System.Security.Cryptography.Oid, System.Security.Cryptography.Oid,
               System.Security.Cryptography.Oid...}
```

To verify the integrity of the Mondoo Powershell `install.ps1` script, please use Microsoft's Get-AuthenticodeSignature PowerShell command and compare the SignerCertificate.

```powershell
Get-AuthenticodeSignature .\install.ps1

SignerCertificate                         Status
-----------------                         ------
EE97D1E3C6CD96E06C47B0233DD7C6CE2684FA50  Valid
```

## Apple macOS

To verify the integrity of the Mondoo executable, please use Apple's codesign utility and compare the TeamIdentifier field, which should match the one below.

```bash
codesign --verify -d --verbose=2 /usr/local/bin/mondoo
Executable=/Library/Mondoo/bin/mondoo
Identifier=mondoo
Format=Mach-O universal (x86_64 arm64)
CodeDirectory v=20500 size=2060754 flags=0x10000(runtime) hashes=64393+2 location=embedded
Signature size=9056
Authority=Developer ID Application: Mondoo, Inc. (W2KUBWKG84)
Authority=Developer ID Certification Authority
Authority=Apple Root CA
Timestamp=12. Jan 2023 at 23:51:56
Info.plist=not bound
TeamIdentifier=W2KUBWKG84
Runtime Version=10.9.0
Sealed Resources=none
Internal requirements count=1 size=168
```

## Current & Previous PGP Public Keys

### Current Key

The current PGP public key from Mondoo has ID `00E1C42B` / fingerprint `4CE909E26AE7439C39CE7647AC69C65100E1C42B` and is:

```
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQINBGAF59cBEAC2qCHNY7b8vqKNfGkmgUiOQM7Ags2qL7Z6wlZR+6PjfHjCO7c/
zJgCOSbY1O/XcwnsntQUBlAjZ7yzIBvvvGjmL+3vW1flKl4ZlgLnufHB9oUXtkVd
AMSnVD/LztLKgDMad4KqNwGHuXOa3Ewl5Fv7ZQBHo0hLjslr/mbjG3CtJovXCuS1
HHklLwTap5C/SHx6DIQvJ5DV7GyhCJkRvVxs495XPEIjgv5nyftWhkDqVQxdHoSZ
RoYvoKytG5isDTlv3qbUgPFN6VYvMMEbGegwQpYvdwq6WHNFgri/Abq+yWKZ+Ysn
t8mXEVZR7onfH8jnI2X2XYrIw/c7GHcmkROU+sDvjKnEY/QfcnZUYQnsYmSW34l5
rOVoqQNEutlu41r3KZ1Z7fA8aRYo++D6IusmgIZYA0MtverWPc/S+ZkirQ/SCmNm
9CHV2iLHBJ2kYZ/sYYXCigOGAoJZ1QsTiXpKOB6X/IoDh5zw2yZQm+9GSQ1OGFlr
AWz9tPv98UpSNqGxJAoigS3aMYUobgskXL+dnCkAgb9kLIuDvp3e5EWJr3qmowC7
JMfphTtjrIVu8IgnpjwULlW1WIh3IUp4YfTN51D3NeeAIXuJYhHA5QSjkK9k+Rst
ElLYDWlvF4vZUgvF1a0DGCc5QcRousnavh4ReivLZZVdhxghFdRmO2NgMwARAQAB
tB9Nb25kb28gSW5jIDxzZWN1cml0eUBtb25kb28uaW8+iQJUBBMBCgA+AhsDBQsJ
CAcDBRUKCQgLBRYCAwEAAh4BAheAFiEETOkJ4mrnQ5w5znZHrGnGUQDhxCsFAmPH
LZ8FCQlk4EgACgkQrGnGUQDhxCsvFw//TH3r5Qd8eR5YVsbfAHjbiTkOGhtt4V2k
s0Gt4s6tuLxQlO2SfqtQBuEH3gf8P2Nz6i0WkXb6bdtJFgJ/QVW7FIUtInqR6KLw
CP06J5ZawUepPusjFt6ARzmy99MwWjCv+rgXk6olrOWrpyauDgCFfGRVNBhhRGwX
RNnzpDwnEQegU5bd5GuLJKvGE4eW349a495Sdfg5V22kngsbM10CoTVAIExLnP6a
GZMqWic7q577UGsxml48xw8wluRJp4Xwa2uAjNZzdFkPmhGeHzsF66Rw7pvaqayP
2t4zpAj3KfjWZcYkTnQdkEcLy01rzZZXvUdtv8dwIKLztEyGcP7uTY0O5Bv0aSES
I9KLMLo0fmMr4pBtpgtpLZPkQp6nfupIZF954+d/IkufjEFSLKJmRVyMph6bNWRU
dBmDfmnoG5aaMVREkXA1oOHVULnjWyCZqfWQj2iWx5/JhBHQwUJQXEu6GnYUI+SJ
H8axM8GpfA2Gaj88G82Vxl0QObMJ5rnaYLWvaoUpRjD+LTVybCzGHVZSQOfy7ukc
windeWQtvqcAIgnRMiWMZ0r88ZyM7Hw59kd4shPenBqLLPMyfrhsBj85n4N2epzE
oFhAnK5Jdr7d195l3onVIEylXGfBiY9cdV7YynJbmaFmnKZivE0c06Lfv3Ck+Luj
Yzytm9bkDrW0IE1vbmRvbyBJbmMgPHNlY3VyaXR5QG1vbmRvby5jb20+iQJUBBMB
CgA+FiEETOkJ4mrnQ5w5znZHrGnGUQDhxCsFAmPHLtACGwMFCQlk4EgFCwkIBwIG
FQoJCAsCBBYCAwECHgECF4AACgkQrGnGUQDhxCvYihAAhkrBNbEUIB0kDIUx/Tyg
S5DsTA9tvx0mlJwYXqnUQXqybfsE9S3HHml7rXRQgSmNbwM149uR41i6BB/VdkN7
hL5a4Hwmuw2q4qBkdwFq459fcDn/KaZRkjD+QsJcs0FvR/E5GyEz3bC4jvWErtpy
wMS0wF34IoR6vqTUgBV8IFaXrMOUjoAbtUTfhUOEnLn0PPVRvs+TZ3D98e1PpinI
ng+TQY9LKXIHzC7oyxoQc5YpIPAZycwwpvlFFqE9xp0/HfcZkW0OZ5A6/KCSEyRC
5u4N4N9vZhe4WeZqEf3KXo01OYNKoOJUa57vMiv4UyNPI53V2P64mcrXqKhAiP2z
BKIAM8OMIeIWRD5a0EMoGNazMGkQ2RD9YALCqbkAsNBQ/ZN6dsl8fVw1LQLAnGLv
/7il90YxIZYzw1sLYG7uATtHXf/jSjGaWS+1nW/faBOTcKj3zaY5/F3REZHhmQDG
6O6ae1HtcgKclJ7N/TXVPS6qcsNDVv2xctW0HpH0RNSt5Xc2VVvkzbZ1JHT/lRRq
iRivUN+HoDwwda5e7pjgThDUVzUwzD6NTXf8Hfp7risZUGwI+ALbPc8zQxu2HlYF
6C4MxGS/hGJTgw01oTcKZma/ZuRW8FtybYVtheEI0S4qaIOg/0leTZV76ugEA+WY
ugfAyAbwEXF540MRjWoxI3q5Ag0EYAXn1wEQAMAiLOUBM5FgrU32MS7MCDpbyoiW
PmPPHE2onMEXzpX5YH1a5JedUwYdAkc1x4WtUmSM3PnrfUA2gD4JX/ZrnyjK2kC7
wmIM61oOARBL/Mmyk7zb5+t/4TlVB0Q1AI9ylPrZPfxYEJ+VaUKJB+pixqilbc6S
muDW3Q7Q9fdF3/Yan3nbewpt11zV3zPZaZfeFfCByOIwmpU9NJXULqV+oW99u0Cj
8N532gMTIEO24oPBm+e71sy9Kv0OwXrlrJwUHhZJ7WciOI1XthxDgoqfxzW4EP6k
jrIkQ4LltnMHtpeKv6yohlLOZiWNmzPWAWnMbpXJCmUpgeTKaxxjXUehsstFbMGE
YsGFM49Z3092AXuGrYnoqpZNv9its7+Ly15wXpdXPPEIjqW9KTJqk+OoO7YopGE2
XRKIDAZc1Qtxzi9gAcwkOvIyhziZvzgyjbi/dtQa/vFWPSih6F3P9TPey82/eSBf
RUwdM+UKP3CD3dNLWHRigtMT/p1dlIRFXRlxYzAjZ4EwRg62eGScttP6PbPO+3IT
VOCpMXAmnguHDrpvuyuLmAwLpW2Q18EVtjV+UuLSbnF4nieUsT5iIWmy7JhRsLEu
1Yerws4bTyoAqNqDaZ1IottzkOHJpvNu5ntiJx8T/M8yuthFFy9jhbTDeiSTV+iE
SDVAtVVqhYT6nyDlABEBAAGJAjwEGAEKACYCGwwWIQRM6QniaudDnDnOdkesacZR
AOHEKwUCY8ctlQUJCWTgPgAKCRCsacZRAOHEK9CsD/wMUmo4pCP8F5EtKe3QNvAu
6wjEpQNXDRCGft18k2eeuyk3v+vJ4jqGLcw5wlvilTzGBu9xZQTkUr3tZX+ZhZkb
e86yXd71qywHcCeIm0pAb2kGMq889r2sZwhR9TjLolFPAtOr3qfbEqK3rQTqZS/4
m1Z2bQ028Vhzwe2L8WrjQDZ3WFAIKp6Yb8pEDWcMDhvgoMGzDQNJwC6t4e2QVZHj
h/v6H/E1E0jEsiHZcSPRM/eE36QayIgXa13VamUZuFx7sb1s8Ik1/c5gseZMkxRR
MOgZYidWpV/FdUJ02lKwT0BZsbLSnzY38+Vpz4FyDBp7UEOlg6uJVkh2FCfP4Wlm
wgpi9CDQNvDEYWPOPDJcKpLqLxHk7mJIYsnDOsfMB+jfG9okEkGoA2My6/eGykhx
SOqD3Y95L3RXRL2PY7sRvcs2ygtRma6u+aU7KxOqsOfwhkyrefo2d74cMaOuPyKK
ix7+7QWLFx8HzREN24tx8eJuuB2Z4lAe7SxVOkY/Lo3pibXET8Cjzw/e+ut6b3Iu
wYfYiuZWjMEIvRNQ+EP5S5rKW+uCPTAYuKeTinNIHm4idD7cdFZJUz+jKAeShOsb
ROXmwrH9exRkCM3RblVq6XRk/GnXburwB2rtPIF8OOnQiGptLUtCnbApp5crYC/u
Ur8NXko6K6rP77odIXjJSA==
=9LQ9
-----END PGP PUBLIC KEY BLOCK-----
```

### Previous Keys

Key ID `00E1C42B` / fingerprint `4CE909E26AE7439C39CE7647AC69C65100E1C42B`:

```
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
A8Hssvbbfw==
=dMNn
-----END PGP PUBLIC KEY BLOCK-----
```

You can download Mondoo's public PGP key from (both are identical):

- [https://releases.mondoo.com/debian/pubkey.gpg](https://releases.mondoo.com/debian/pubkey.gpg)
- [https://releases.mondoo.com/rpm/pubkey.gpg](https://releases.mondoo.com/rpm/pubkey.gpg)
