# Mondoo Cloud-Native Security

![Mondoo Cloud-Native Security](assets/title.png)

## Usage

![Mondoo CLI](docs/assets/mondoo-cli.png)

## Quick Start

Install `mondoo`:

***Workstation***

```
export MONDOO_REGISTRATION_TOKEN='changeme'
curl -sSL http://mondoo.io/download.sh | bash
```

***Service***

```
export MONDOO_REGISTRATION_TOKEN='changeme'
curl -sSL http://mondoo.io/install.sh | bash
```

For other installation methods, have a look at our [documentation](https://mondoo.io/docs/agent/).


Run a scan:

```
# scan a docker image from remote registry
mondoo scan -t docker://centos:7

# scan docker container (get ids from docker ps)
mondoo scan -t docker://00fa961d6b6a

# scan a ssh instance
mondoo scan -t ssh://ec2-user@54.76.229.223
```

## Repository Structure

**Mondoo Deployment**
- [ansible-mondoo](./deployment/ansible-mondoo) - Ansible role for Mondoo
- [chef-mondoo](./deployment/chef-mondoo) - Chef cookbook for Mondoo
- [install.sh](./install.sh) - Mondoo Agent Bash Installer for Servers
- [download.sh](./download.sh) - Mondoo Agent Bash Downloader for Workstation
- [Dockerfile](./Dockerfile) - Build script for official Mondoo container

**Mondoo Integration**
- [packer-provisioner-mondoo](./packer-provisioner-mondoo) - Mondoo Packer Provisioner
- [terraform-provisioner-mondoo](./terraform-provisioner-mondoo) - Mondoo Terrafrom Provisioner

**Examples**

 - [ansible-aws-ec2](./examples/ansible-aws-ec2) - Ansible Playbook to deploy Mondoo Agents
 - [chef-aws-ec2](./examples/chef-aws-ec2) - Chef Wrapper Cookbook to deploy Mondoo Agents
 - [cloudinit](examples/cloudinit) - Lauch instance on AWS with Mondoo Agent
 - [docker](./examples/docker) - Play with Docker & Mondoo
 - [packer-aws](./examples/packer-aws) - Build & Scan AMI on AWS
 - [packer-digitalocean](./examples/packer-digitalocean) - Build & Scan image on Digitalocean
 - [terraform-aws](./examples/terraform-aws) - Launch & Scan instance on AWS
 - [terraform-digitalocean](./examples/terraform-digitalocean) - Launch & Scan instance on Digitalocean
 - [vagrant](./examples/vagrant) - Spin-up Mondoo agents in Vagrant

 **Docs**

  - [docs](./docs) - Source for Mondoo documentation (uses [docsify](https://docsify.js.org/#/quickstart))

