provider "null" {}

resource "null_resource" "mondoo" {
  provisioner "mondoo" {
    report = {
      format = "cli"
    }

    # this is for testing here, normallly this does not need to be overridden
    connection {
      type = "${var.conn}"
      host = "${var.host}"
      user = "${var.user}"
      password = "${var.password}"
    }
  }
}