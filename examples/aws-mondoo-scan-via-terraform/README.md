# Scan AWS EC2 instances for vulnerabilities with Terraform and Mondoo

This example demonstrates the use of spinning up an AWS instance with Terraform and scanning that instance as well as the AwS account with Mondoo.

## Preconditions

 * [AWS Account](https://aws.amazon.com/free/)
 * [Terraform CLI installed on workstation](https://learn.hashicorp.com/terraform/getting-started/install.html)
 * [Mondoo CLI installed on workstation](https://mondoo.com/docs/getstarted/server)

## Build Infrastructure

Verify that everything is in place for the infrastructure:

```
terraform init
```

Now, we are ready to spin up an instance. As a parameter, the terraform configuration requires an ssh key. The private key is required for `remote-exec` and the `mondoo` command to communicate with the newly created server.

```
$ terraform apply -var 'key_name={your_aws_key_name}' \
   -var 'public_key={path_to_ssh_public_key}' \
   -var 'private_key={path_to_ssh_private_key}'
```

```
$   terraform-aws git:(chris-rock/update-terraform) ✗ terraform apply  

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_instance.web will be created
  + resource "aws_instance" "web" {
      + ami                          = "ami-0cfee17793b08a293"
      + arn                          = (known after apply)
      + associate_public_ip_address  = (known after apply)
      + availability_zone            = (known after apply)
      + cpu_core_count               = (known after apply)
      + cpu_threads_per_core         = (known after apply)
      + get_password_data            = false
      + host_id                      = (known after apply)
      + id                           = (known after apply)
      + instance_state               = (known after apply)
      + instance_type                = "t2.micro"
      + ipv6_address_count           = (known after apply)

...

aws_instance.web: Still creating... [1m0s elapsed]
aws_instance.web: Provisioning with 'local-exec'...
aws_instance.web (local-exec): Executing: ["/bin/sh" "-c" "mondoo scan -t ssh://ubuntu@100.27.0.24 -i ~/.ssh/id_rsa --insecure --exit-0-on-success"]
aws_instance.web (local-exec): → loaded configuration from /Users/chris-rock/.mondoo.yml
aws_instance.web (local-exec):                         .-.
aws_instance.web (local-exec):                         : :
aws_instance.web (local-exec): ,-.,-.,-. .--. ,-.,-. .-' : .--.  .--.
aws_instance.web (local-exec): : ,. ,. :' .; :: ,. :' .; :' .; :' .; :
aws_instance.web (local-exec): :_;:_;:_;`.__.':_;:_;`.__.'`.__.'`.__.'

aws_instance.web (local-exec): → resolve assets
aws_instance.web (local-exec): → discover related assets for 1 assets
aws_instance.web (local-exec): → resolved 1 assets
aws_instance.web (local-exec): → execute policies
aws_instance.web (local-exec): → establish connection to asset 100.27.0.24 (baremetal)
aws_instance.web (local-exec): → verify platform access to 100.27.0.24
aws_instance.web (local-exec): → gather platform details build= platform=ubuntu release=16.04

...

aws_instance.web: Creation complete after 2m17s [id=i-02abc5efc039e0375]
null_resource.example1: Creating...
null_resource.example1: Provisioning with 'local-exec'...
null_resource.example1 (local-exec): Executing: ["/bin/sh" "-c" "mondoo scan -t aws:// --option 'region=us-east-1' --exit-0-on-success"]
null_resource.example1 (local-exec): → loaded configuration from /Users/chris-rock/.mondoo.yml
null_resource.example1 (local-exec):                         .-.
null_resource.example1 (local-exec):                         : :
null_resource.example1 (local-exec): ,-.,-.,-. .--. ,-.,-. .-' : .--.  .--.
null_resource.example1 (local-exec): : ,. ,. :' .; :: ,. :' .; :' .; :' .; :
null_resource.example1 (local-exec): :_;:_;:_;`.__.':_;:_;`.__.'`.__.'`.__.'

null_resource.example1 (local-exec): → resolve assets
null_resource.example1 (local-exec): → discover related assets for 1 assets
null_resource.example1 (local-exec): → resolved 1 assets
null_resource.example1 (local-exec): → execute policies
null_resource.example1 (local-exec): → establish connection to asset AWS Account 123456789ABC (api)
null_resource.example1 (local-exec): → verify platform access to AWS Account 123456789ABC
null_resource.example1 (local-exec): → gather platform details build= platform=aws release=
null_resource.example1 (local-exec): → synchronize asset name="AWS Account 123456789ABC"

...

null_resource.example1: Creation complete after 27s [id=8369796602841781308]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

instance_id = "i-02abc5efc039e0375"


```