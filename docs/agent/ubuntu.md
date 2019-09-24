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


## Upgrade

The mondoo agent can be easily updated via:

```bash
apt-get update && apt-get install -y mondoo
```