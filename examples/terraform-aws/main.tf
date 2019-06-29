# Kudos to https://github.com/terraform-providers/terraform-provider-aws for their great example

variable "public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.
Example: ~/.ssh/terraform.pub
DESCRIPTION
}

variable "key_name" {
  description = "Desired name of AWS key pair"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

# Ubuntu Precise 16.04 LTS (x64)
# see https://cloud-images.ubuntu.com/locator/ec2/ for updates  
variable "aws_amis" {
  default = {
    eu-central-1 = "ami-0085d4f8878cddc81"
    eu-west-1    = "ami-03746875d916becc0"
    us-east-1    = "ami-0cfee17793b08a293"
    us-west-1    = "ami-09eb5e8a83c7aa890"
    us-west-2    = "ami-0b37e9efc396e4c38"
  }
}

# Specify the provider and access details
provider "aws" {
  region = var.aws_region
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "terraform_example"
  description = "Used in the terraform"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

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

