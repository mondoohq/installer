variable "ssh_fingerprint" {
  description = <<DESCRIPTION
Fingerpring of your ssh key
- Get your ssh fingerprint from https://cloud.digitalocean.com/account/security
- Obtain your ssh_key id number via your account. See Document https://developers.digitalocean.com/documentation/v2/#list-all-keys
DESCRIPTION
  default = "5e:f8:07:77:14:db:ab:73:b5:62:69:79:66:04:8e:86"
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

