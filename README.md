# Mondoo Cloud-Native Security

![Mondoo Cloud-Native Security](assets/github.splash.png)

## Usage

![Mondoo CLI](assets/mondoo-cli.png)

## Quick Start

Install `mondoo`:

***Workstation***

```bash
export MONDOO_REGISTRATION_TOKEN='changeme'
curl -sSL http://mondoo.io/download.sh | bash
```

***Service***

```bash
export MONDOO_REGISTRATION_TOKEN='changeme'
curl -sSL http://mondoo.io/install.sh | bash
```

For other installation methods, have a look at our [documentation](https://docs.mondoo.io/server/overview).

Run a scan:

```bash
# scan a docker image from remote registry
mondoo scan -t docker://centos:7

# scan docker container (get ids from docker ps)
mondoo scan -t docker://00fa961d6b6a

# scan a ssh instance
mondoo scan -t ssh://ec2-user@54.76.229.223
```

## Examples

### AWS

Example   | Description |
--------- | --------- |
[packer-aws](./examples/packer-aws) | Build & Scan AMI on AWS |
[mondoo-scan-via-terraform-aws](./examples/mondoo-scan-via-terraform-aws) | Launch & Scan instance on AWS |

### Digital Ocean

Example   | Description |
--------- | --------- |
[packer-digitalocean](./examples/packer-digitalocean) | Build & Scan image on Digitalocean |
[mondoo-scan-via-terraform-digitalocean](./examples/mondoo-scan-via-terraform-digitalocean) | Launch & Scan instance on Digitalocean |

### Mondoo Client

Example   | Description |
--------- | --------- |
[mondoo-deploy-ansible](./examples/mondoo-deploy-ansible) | Ansible Playbook to deploy Mondoo Client |
[mondoo-deploy-chef](./examples/mondoo-deploy-chef) | Chef Cookbook to deploy Mondoo Client |
[mondoo-trial-vagrant](./examples/mondoo-trial-vagrant) | Spin-up Mondoo Client in Vagrant |


**Mondoo Scripts**

- [install.sh](./install.sh) - Mondoo Agent Bash Installer for Servers
- [download.sh](./download.sh) - Mondoo Agent Bash Downloader for Workstation
- [Dockerfile](./Dockerfile) - Build script for official Mondoo container
