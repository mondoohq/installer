# Mondoo Terraform Provisioner

Mondoo ships an integration for [Terraform](https://www.terraform.io/) to ease the assessment of vulnerabilities during an image build process. The integration is open source and available in our [Mondoo GitHub repository](https://github.com/mondoolabs/mondoo)

## Install Mondoo Packer Provisioner

The Mondoo Packer Provisioner depends on:

  * [Terraform CLI installed on workstation](https://learn.hashicorp.com/terraform/getting-started/install.html)
  * [Mondoo CLI installed on workstation](../agent/installation)

The provisioner plugin may be installed via:

  * Pre-compiled binary (recommended)
  * From Source (advanced)

### Install packer plugin from binary

To install the precompiled binary, download the appropriate package from [Github](https://github.com/mondoolabs/mondoo/releases/latest) and place the binary in Terraform's plugin directory `~/.terraform.d/plugins` (Linux, Mac) or `%USERPROFILE%/terraform.d/plugins` (Windows). Other locations that Terraform searches for are [documented on their website](https://www.terraform.io/docs/extend/how-terraform-works.html#plugin-locationss).

The following simplifies the installation:

**Linux**

```
mkdir -p ~/.terraform.d/plugins
cd ~/.terraform.d/plugins
curl https://github.com/mondoolabs/mondoo/releases/0.3.0/latest/terraform-provisioner-mondoo_0.3.0_linux_amd64.tar.gz | tar -xz > terraform-provisioner-mondoo
chmod +x terraform-provisioner-mondoo
```

**Mac**

```
mkdir -p ~/.terraform.d/plugins
cd ~/.terraform.d/plugins
curl https://github.com/mondoolabs/mondoo/releases/0.3.0/latest/terraform-provisioner-mondoo_0.3.0_darwin_amd64.tar.gz | tar -xz > terraform-provisioner-mondoo
chmod +x terraform-provisioner-mondoo
```

### Compiling the Terraform plugin from source

If you wish to compile from source, you need to have [Go](https://golang.org/) installed and configured.

1. Clone the mondoo repository from GitHub into your $GOPATH:

```
$ mkdir -p $(go env GOPATH)/src/github.com/mondoolabs && cd $_
$ git clone https://github.com/mondoolabs/mondoo.git
$ cd mondoo/terraform-provisioner-mondoo
```

2. Build the plugin for your current system and place the binary in the packer plugin directory

```
make install
```

### Verifying the Installation 

After installing Terraform, Mondoo Agent and the Mondoo Terraform Provisioning Plugin run the following commands to check that everything is configured properly:

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

Once the plugin is installed, you can use the provisioner by adapting your `instance` configuration. The following is a fully functional Terraform configuration that launches a DigitalOcean droplet with Nginx installed and a Mondoo vulnerability assessment.

```
variable "ssh_fingerprint" {
  description = <<DESCRIPTION
The fingerprint of your ssh key
- Get your ssh fingerprint from https://cloud.digitalocean.com/account/security
- Obtain your ssh_key id number via your account. See Document https://developers.digitalocean.com/documentation/v2/#list-all-keys
DESCRIPTION
}

provider "digitalocean" {
  # set the DIGITALOCEAN_TOKEN environment variable before calling
  # terraform apply:
  # export DIGITALOCEAN_TOKEN="Your API TOKEN"
}

resource "digitalocean_droplet" "mywebserver" {
  ssh_keys = [
    var.ssh_fingerprint,
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
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sudo apt-get update",
      "sudo apt-get -y install nginx",
    ] 
  }

  provisioner "mondoo" {
    report = {
      format = "cli"
    }

    # by default we recommend to pass provisioning even if mondoo found vulnerabilities
    on_failure = continue
  }
}
```

To run the example, run `terraform`:

```
export DIGITALOCEAN_TOKEN="Your API TOKEN"
terraform apply do-nginx.json 
```

## Mondoo Terraform Provisioner Configuration Reference

Required Parameters:

  * none

Optional Parameters:

  * `report.format` (string) - The format can be set to `cli` or `yaml`

  * `collector` (string) - The collector reports the packages to Mondoo cloud only and does not print the result on CLI. Supported values are `http` and `awssns` 

  * `on_failure` (string) - If on_failure is set to `continue` terraform continues even if vulnerabilities have been found
  
  ```
  "on_failure": "continue",
  ```

  * `labels` (map of string) - Custom labels can be passed to mondoo. This eases searching for the correct asset report later.

```
"labels": {
  "mondoo.app/ami-name":  "{{user `ami_name`}}",
  "name":"Packer Builder",
  "custom_key":"custom_value"
}
```

## AWS Infrastructure Provisioning Example

This example illustrates the combination of Terraform & Mondoo to build an infrastructure running on AWS. The source for this example is available on [Github](https://github.com/mondoolabs/mondoo/tree/master/examples/terraform-aws). Further examples are available in our [GitHub repo](https://github.com/mondoolabs/mondoo/tree/master/examples), eg. for [DigitalOcean](https://github.com/mondoolabs/mondoo/tree/master/examples/terraform-digitalocean).

***Terraform Configuration***

```
resource "aws_instance" "web" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    host    = coalesce(self.public_ip, self.private_ip)
    type    = "ssh"
    user    = "ubuntu"
    timeout = "2m"
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

  provisioner "mondoo" {
    report = {
      format = "cli"
    }

    # by default we recommend to pass provisioning even if mondoo found vulnerabilities
    on_failure = continue
  }
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

## Uninstall

You can easily uninstall the provisioner by removing the binary.

```
# linux & mac
rm ~/.terraform.d/plugins/terraform-provisioner-mondoo
```