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

