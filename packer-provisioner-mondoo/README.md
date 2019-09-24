# Mondoo Packer Provisioner

This provisioner runs Mondoo vulnerability scan as part of the packer build. It enables you to easily plug Mondoo into your existing Packer build pipeline. 

The provisioner leverages Packer's built-in ssh proxy, to easily assess the vulnerabilities without the need to install anything on the target. Everybody loves clean images, right?

Further documentation is available at [Mondoo Packer Integration Docs](https://mondoo.io/docs/apps/packer). An AMI build example is located in the [examples directory](../examples/packer-aws) 

## Preparation

1. Install Mondoo agent on your workstation
2. Download the Mondoo Packer provisioner and place it into a [Packer plugin directory](https://www.packer.io/docs/extending/plugins.html#installing-plugins) like `~/.packer.d/plugins` or `%APPDATA%/packer.d/plugins`

## Usage

The simplest setup is to add `mondoo` to your provisioners list:

```
  "provisioners": [{
    "type": "shell",
    "scripts": [
      "scripts/install.sh",
    ],
    "override": {
      "virtualbox-iso": {
        "execute_command": "/bin/sh '{{.Path}}'"
      }
    }
  }, {
    "type": "mondoo",
    "on_failure": "continue",
  }],
```

The example above used the option `on_failure`, which allows you to pass a packer build, even if vulnerabilities have been found.

If you're using WinRM as a connection type, you need to set the user and password manually (see [hashicorp/packer#7079](https://github.com/hashicorp/packer/issues/7079)):

```
    {
      "type": "mondoo",
      "winrm_user": "vagrant"
      "winrm_password": "vagrant",
    }
```

## Compiling the Packer plugin from source

If you wish to compile from source, you need to have [Go](https://golang.org/) installed and configured.

1. Clone the mondoo repository from GitHub into your $GOPATH:

```
$ mkdir -p $(go env GOPATH)/src/github.com/mondoolabs && cd $_
$ git clone https://github.com/mondoolabs/mondoo.git
$ cd mondoo/packer-provisioner-mondoo
```

2. Build the plugin for your current system and place the binary in the packer plugin directory

```
make install
```

## Kudos

The tests are derived from [maier/packer-templates](https://github.com/maier/packer-templates).