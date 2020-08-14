# Installing Mondoo Agent on RedHat & CentOS

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


## FAQ

**I experience an curl SSL error during installation**

Mondoo is using newer TLS 1.2 and above. Therefore, you may see errors like NSS error 12190 on older systems that do not support newer TLS versions. Please make sure you have the latest `curl` and `nss` version installed via:

```
yum update curl nss -y
```

Alternatively, you can try to specify the tls protocol (if available in your curl build):

```
curl --tlsv1.2 -sSL https://mondoo.io/install.sh | bash
```