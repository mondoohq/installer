# Terraform & Mondoo

It is very easy to use Mondoo in combination with Terraform. The following documentation helps to ease vulnerabilities & policy assessments during a build process.

### Verifying the Installation

After installing Terraform, Mondoo Agent run the following commands to verify that everything is configured properly:

```
$ terraform
Usage: terraform [-version] [-help] <command> [args]
...

$ mondoo status
  →  mondoo cloud: https://api.mondoo.app
  →  space: //captain.api.mondoo.app/spaces/focused-darwin-833545
  →  agent is registered
  ✔  agent //agents.api.mondoo.app/spaces/focused-darwin-833545/agents/1NairOj7L1Gi7BMQqPbBO4LAQ2v authenticated successfully
```

If you get an error, ensure the tools are properly configured for your system path.

## Basic Example

> The section describes the [Dgital Ocean example](https://github.com/mondoolabs/mondoo/tree/master/examples/terraform-digitalocean). Further examples are available in our [GitHub repo](https://github.com/mondoolabs/mondoo/tree/master/examples)

The following is a fully functional Terraform configuration that launches a DigitalOcean droplet with Nginx installed and a Mondoo vulnerability assessment.

```hcl2
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = ">= 2.5.1"
    }
  }
}

variable "do_token" {
  description = "value of DIGITALOCEAN_TOKEN"
}

provider "digitalocean" {
  token = var.do_token
}

variable "private_key" {
  description = "path to private key"
  default = "~/.ssh/id_rsa"
}

variable "public_key" {
  description = "path to public key"
  default = "~/.ssh/id_rsa.pub"
}

resource "digitalocean_ssh_key" "default" {
  name = "terraform"
  public_key = file(var.public_key)
}

resource "digitalocean_droplet" "mywebserver" {
  ssh_keys = [
    digitalocean_ssh_key.default.fingerprint
  ]
  image              = "ubuntu-18-04-x64"
  region             = "nyc1"
  size               = "s-1vcpu-1gb"
  private_networking = true
  backups            = true
  ipv6               = true
  name               = "sample-tf-droplet"

  # The connection is required to let provisioner's know how to connect
  connection {
    type     = "ssh"
    host     = self.ipv4_address
    user     = "root"
    timeout  = "2m"
    private_key = file(var.private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sudo apt-get update",
      "sudo apt-get -y install nginx",
    ]
  }

  provisioner "local-exec" {
    command = "mondoo scan -t ssh://root@${self.ipv4_address} -i ${var.private_key} --insecure --exit-0-on-success"
  }
}
```

To run the example:

```bash
# set token for DigitalOcean
export DIGITALOCEAN_TOKEN=d1...ef
# run terraform
terraform apply -var do_token=$DIGITALOCEAN_TOKEN
```

To trigger Mondoo, use the `local-exec` and pass in the required arguments to connect to the machine:

```hcl2
provisioner "local-exec" {
  command = "mondoo scan -t ssh://root@${self.ipv4_address} -i ${var.private_key} --insecure --exit-0-on-success"
}
```

## AWS Infrastructure Provisioning Example

This example illustrates the combination of Terraform & Mondoo to build an infrastructure running on AWS. This example is available on [Github](https://github.com/mondoolabs/mondoo/tree/master/examples/terraform-aws). Similar to the example above, it runs `mondoo` for the EC2 instance. In additon, it also runs a scan for the AWS account itself.

***Terraform Configuration***

```hcl
resource "aws_instance" "web" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    host    = coalesce(self.public_ip, self.private_ip)
    type    = "ssh"
    user    = "ubuntu"
    timeout = "2m"
    private_key = file(var.private_key)
  }

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region as we specified
  ami = var.aws_amis[var.aws_region]

  # The name of our SSH keypair we created above.
  key_name = aws_key_pair.auth.id

  # Our Security group to allow HTTP and SSH access
  security_groups = [aws_security_group.default.name]

  # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80s
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install nginx",
      "sudo service nginx start",
    ]
  }

  # run scan of instance
  provisioner "local-exec" {
    command = "mondoo scan -t ssh://ubuntu@${coalesce(self.public_ip, self.private_ip)} -i ${var.private_key} --insecure --exit-0-on-success"
  }
}

# run scan of aws account
resource "null_resource" "example1" {
  provisioner "local-exec" {
    command = "mondoo scan -t aws:// --option 'region=${var.aws_region}' --exit-0-on-success"
  }

  depends_on = [
    "aws_instance.web"
  ]
}

```

***Terraform Apply***

To run the full example, clone the examples first:

```
$ git clone https://github.com/mondoolabs/mondoo.git
$ cd mondoo/examples/terraform-aws
```

Verify that everything is in place for the infrastructure:

```
terraform init
```

Now we are ready to provision a new EC2 instance:

```bash
$ terraform apply -var 'key_name=terraform' -var 'public_key=~/.ssh/id_rsa.pub' -var 'private_key=~/.ssh/id_rsa'
```

You can easily destroy the setup via:

```
$ terraform destroy -var 'key_nameterraform' -var 'public_key=~/.ssh/id_rsa.pub' -var 'private_key=~/.ssh/id_rsa'
```