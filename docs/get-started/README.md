# Hello, Mondoo

Mondoo is designed to help you identify risk across your fleet. It [integrates very well](../integration) in your infrastructure. Out-of-the-box Mondoo ships with integration for major cloud environments, CI/CD environments and build tools like [Packer](../integration/devops/packer) as well as provisioning tools like [Terraform](../integration/devops/terraform), [Ansible](../agent/installation/ansible) and [Chef](../agent/installation/chef).

Mondoo support vulnerability scanning for the following environments:

- [SSH Targets](usage#ssh-targets)
- [Ansible Inventory](usage#ansible-inventory)
- [Local System](usage#local-system)
- [Azure Compute Instances](usage#azure-instances)
- [AWS EC2 Instances](usage#aws-ec2-instances)
- [GCP Compute Instances](usage#gcp-instances)
- [Kubernetes](usage#kubernetes)
- [Docker Images](usage#docker-images)
- [Docker Container](usage#docker-container)
- [Azure Container Registry](usage#azure-container-registry)
- [AWS Elastic Container Registry](usage#aws-elastic-container-registry)
- [Docker Hub Repository](usage#aws-elastic-container-registry)
- [Google Cloud Container Registry](usage#google-cloud-container-registry)
- [Harbor Registry](usage#harbor-registry)

The following operating systems are supported:

- Amazon Linux 1, 2
- CentOS 6, 7, 8
- Debian 8, 9, 10
- openSUSE
- Oracle Linux 6, 7, 8
- RedHat 6, 7, 8
- Suse 12, 15
- Ubuntu 14.04, 16.04, 18.04
- Windows Server 2016, 2019

Mondoo can report on terminal:

![Mondoo CLI report](../assets/mondoo-cli.png)

In your Mondoo dashboard:

![See report in Mondoo dashboard](../assets/mondoo-cicd-awscodebuild-result-dashboard.png)

Or in your CI/CD environment:

![See report in CI/CD](../assets/mondoo-cicd-awscodebuild-result-text.png)
