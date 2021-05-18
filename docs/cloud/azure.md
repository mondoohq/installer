# Azure Integration

Mondoo offers a wide range of choices to collect risk information about workload running in your Azure account:

**Gather vulnerability information during build-time**

- [Risk assessment in Azure DevOps](../cicd/azure-devops.md#azure-devops)
- [Risk assessment for Azure Container Registry](../registry/azure_acr.md#azure-container-registry)
- [Build AMIs with Packer](../devops/packer.md)
- [Test Docker Images in Azure DevOps](../cicd/azure-devops.md)

**Gather vulnerability information during run-time**

- [Scan Azure compute instances from your workstation](#scan-from-workstation)
- [Install mondoo agent via CloudInit](../installation/cloudinit.md)
- [Terraform deployment](../devops/terraform.md)
- [Verify instances managed by Chef/AWS OpsWorks](../installation/chef.md)
- [Verify instances managed by Ansible](../installation/ansible.md)

## Scan from Workstation

The Mondoo CLI leverages the configuration from [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest). Install the `az` command and login to Azure:

```bash
az login
```

You need your subscription id and the resource group. Run `az account list` and ` az vm list` to determine those values:

```bash
$ az account list
Name                  CloudName    SubscriptionId                        State    IsDefault
--------------------  -----------  ------------------------------------  -------  -----------
Azure subscription 1  AzureCloud   10192451-09aa-4782-1016-1cdfede1026b  Enabled  True
```

```bash
$ az vm list
Name     ResourceGroup    Location    Zones
-------  ---------------  ----------  -------
centos   DEMO             westus
ubuntu   DEMO             westus
win2019  DEMO             westus
```

Provided with those values, you can trigger a scan via `mondoo`:

```bash
$ mondoo scan -t az://subscriptions/subscriptionid/resourceGroups/groupname
```

![Mondoo Azure instances scan from CLI](../static/videos/azure-compute-scan.gif)

> Note: mondoo uses `~/.ssh/config` to determine the users for each detected public IP

Instead of using the same ssh username for all instances, you can also configure the SSH config and configure the username for each instance with their username:

```bash
Host 123.123.123.123
  User chris

Host yourdomain.com
  IdentityFile /your/path/keyname
````

If you require a specific list of instances with more detailed configuration, consider the use of an [Ansible inventory](../devops/ansible.md)

> Note: SSH config does not allow to configure a host with a password, therefore Windows machines are only scanned as part of the cloud scan if they use public key authentication. You can always scan those instances individually via `mondoo scan -t ssh://username@123.123.123.123 --password 'mypassword'