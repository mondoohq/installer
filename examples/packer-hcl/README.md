# Packer HCL example

This example demonstrates how to use packer in combination with Mondoo.

**Requirements**

- [Virtual Box](https://www.virtualbox.org/wiki/Downloads)
- [Vagrant 1.8.0](https://www.vagrantup.com/downloads)
- [Mondoo Packer Provisioner](https://mondoo.com/docs/supplychain/packer/#install-mondoo-packer-provisioner)
- [Mondoo](https://mondoo.com/docs/operating_systems/installation/)

To run the example, ensure Vagrant and VirtualBox are installed on your workstation. Next, install the Mondoo Client and Mondoo Packer Provisioner.

To run the example, we need Vagrant and Virtual Box installed on your workstation. In addition, the [Mondoo Client](https://mondoo.com/docs/tutorials/mondoo/account-setup/#step-2-install-and-register-mondoo-client-on-a-workstation) is required on your workstation in combination with the [Mondoo Packer Provisioner](https://mondoo.com/docs/supplychain/packer/#install-mondoo-packer-provisioner).

**Build the image**

Once the workstation is prepared, you can simply build the Alpine image via:

```
packer build .
```
