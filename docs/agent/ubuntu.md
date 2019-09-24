# Installing Mondoo Agent on Debian & Ubuntu

At first, add mondoo's signed apt repository:

```bash
curl -sS https://releases.mondoo.io/debian/pubkey.gpg | apt-key add -
echo "deb https://releases.mondoo.io/debian/ stable main" | tee /etc/apt/sources.list.d/mondoo.list
```

Then, install the mondoo agent:

```bash
apt-get update && apt-get install mondoo
```

Register the agent with your mondoo cloud organization

```bash
mkdir -p /etc/opt/mondoo/
mondoo register --config /etc/opt/mondoo/mondoo.yml --token 'TOKEN'
```

Set collector mode for systemd

```
echo "collector: http" | $sudo_cmd tee -a /etc/opt/mondoo/mondoo.yml
```

Start the agent:

```bash
systemctl enable mondoo.timer && systemctl start mondoo.timer
systemctl daemon-reload
```

The agent status can be displayed via:

```bash
systemctl list-timers
systemctl status mondoo.timer
```

## Upgrade

The mondoo agent can be easily updated via:

```bash
apt-get update && apt-get install -y mondoo
```

## FAQ

**I experience an apt warning about missing i386 support**

```bash
$   apt-get update
Hit:1 http://archive.ubuntu.com/ubuntu xenial InRelease
Hit:2 http://archive.ubuntu.com/ubuntu xenial-updates InRelease
Hit:3 http://archive.ubuntu.com/ubuntu xenial-backports InRelease                
Hit:4 http://security.ubuntu.com/ubuntu xenial-security InRelease       
Hit:5 https://releases.mondoo.io/debian stable InRelease
Reading package lists... Done
N: Skipping acquire of configured file 'main/binary-i386/Packages' as repository 'https://releases.mondoo.io/debian stable InRelease' doesn't support architecture 'i386'
```

Mondoo does not release 32-bit bit packages for Linux. This warning is happening on Debian/Ubuntu multi-arch environments with mixed packages architectures. You can solve that issue by updating `/etc/apt/sources.list.d/mondoo.list` to 

```
deb [arch=amd64] https://releases.mondoo.io/debian/ stable main
```

**During configuration of the apt-repo I see the error `The following packages have unmet dependencies`**

Since the Mondoo package has no direct dependencies, this is likely an issue with the current setup. While we recommend fixing the root issue, you can download the deb package manually from our releases page.

```
# install package
wget https://releases.mondoo.io/mondoo/0.26.0/mondoo_0.26.0_linux_amd64.deb
dpkg -i mondoo_0.26.0_linux_amd64.deb
```



