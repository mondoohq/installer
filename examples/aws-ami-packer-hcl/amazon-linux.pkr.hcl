variable "aws_access_key" {
  type    = string
  default = env("AWS_ACCESS_KEY_ID")
}

variable "aws_secret_key" {
  type    = string
  default = env("AWS_SECRET_ACCESS_KEY")
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

locals {
  ami_name = "aws-ami-example ${local.timestamp}"
}

source "amazon-ebs" "example_build" {
  access_key    = var.aws_access_key
  ami_name      = local.ami_name
  instance_type = "t2.micro"
  region        = "us-east-1"
  secret_key    = var.aws_secret_key
  source_ami    = "ami-04902260ca3d33422"
  ssh_username  = "ec2-user"
}

build {
  sources = ["source.amazon-ebs.example_build"]

  provisioner "shell" {
    inline = ["ls -al /home/ec2-user"]
  }

  provisioner "mondoo" {
    labels = {
      "mondoo.app/ami-name" = "${local.ami_name}"
      name                  = "Packer Builder"
    }
    on_failure = "continue"
  }
}
