provider "digitalocean" {
  # You need to set this in your .bashrc
  # export DIGITALOCEAN_TOKEN="Your API TOKEN"
  #
}

resource "digitalocean_droplet" "mywebserver" {
  # Obtain your ssh_key id number via your account. See Document https://developers.digitalocean.com/documentation/v2/#list-all-keys
  ssh_keys           = [24269831]         # Key example
  image              = "ubuntu-18-04-x64"
  region             = "ams3"
  size               = "s-1vcpu-1gb"
  private_networking = true
  backups            = true
  ipv6               = true
  name               = "mywebserver-ams3"

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sudo apt-get update",
      "sudo apt-get -y install nginx",
    ]

    connection {
      type     = "ssh"
      user     = "root"
      timeout  = "2m"
    }
  }

  provisioner "mondoo" {
    reporter {
      name = "cli"
    }

    connection {
      type = "ssh"
      user     = "root"
      timeout  = "2m"
    }

    on_failure = "continue"
  }
}
