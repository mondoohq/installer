# AWS

Mondoo offers a wide range of choices to collect risk information about the workload running in your AWS account:

**Gather vulnerability information during build-time**

 - [Risk assessment in AWS Codebuild](../cicd/aws-codebuild.md#aws-codebuild)
 - [Risk assessment for AWS ECR](../registry/aws_ecr.md#aws-elastic-container-registry)
 - [Build AMIs with Packer](../devops/packer.md)
 - [Test Docker Images in AWS CodeBuild](../cicd/aws-codebuild.md)

**Gather vulnerability information during run-time**

  - [Event-based and scheduled scanning with Mondoo-AWS Integration](#mondoo-aws-integration)
  - [Scan AWS EC2 instances from your workstation](#scan-from-workstation)
  - [Install mondoo agent via CloudInit](../installation/cloudinit.md#aws-ec2-instance-user-data)
  - [Terraform deployment](../devops/terraform.md)
  - [Verify instances managed by Chef/AWS OpsWorks](../installation/chef.md)
  - [Verify instances managed by Ansible](../installation/ansible.md)
  - Assess risk of newly deployed EC2 instances automatically

# Mondoo AWS Integration

Use the AWS integration to enable cron-scheduled and [event-based](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-service-event.html) scanning of your AWS account and EC2 instances.
- [Create](#create)
- [List and View](#list-and-view)
- [Remove](#remove)
- [Troubleshooting](#troubleshooting)


## How it works 
We use AWS Cloudformation to setup the Mondoo Lambda function in the desired account. The lambda function scans the account and EC2 instances on the desired cron schedule. It communicates with Mondoo Cloud to find the appropriate policies and sends all results to Mondoo Cloud.

The AWS Cloudformation JSON is available as part of the [`mondoo-lambda-prod` S3 bucket](https://s3.console.aws.amazon.com/s3/buckets/mondoo-lambda-prod?region=us-east-1&tab=objects).

## Create

The Mondoo AWS Integration create screen can be accessed three ways:
   - initial wizard screen: [select "AWS" environment](#wizard-screen-photo)
   - fleet screen: [select "Add Integration" under "AWS Accounts"](#fleet-aws-screen-photo)
   - left hand menu of [fleet add screen](#fleet-add-menu)

![integration-create-image](./images/aws-integration-create.png)

After entering your AWS Account ID, selecting your desired scan configuration options, and clicking create, you will be redirected to the integration view page where a notification will appear with a link to launch the Cloudformation stack.

*<b>Please note: you must launch the AWS Cloudformation stack to complete the setup.</b>*

Scan Configuration options, explained:

  _Note: All references to "Event" in the scan configuration options is a reference to [AWS EventBridge Events](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-service-event.html)_ 

- Re-assess schedule in hours: the interval at which scans should be executed
- Account
    - Trigger on AWS Console Sign-in Event: trigger an account scan whenever a user signs in to the aws console 
    - Trigger on S3 Bucket Event: trigger an account scan whenever a change is made to an S3 bucket
- EC2
    - Discover Instances: find all ec2 instances in the account (across all regions)
    - Connect via SSM: use ssm to scan the instance when available 
    - Connect via SSH: use ssh to scan instances, using the secrets metadata query and aws secrets manager vault to retrieve the secrets
    - Secrets Metadata Query: see [Mondoo vault docs](../getstarted/vault.md)
    - Optional Filters: instance scanning can be filtered to a subset of regions, instance ids, or tags
    - Trigger on Instance State Change Event: trigger a scan of all EC2 instances whenever an instance state changes
    - Trigger on EC2 Autoscaling Event: trigger a scan of all EC2 instances on all autoscaling events
- ECR
   - Discover Images: find all container images stored in ECR (across all regions)
   - Trigger on Image Action Event: trigger a scan of all ECR images on any ECR image action event 

## List and View
A list of integrations and a detail page for each is available on the `FLEET` page:

![integration-list-image](./images/aws-integration-list.png)

Clicking on any of the integration rows will lead to the details page for that integration.

![integration-detail-image-top](./images/aws-integration-detail-top.png)

The primary screen provides you with general information about the integration. This is where status and errors will be reported.

Below, there are three tabs: 
- Overview: List of resources Mondoo has discovered in your AWS account
- Recommended Policies: Enable and disable recommended polcies
- Configuration: Edit your scan configuration options


## Remove
When removing an AWS Integration from Mondoo server, a notification will appear with a link to the AWS Cloudformation Stacks list page for easy stack deletion. The configured integration will be removed from Mondoo, and the rule allowing the Mondoo AWS account to send events to the target account will be deleted. 

_Please note: Mondoo will not delete you AWS Cloudformation stack for you. You must follow the link and delete the stack in the AWS Console._

## Troubleshooting & FAQ

### Cloudformation Failure
If Cloudformation fails to complete creating the stack for whatever reason, that failure will be reported in the Mondoo UI. Please check the AWS Cloudformation UI for more information about the error, resolve as instructed, and visit the "Configuration" tab of the integration detail view to re-launch the stack.

### Lambda VPC Access
The AWSLambdaVPCAccessExecutionRole is already attached to the Mondoo Lambda Role for the function. Should your lambda function require VPC access to be able to scan instances, please refer to https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html to attach the lambda function to the appropriate VPC. You will also need to configure your security group to allow outbound traffic to [mondoo app](https://mondoo.app) from the labda function and ssm instances.

## Statuses
The possible statuses for the AWS Integration are: 
- waiting for cloudformation: Cloudformation either hasn't started yet or hasn't yet created the iam role allowing Mondoo to talk to the target account yet
- setup in progress: the iam role allowing Mondoo to talk to the target account has been created, Cloudformation is still in progress
- registering: the integration is registering with Mondoo
- configuring: Mondoo is sending the integration the scan configuration opetions; the integration is saving those options
- active: Integration is active/healthy

## Action Buttons
There are a few action buttons on the integration read page:
- Trigger Scan: sends a message to the integration to trigger a scan
- Ping: sends a ping message to the integration. the integration should respond by sending a checkin message to Mondoo, and the last ping time will be updated
- Retry Setup: if an error occurred during setup, and the Cloudformation stack is now up and running but the integration is unhealthy, use Retry Setup to get it back to a healthy place

## Reference Images

### wizard-screen-photo
![wizard-screen](./images/wizard-screen.png)
### fleet-aws-screen-photo
![add-aws-account](./images/add-aws-account.png)
### fleet-menu-add
![fleet-add-menu](./images/fleet-add-menu.png)


# Scan from Workstation

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
