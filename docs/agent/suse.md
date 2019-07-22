# Installing Mondoo Agent on Suse & openSUSE

At first, add mondoo's signed apt repository:

```
curl --silent --location https://releases.mondoo.io/rpm/mondoo.repo | tee /etc/zypp/repos.d/mondoo.repo
```

Then, install the mondoo agent:

```bash
zypper -n --gpg-auto-import-keys install mondoo
```

Register the agent with your mondoo cloud organization

```bash
mondoo register --config /etc/opt/mondoo/mondoo.yml --token 'TOKEN'
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
s
## Upgrade

The mondoo agent can be easily updated via:

```bash
zypper update mondoo
```