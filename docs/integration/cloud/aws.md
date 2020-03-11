# AWS Integration

Mondoo offers a wide range of choices to collect risk information about workload running in your AWS account:

**Gather vulnerability information during build-time**

 - [Build AMIs with Packer](../devops/packer)
 - [Test Docker Images in AWS CodeBuild](../cicd/aws-codebuild)

**Gather vulnerability information during run-time**

  - [Instance provisioning via CloudInit](../../agent/installation/cloudinit#aws-ec2-instance-user-data)
  - [Terraform deployment](../devops/terraform)
  - [Verify instances managed by Chef/AWS OpsWorks](../../agent/installation/chef)
  - [Verify instances managed by Ansible](../../agent/installation/ansible)
  - Assess risk of newly deployed EC2 instances automatically
