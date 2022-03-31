# Packer HCL example

This example demonstrates how to use packer in combination with Mondoo.

**Requirements**

To run the example, we need Vagrant and Virtual Box installed on your workstation. In addition, the Mondoo Client is required on your workstation in combination with the Packer integration.

- [Virtual Box](https://www.virtualbox.org/wiki/Downloads)
- [Vagrant 1.8.0](https://www.vagrantup.com/downloads)
- [Mondoo Packer Provisioner](https://mondoo.com/docs/supplychain/packer/#install-mondoo-packer-provisioner)
- [Mondoo](https://mondoo.com/docs/operating_systems/installation/)

**Build the image**

Once the workstation is prepared, you can simply build the Alpine image via:

```
packer build .
```
