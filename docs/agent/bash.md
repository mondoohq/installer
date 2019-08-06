# Installing Mondoo Agent via Bash Script

<img src="../assets/videos/mondoo-install.gif">

This one-line script installation is installing and configuring Mondoo agent for Servers. During its execution it does the following:

* detect the operating system
* installs Mondoo package
* register agent if `MONDOO_REGISTRATION_TOKEN` is provided
* configure the service if the agent was registered

> Note: we encourage you to familiarize yourself with our script before you use it.
> The source is available in our public [github repository](https://github.com/mondoolabs/mondoo/blob/master/install.sh)

Instead of downloading the latest binary, it configures the gpg signed Mondoo package repository. This allows an easy install/update/remove of the Mondoo agent.

> Note: If you are  looking for a binary download (eg. we recommend this for workstations setup), 
> please follow our [binary install instructions](./binaries)

## Examples:

**Install package and register agent**

After the installation of the package, the installation script looks for the `MONDOO_REGISTRATION_TOKEN` environment variable. If set, it starts a registration process.

```
export MONDOO_REGISTRATION_TOKEN='ey...ax'
curl -sSL https://mondoo.io/install.sh | bash
```

**Install package and register manually**

If the environment variable is not set you can easily run the regisstration as a second step:

```
curl -sSL https://mondoo.io/install.sh | bash
MONDOO_REGISTRATION_TOKEN='ey...ax'
mondoo register --config /etc/opt/mondoo/mondoo.yml --token 'MONDOO_REGISTRATION_TOKEN'
```

**systemd configuration**

The mondoo package ships with a systemd configuration. By default, the mondoo service is not enabled. You can enable and start the service via:

```
$ systemctl enable mondoo.timer
$ systemctl start mondoo.timer
$ systemctl daemon-reload
```