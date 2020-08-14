# AWS Integration

Mondoo offers a wide range of choices to collect risk information about workload running in your AWS account:

**Gather vulnerability information during build-time**

 - [Risk assessment in AWS Codebuild](../cicd/aws-codebuild.md#aws-codebuild)
 - [Risk assessment for AWS ECR](../registry/aws_ecr.md#aws-elastic-container-registry)
 - [Build AMIs with Packer](../devops/packer.md)
 - [Test Docker Images in AWS CodeBuild](../cicd/aws-codebuild.md)

**Gather vulnerability information during run-time**

  - [Scan AWS EC2 instances from your workstation](#scan-from-workstation)
  - [Install mondoo agent via CloudInit](../installation/cloudinit.md#aws-ec2-instance-user-data)
  - [Terraform deployment](../devops/terraform.md)
  - [Verify instances managed by Chef/AWS OpsWorks](../installation/chef.md)
  - [Verify instances managed by Ansible](../installation/ansible.md)
  - Assess risk of newly deployed EC2 instances automatically

## Scan from Workstation

Ensure you have your AWS credentials configured properly:

```bash
$ cat ~/.aws/credentials
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[mondoo]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

If you want to use a specific profile, set `AWS_PROFILE`

```bash
$ export AWS_PROFILE=mondoo
```

You can also set the region:

```bash
$ export AWS_REGION=us-east-1
```

Now, you are ready to scan the EC2 instances:

```bash
$ mondoo scan -t ec2://profile/name/region/us-east-1
$ mondoo scan -t ec2://region/us-east-1
$ mondoo scan -t ec2://user/ec2-user
$ mondoo scan -t ec2://profile/mondoo/region/us-east-1/user/ec2-user
```

![Mondoo AWS EC2 instances scan from CLI](../static/videos/aws-ec2-scan.gif)

> Note: mondoo uses `~/.ssh/config` to determine the users for each detected public IP

Instead of using the same ssh username for all instances, you can also configure the SSH config and configure the username for each instance with their username:

```bash
Host 123.123.123.123
  User chris

Host yourdomain.com
  IdentityFile /your/path/keyname
````

If you require a specific list of instances with more detailed configuration, consider the use of an [Ansible inventory](../devops/ansible.md)