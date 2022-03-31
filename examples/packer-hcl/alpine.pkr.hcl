
source "virtualbox-iso" "alpine" {
  iso_urls = [
    "isos/alpine-virt-3.15.3-x86_64.iso",
    "http://dl-cdn.alpinelinux.org/alpine/v3.15/releases/x86_64/alpine-virt-3.15.3-x86_64.iso"
  ]
  iso_checksum =  "sha256:b432eb9a71b7f5531cb7868c82f405cc63c052358698f44fbfe06103b40fa1bb"

  communicator = "ssh"
  ssh_username = var.sshusername
  ssh_password = var.sshpassword
  shutdown_command = "echo vagrant | sudo -S /sbin/poweroff"

  guest_additions_mode = "disable"
  guest_os_type = "Linux26_64"
  http_directory =  "http"

  boot_wait = "10s"
  boot_command = [
    "root<enter><wait>",
    "ifconfig eth0 up && udhcpc -i eth0<enter><wait10>",
    "wget http://{{ .HTTPIP }}:{{ .HTTPPort }}/answers<enter><wait>",
    "setup-alpine -f $PWD/answers<enter><wait5>",
    "${var.rootpassword}<enter><wait>",
    "${var.rootpassword}<enter><wait>",
    "<wait10>y<enter>",
    "<wait10><wait10>",
    "reboot<enter>",
    "<wait10><wait10>",
    "root<enter><wait5>",
    "${var.rootpassword}<enter><wait5>",
    "echo http://dl-cdn.alpinelinux.org/alpine/v3.15/community/ >> /etc/apk/repositories<enter>",
    "apk add sudo<enter><wait5>",
    "echo 'Defaults env_keep += \"http_proxy https_proxy\"' > /etc/sudoers.d/wheel<enter>",
    "echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/wheel<enter>",
    "adduser ${var.sshusername}<enter><wait5>",
    "${var.sshpassword}<enter><wait>",
    "${var.sshpassword}<enter><wait>",
    "adduser ${var.sshusername} wheel<enter><wait5>",
    "apk add virtualbox-guest-additions virtualbox-guest-modules-virt<enter>",
    "<wait10>"
  ]
}

build {
  sources = [
    "source.virtualbox-iso.alpine",
  ]

  provisioner "shell" {
    scripts = [
        "scripts/prepare.sh"
    ]
  }

  provisioner "mondoo" {
    on_failure =  "continue"

    # enable sudo configuration
    # sudo {
    #   active = true
    # }

    # use incognito to keep the report locally
    # incognito = true
  }

  post-processor "vagrant" {
    vagrantfile_template = "Vagrantfile"
    output        = "output.box"
  }
}