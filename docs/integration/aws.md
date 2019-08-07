# AWS Integration

Mondoo offers a wide range of choices to collect information about workload running in your AWS account and covers scanning vulnerabilities for the following use cases:

**Gather vulnerability information during build-time**

 - [Build AMIs with Packer](./packer)
 - [Test Docker Images in AWS CodeBuild](./cicd#aws-codebuild)

**Gather vulnerability information during run-time**

  - [Instance provisioning via CloudInit](../agent/cloudinit#aws-ec2-instance-user-data)
  - [Terraform deployment](./terraform)
  - [Verify instances managed by Chef/AWS OpsWorks](../agent/chef)
  - [Verify instances managed by Ansible](../agent/ansible)
  - Assess risk of newly deployed EC2 instances automatically
