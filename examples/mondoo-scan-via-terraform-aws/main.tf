# Kudos to https://github.com/terraform-providers/terraform-provider-aws for their great example

terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

variable "public_key" {
  description = "Path to the SSH public key to be used for authentication. Example: ~/.ssh/terraform.pub"
  default = "~/.ssh/id_rsa.pub"
}

variable "private_key" {
  description = "path to private key"
  default = "~/.ssh/id_rsa"
}

variable "key_name" {
  description = "Desired name of AWS key pair"
  default = "Terraform Key"
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
  public_key = file(var.public_key)
}

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
# see https://www.terraform.io/docs/language/resources/provisioners/null_resource.html
resource "null_resource" "example1" {
  provisioner "local-exec" {
    command = "mondoo scan -t aws:// --option 'region=${var.aws_region}' --exit-0-on-success"
  }

  depends_on = [
    "aws_security_group.default",
    "aws_instance.web"
  ]
}


output "instance_id" {
  value = aws_instance.web.id
}
