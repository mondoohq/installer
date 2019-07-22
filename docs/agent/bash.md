# Installing Mondoo Agent via Bash Script

This one-line script installation is installing and configuring Mondoo agent for Servers. During its execution it does the following:

* detect the operating system
* installs Mondoo package
* register agent if `MONDOO_REGISTRATION_TOKEN` is provided
* configure the service if the agent was registered

> Note: we encourage you to familiarize yourself with our script before you use it.
> The source is available in our public [github repository](https://github.com/mondoolabs/mondoo/blob/master/install.sh)

Instead of downloading the latest binary, it configures the gpg signed Mondoo package repository. This allows an easy install/update/remove of the Mondoo agent.

> Note: If you are  looking for a binary download (eg. for workstations setup), 
> please follow our [binary install instructions](./binaries)

## Examples:

**Install package and register agent**

```
MONDOO_REGISTRATION_TOKEN='ey...ax'
curl -sSL https://mondoo.io/install.sh | bash
```

**Install package and register manually**

```
curl -sSL https://mondoo.io/install.sh | bash
mondoo register --config /etc/opt/mondoo/mondoo.yml --token 'MONDOO_REGISTRATION_TOKEN'
```
