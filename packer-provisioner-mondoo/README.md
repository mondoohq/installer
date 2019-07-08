# Mondoo Packer Provisioner

This provisioner runs Mondoo vulnerability scan as part of the packer build. This provisioner enables you to easily plug Mondoo into your existing packer pipeline. The advantage of using Mondoo as part of the pipleine is that no tool needs to be installed on the target. Therefore the images stays clean.

Further documentation is available at [Mondoo Packer Integration Docs](https://mondoo.io/docs/apps/packer). An AMI build example is located in the [examples directory](../examples/packer-ami) 

## Preparation

1. Install mondoo agent on your workstation
2. Download and install the packer plugin and place it into `~/.packer.d/plugins`

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
    "type": "mondoo"
  }],
```

## Kudos

The tests are derived from [maier/packer-templates](https://github.com/maier/packer-templates).