terraform {
  required_providers {
    digitalocean = {
      source = "hashicorp/null"
      version = ">= 3.1.0"
    }
  }
}

provider "null" {}

resource "null_resource" "example1" {
  provisioner "local-exec" {
    command = "mondoo scan -t ${var.conn}://${var.user}@${var.host} --password ${var.password} --exit-0-on-success"
  }
}
