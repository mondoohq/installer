# Scan Docker images inside the Mondoo container

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

All agents use a secure private key to sign their data. Via a registration token, the agent is able to retrieve its credentials securely. Use the [dashboard](../agent/installation/registration#agent-registration) to gather a new registration token.

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



