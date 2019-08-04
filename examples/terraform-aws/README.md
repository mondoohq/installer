# Scan AWS EC2 instances for vulnerabilities with Terraform and Mondoo

This example demonstrates the use of spinning up an AWS instance with Terraform and scanning that instance with Mondoo.

## Preconditions

 * [AWS Account](https://aws.amazon.com/free/)
 * [Terraform CLI installed on workstation](https://learn.hashicorp.com/terraform/getting-started/install.html)
 * [Mondoo CLI installed on workstation](https://mondoo.io/docs/agent/installation)
 * [Mondoo Terraform Provisioner](https://mondoo.io/docs/apps/terraform)


## Build Infrastructure

Verify that everything is in place for the infrastructure:

```
terraform init
```

Now, we are ready to spin up an instance. As a parameter, the terraform configuration requires an ssh key that is configured with the local ssh-agent. All Terraform provisioners will use it to connect to the instance remotely.

```
$ terraform apply -var 'key_name={your_aws_key_name}' \
   -var 'public_key_path={location_of_your_key_in_your_local_machine}'
```

```
$ terraform apply -var 'key_name=chris-rock' -var 'public_key_path= /users/chris-rock/.ssh/id_rsa.pub'

aws_key_pair.auth: Refreshing state... [id=chris-rock]
aws_security_group.default: Refreshing state... [id=sg-0674c664601a7f8ad]

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_instance.web will be created
...

aws_instance.web (remote-exec): Processing triggers for ufw (0.35-0ubuntu2) ...
aws_instance.web: Provisioning with 'mondoo'...
aws_instance.web (mondoo): start mondoo provisioner
aws_instance.web (mondoo): Executing: vuln
aws_instance.web (mondoo): Start vulnerability scan:
aws_instance.web (mondoo):   →  detected automated runtime environment: Terraform
aws_instance.web (mondoo):   →  verify platform access to ssh://ubuntu@54.175.81.209
aws_instance.web: Still creating... [1m10s elapsed]
aws_instance.web (mondoo):   →  gather platform details
aws_instance.web (mondoo):   →  detected ubuntu 16.04
aws_instance.web (mondoo):   →  gather platform packages for vulnerability scan
aws_instance.web (mondoo):   →  found 466 packages
aws_instance.web (mondoo):   →  analyse packages for vulnerabilities
aws_instance.web: Still creating... [1m30s elapsed]
aws_instance.web (mondoo): Advisory Report:
aws_instance.web (mondoo):   ■        PACKAGE                     INSTALLED               VULNERABLE (<)  ADVISORY
aws_instance.web (mondoo):   ■   9.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
aws_instance.web (mondoo):   ├─  9.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
aws_instance.web (mondoo):   ├─  8.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
aws_instance.web (mondoo):   ├─  8.1  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
aws_instance.web (mondoo):   ├─  7.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
aws_instance.web (mondoo):   ├─  7.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
aws_instance.web (mondoo):   ├─  7.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
aws_instance.web (mondoo):   ├─  7.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
aws_instance.web (mondoo):   ├─  7.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
aws_instance.web (mondoo):   ├─  7.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
aws_instance.web (mondoo):   ├─  7.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
...
aws_instance.web (mondoo):   →  ■ found 71 advisories: 2 critical, 14 high, 26 medium, 3 low, 26 none, 0 unknown
aws_instance.web (mondoo):   →  report is available at https://mondoo.app/v/serene-dhawan-599345/focused-darwin-833545/reports/1Nbx4rp7LCK1ogMKj7CCrsZgsJk

aws_instance.web: Creation complete after 1m35s [id=i-02332991769bae321]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

instance_id = i-02332991769bae321

```