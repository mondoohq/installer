# The Mondoo Agent

The Mondoo agent is a small & cross-platform binary that makes it easy to assess system vulnerabilities. Its main responsibility is to determine installed packages and send the package list including their versions for further analysis to Mondoo's vulnerability database.

![Mondoo CLI](../assets/mondoo-cli.png)

## Installation

<style>
a.agents {
  text-decoration: none;
  border: none;
}

a:hover.agents {
  opacity: 0.6;
}

a.agents img {
  width: 150px;
  margin-right:10px;
}
</style>

<a href="/docs/agent/windows" class="agents"><img src="../assets/button-windows.png" class="agents"/></a><a href="/docs/agent/macos" class="agents"><img src="../assets/button-macos.png"/></a><a href="/docs/agent/redhat" class="agents"><img src="../assets/button-redhat.png"/></a><a href="/docs/agent/amazonlinux" class="agents"><img src="../assets/button-amzn.png" /></a>

<a href="/docs/agent/ubuntu" class="agents"><img src="../assets/button-ubuntu.png"/></a><a href="/docs/agent/redhat" class="agents"><img src="../assets/button-centos.png" class="agents"/></a><a href="/docs/agent/ubuntu" class="agents"><img src="../assets/button-debian.png" class="agents"/></a><a href="/docs/agent/suse" class="agents"><img src="../assets/button-suse.png" class="agents"/></a>

<a href="/docs/agent/ansible" class="agents"><img src="../assets/button-ansible.png"/></a><a href="/docs/agent/chef" class="agents"><img src="../assets/button-chef.png"/></a>


## How it works

The agent works by continuously assessing the installed packages and submitting the package metadata to Mondoo API over HTTPS. After the registration with your Mondoo Space, the agent is ready for vulnerability assessments.

The CLI is designed for two use cases:

 * run as service for continuous vulnerability assessment
 * run on workstation to assess vulnerabilities for remote systems or docker images
 * run docker image scan as part of a CI/CD

**Use case: Service**

You want to see the vulnerability assessment of your server continuously. The agent runs in background and submits changes of the installed packages for vulnerability analysis. By using this approach, you always have the latest view on your infrastructure.

**Use case: Workstation or CI/CD**

You want to assess the vulnerabilities of a system that is accessible via SSH. 

```
mondoo vuln -t ssh://ec2-user@54.146.196.40
Start vulnerability scan:
  →  verify platform access to ssh://ec2-user@54.146.196.40
  →  gather platform details
  →  detected amzn 2
  →  gather platform packages for vulnerability scan
  →  found 433 packages
  →  analyse packages for vulnerabilities
Advisory Report:
  →  ■ found no advisories
  →  report is available at https://mondoo.app/v/goofy-hofstadter-187738/gallant-payne-155889/reports/1NmpiPcVfQZLT2GDylRjOc1wSMh
```

Another option is to quickly scan a docker image stored in a docker registry:

```
mondoo vuln -t docker://centos:7
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
  →  report is available at https://mondoo.app/v/goofy-hofstadter-187738/gallant-payne-155889/reports/1NmZsWAQUmlXGtf5dqt083hfRJx
exit status 104
```

The agent can scan the following assets:

* Local Operating System
* Remote Operating System via SSH
* Docker images (local or remote)
* Docker containers (running or stopped)

## Installation

The agent can be installed onto various operating systems. We provide [installers](./installation) to make it easy to run and manage Mondoo agents.

## Usage

```
mondoo help

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

See the [Mondoo CLI](./mondoo) instructions to get started.

## Configuration

The agent uses a yaml configuration file. See the [configuration documentation](./configuration) for more details.

## Troubleshooting

For help with the installation, visit the [diagnosing documentation](./diagnosing) or contact [Mondoo Support](../help).
