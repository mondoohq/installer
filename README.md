# Mondoo Cloud-Native Security

![Mondoo Cloud-Native Security](assets/github.splash.png)

## Usage

![Mondoo CLI](assets/mondoo-cli.png)

## Getting Started with Mondoo - Sign up for free account!

Get started with Mondoo by signing up for a free Mondoo Platform account, and install and configure Mondoo Client on your workstation. You can follow our guide at [Mondoo Platform and Mondoo Client setup](https://mondoo.com/docs/tutorials/mondoo/account-setup/).

## Run a security assessment

Mondoo can run security assessments on local, and remote targets including servers (Linux, Windows, macOS), Cloud (AWS, Azure, Google, VMware), Kubernetes (EKS, GKE, AKS, self-managed), containers, container registries, SaaS products (MS365, GitHub, GitLab), and more.

Run a scan:

```bash
# scan your local host
mondoo scan local

# scan a cloud environment
mondoo scan aws
mondoo scan gcp
mondoo scan azure

# scan a kubernetes cluster
mondoo scan k8s

# scan a docker image from remote registry
mondoo scan docker image centos:7

# scan a docker container (get ids from docker ps)
mondoo scan docker container 00fa961d6b6a

# scan a system over ssh
mondoo scan ssh ec2-user@54.76.229.223
```

**Mondoo Scripts**

- [install.sh](./install.sh) - Mondoo Client Bash Installer for Servers
- [download.sh](./download.sh) - Mondoo Client Bash Downloader for Workstation
- [Dockerfile](./Dockerfile) - Build script for official Mondoo container

**Docker Containers**

- https://hub.docker.com/r/mondoo/client

**Installation Packages**

- [releases.mondoo.com](https://releases.mondoo.com)
