# AWS

Mondoo offers a wide range of choices to collect risk information about workload running in your AWS account:

**Gather vulnerability information during build-time**

 - [Risk assessment in AWS Codebuild](../cicd/aws-codebuild.md#aws-codebuild)
 - [Risk assessment for AWS ECR](../registry/aws_ecr.md#aws-elastic-container-registry)
 - [Build AMIs with Packer](../devops/packer.md)
 - [Test Docker Images in AWS CodeBuild](../cicd/aws-codebuild.md)

**Gather vulnerability information during run-time**

  - [Event-based scanning with Mondoo-AWS Integration](#integration)
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
Mondoo provides policies for scanning the security of your AWS account following [CIS Standards](https://www.cisecurity.org/benchmark/amazon_web_services/)
EC2 instances are automatically discovered and can be scanned using SSH or SSM. 
To associate credentials with instances for SSH scanning, please refer to the [Mondoo vault docs](../getstarted/vault.md)

Now, you are ready to scan your AWS account and EC2 instances:

```bash
$ mondoo scan -t aws://
# scan your account and discover all ec2 instances
$ mondoo scan -t aws:// --discover all
```

Use `--discover-filter` to add filters for regions, instance ids, and tags:

```bash
$ mondoo scan -t aws:// --discover all --discover-filter regions=us-east-2 --discover-filter instance-ids=i-06eab6c104c0f5fb0 --discover-filter tags=Name:testnametag
```

## Mondoo AWS Integration

Use the AWS integration to enable cron-scheduled and event-based scanning of your AWS account and EC2 instances.

### How it works 
We use AWS Cloudformation to setup the Mondoo Lambda function in the desired account. The lambda function scans the account and EC2 instances on the desired cron schedule. It communicates with Mondoo Cloud to find the appropriate policies and sends all results to Mondoo Cloud.

### Create
Use the Mondoo UI to create the integration:

![integration-create-image](./aws-integration-create.png)

After entering your AWS Account ID, the browser will open a new tab with AWS Cloudformation loaded, ready to launch the stack. 

Scan Configuration options, explained:
- cron scan in hours: the interval at which scans should be executed
- discover ec2 instances: find the ec2 instances in the account (across all regions)
- use ssm: use ssm to scan the instance when available 
- use ssh: use ssh to scan instances, using the secrets metadata query and aws secrets manager vault to retrieve the secrets
- secrets metadata query: see [Mondoo vault docs](../getstarted/vault.md)
- show ec2 instances filtering options: displays fields to enter in region, instance id, or tag filters. this mirrors the cli `--discover-filter` behaviour noted above

### View
A list of integrations and a detail page for each is available on the agents page:

![integration-list-image](./aws-integration-list.png)

Clicking on any of the integration rows will lead to the details page for that integration. Any errors the server encountered when setting up the integration will be displayed on the details page. This is also where scan configuration options can be edited and a one-off scan triggered.


### Remove
When removing an AWS Integration from Mondoo server, a link will be opened to the AWS Cloudformation Stacks list page for easy stack deletion. The configured integration will be removed from Mondoo, and the rule allowing the Mondoo AWS account to send events to the target account will be deleted. 


### Lambda VPC Access
The AWSLambdaVPCAccessExecutionRole is already attached to the Mondoo Lambda Role for the function. Should your lambda function require VPC access to be able to scan instances, please refer to https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html to attach the lambda function to the appropriate VPC. You will also need to configure your security group to allow outbound traffic to [mondoo app](https://mondoo.app) from the labda function and ssm instances.