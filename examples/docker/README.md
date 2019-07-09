# Run Mondoo in Docker

1. Start the mondoo container 

Starting `mondoo` in a container is very easy:

```
$ docker run -it mondoolabs/mondoo /bin/sh
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
  status      Verifies the access to Mondoo Cloud
  unregister  Unregister Mondoo agent from Mondoo Cloud
  version     Displays the Mondoo agent version
  vuln        Scans an asset for known vulnerabilities

Flags:
      --config string   config file (default is $HOME/.mondoo.yaml)
  -h, --help            help for mondoo

Use "mondoo [command] --help" for more information about a command.

```

2. Register the agent

```
/ $ mondoo register --token 'eyJhbGciOiJFUzM4NCIsImtpZCI6IiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsibW9uZG9vIl0sImV4cCI6MTU2MjY4OD
E3OCwiaWF0IjoxNTYyNjg4MTE4LCJpc3MiOiJtb25kb28vYW1zIiwibmJmIjoxNTYyNjg4MTE4LCJzcGFjZSI6Ii8vY2FwdGFpbi5hcGkubW9uZG9vLmFwcC
9zcGFjZXMvZGF6emxpbmctaGVybWFubi04NTc2OTQiLCJzdWIiOiJhZ2VudCJ9.4as1CepoT-2XEmneW2Tkpkfope7drUvZdui2oGbXtt8l5U0JegfOIpecp
fFYXn_cOA2fnoJwLJsPC63vKGZDiuDI9NKA6B3VRY8T8teJpt4S1wKmxLO-ab_2k05F3FlP'
  ✔  agent //agents.api.mondoo.app/spaces/dazzling-hermann-857694/agents/1NmZG4Mt2fKXRrYGvUPiyLG7JyQ registered successfully
```

3. Scan the local container

```
/ $ mondoo vuln
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
/ $ mondoo vuln -t docker://centos:7
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