# Quickstart

The easiest way to try Mondoo is by installing the agent locally on your workstation or use our  Docker container `mondoolabs/mondoo`. You can easily try out

- [Installation](#installation)
- [Registration](#registration)
- [First Scan](#scan-your-first-target)
- [Try with Docker](#try-with-docker)

## Installation

**Windows workstation**

<img src="../assets/windows_mondoo_install.png">

```powershell
iex (new-object net.webclient).downloadstring('https://mondoo.io/download.ps1')
```
See [Installing Mondoo Agent on Windows workstation](../agent/windows) for further information. 

**macOS Workstation**

<img src="../assets/videos/mondoo-setup-macos.gif">

```
brew tap mondoolabs/mondoo
brew install mondoo
```

See [Installing Mondoo Agent on macOS workstation](../agent/macos) for further information. 

**Linux Workstation**

```
curl -sSL https://mondoo.io/download.sh | bash
```

> Note: We support a wide range of [Linux operating systems(../agent) . We recommend our [package installation](../agent/bash) for server environments to ensure you always retrieve the latest updates. For workstations, we also provide a [script that just ships with the mondoo binary]((../agent/binaries)). 

## Registration

```
mondoo register --token 'ey...FlP'
  ✔  agent //agents.api.mondoo.app/spaces/dazzling-hermann-857694/agents/1NmZG4Mt2fKXRrYGvUPiyLG7JyQ registered successfully
```

## Scan your first target

```
mondoo scan -t ssh://ec2-user@54.205.49.51
Start vulnerability scan:
  →  verify platform access to ssh://ec2-user@54.205.49.51
  →  gather platform details
  →  detected amzn 2
  →  gather platform packages for vulnerability scan
  →  found 435 packages
  →  analyse packages for vulnerabilities
Advisory Report:
  ■   SCORE  PACKAGE       INSTALLED               VULNERABLE (<)          AVAILABLE               ADVISORY                                 
  ■   7.8    curl          7.61.1-9.amzn2.0.1      7.61.1-11.amzn2.0.2     7.61.1-11.amzn2.0.2     https://mondoo.app/vuln/ALAS2-2019-1233  
  ■   7.8    libcurl       7.61.1-9.amzn2.0.1      7.61.1-11.amzn2.0.2     7.61.1-11.amzn2.0.2     https://mondoo.app/vuln/ALAS2-2019-1233  
  ■   6.9    kernel        4.14.123-111.109.amzn2  4.14.133-113.112.amzn2  4.14.133-113.112.amzn2  https://mondoo.app/vuln/ALAS2-2019-1253  
  ╰─  6.5    kernel        4.14.123-111.109.amzn2  4.14.133-113.105.amzn2  4.14.133-113.112.amzn2  https://mondoo.app/vuln/ALAS2-2019-1232  
  ■   6.9    kernel-tools  4.14.133-113.105.amzn2  4.14.133-113.112.amzn2  4.14.133-113.112.amzn2  https://mondoo.app/vuln/ALAS2-2019-1253  
  →  ■ found 3 advisories: ■ 0 critical, ■ 1 high, ■ 2 medium, ■ 0 low, ■ 0 none, ■ 0 unknown
  →  report is available at https://mondoo.app/v/tender-elbakyan-495615/gallant-kilby-587371/reports/1P4JUZrB1n6rkKU5J5JthPtP42Q
  ```

# Try with Docker

1. Start the mondoo container 

Starting `mondoo` in a container is very easy:

```
$ docker run -it --entrypoint /bin/sh mondoolabs/mondoo
/ $ mondoo

_____ ______   ________  ________   ________  ________  ________
|\   _ \  _   \|\   __  \|\   ___  \|\   ___ \|\   __  \|\   __  \
\ \  \\\__\ \  \ \  \|\  \ \  \\ \  \ \  \_|\ \ \  \|\  \ \  \|\  \
 \ \  \\|__| \  \ \  \\\  \ \  \\ \  \ \  \ \\ \ \  \\\  \ \  \\\  \
  \ \  \    \ \  \ \  \\\  \ \  \\ \  \ \  \_\\ \ \  \\\  \ \  \\\  \
   \ \__\    \ \__\ \_______\ \__\\ \__\ \_______\ \_______\ \_______\
    \|__|     \|__|\|_______|\|__| \|__|\|_______|\|_______|\|_______|


Mondoo scans operating systems for known vulnerabilities

Usage:
  mondoo [command]

Available Commands:
  help        Help about any command
  register    Registers Mondoo agent with Mondoo Cloud
  scan        Scans an asset for known vulnerabilities
  status      Verifies the access to Mondoo Cloud
  unregister  Unregister Mondoo agent from Mondoo Cloud
  version     Displays the Mondoo agent version

Flags:
      --config string   config file (default is $HOME/.mondoo.yaml)
  -h, --help            help for mondoo

Use "mondoo [command] --help" for more information about a command.

```

2. Register the agent

```
/ $ mondoo register --token 'ey...FlP'
  ✔  agent //agents.api.mondoo.app/spaces/dazzling-hermann-857694/agents/1NmZG4Mt2fKXRrYGvUPiyLG7JyQ registered successfully
```

3. Scan the local container

```
/ $ mondoo scan
Start vulnerability scan:
  →  verify platform access to local://
  →  gather platform details
  →  detected alpine 3.10.0
  →  gather platform packages for vulnerability scan
  →  found 38 packages
  →  analyse packages for vulnerabilities
Advisory Report:
  →  ■ found no advisories
  →  report is available at https://mondoo.app/v/tender-elbakyan-495615/dazzling-hermann-857694/reports/1NmZH5j4FEusxhzN6QsPeniuJJB
```

4. Scan a remote container image from inside the container:

```
/ $ mondoo scan -t docker://centos:7
Start vulnerability scan:
  →  verify platform access to docker://centos:7
  →  gather platform details
  →  detected centos 7.6.1810
  →  gather platform packages for vulnerability scan
  →  found 146 packages
  →  analyse packages for vulnerabilities
Advisory Report:
  ■        PACKAGE       INSTALLED          VULNERABLE (<)       ADVISORY                                                                                     
  ■   9.8  python        2.7.5-76.el7       0:2.7.5-77.el7_6     https://mondoo.app/advisories/RHSA-2019%3A0710  
  ╰─  9.8  python        2.7.5-76.el7       0:2.7.5-80.el7_6     https://mondoo.app/advisories/RHSA-2019%3A1587  
  ■   9.8  python-libs   2.7.5-76.el7       0:2.7.5-77.el7_6     https://mondoo.app/advisories/RHSA-2019%3A0710  
  ╰─  9.8  python-libs   2.7.5-76.el7       0:2.7.5-80.el7_6     https://mondoo.app/advisories/RHSA-2019%3A1587  
  ■   8.8  libssh2       1.4.3-12.el7       0:1.4.3-12.el7_6.2   https://mondoo.app/advisories/RHSA-2019%3A0679  
  ■   8.6  bind-license  32:9.9.4-73.el7_6  32:9.9.4-74.el7_6.1  https://mondoo.app/advisories/RHSA-2019%3A1294  
  ■   4.7  openssl-libs  1:1.0.2k-16.el7    1:1.0.2k-16.el7_6.1  https://mondoo.app/advisories/RHSA-2019%3A0483  
  →  ■ found 5 advisories: 2 critical, 2 high, 1 medium, 0 low, 0 none, 0 unknown
  →  report is available at https://mondoo.app/v/tender-elbakyan-495615/dazzling-hermann-857694/reports/1NmZUg5URmOErNRqjxmLiOJsip1

```



