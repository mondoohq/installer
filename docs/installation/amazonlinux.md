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
mondoo register --config /etc/opt/mondoo/mondoo.yml --token 'PASTE_MONDOO_REGISTRATION_TOKEN'
```

Start the agent:

```bash
systemctl enable mondoo.service && systemctl start mondoo.service
systemctl daemon-reload
```

The agent status can be displayed via:

```bash
systemctl status mondoo.service
```


## Upgrade

The mondoo agent can be easily updated via:

```bash
yum clean expire-cache && yum update mondoo
```