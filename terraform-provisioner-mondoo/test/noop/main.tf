provider "null" {}

resource "null_resource" "mondoo" {
  provisioner "mondoo" {
    reporter = {
      format = "yaml"
    }

    connection {
      type = "${var.conn}"
      host = "${var.host}"
      user = "${var.user}"
    }

    on_failure = "continue"
  }
}