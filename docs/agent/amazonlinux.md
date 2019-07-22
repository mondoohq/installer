# Installing Mondoo Agent on Amazon Linux

At first, add mondoo's signed apt repository:

```
curl --silent --location https://releases.mondoo.io/rpm/mondoo.repo | tee /etc/yum.repos.d/mondoo.repo
```

Then, install the mondoo agent:

```bash
yum install -y mondoo
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
yum clean expire-cache && yum update mondoo
```