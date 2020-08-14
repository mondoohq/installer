# Server Security

## SSH Targets

The mondoo agent has full ssh support and picks up configuration from ssh config and credentials from the ssh-agent automatically. Therefore, you do not need to pass in secrets as clear text which prevents storing credentials in shell history. Plus, it is way more convenient :-)

```bash
# scan ssh target with default port 22
$ mondoo scan -t ssh://ec2-user@52.51.185.215

# scan ssh target on a custom port
$ mondoo scan -t ssh://ec2-user@52.51.185.215:2222
```

![Mondoo SSH scan from CLI](../static/videos/ssh-scan.gif)

Definitions from ` ~/.ssh/config` are used by the mondoo agent. The following defines the host `shorty` for ssh:

```
Host shorty
  HostName 54.205.49.51
  User ec2-user
```

You can use `shorty` as host identifier with `monndoo`  then:

```
# use hosts defined in ~/.ssh/config
$ mondoo scan -t ssh://shorty
```

**Identity Authentication**

You can always pass unencrypted keys via the `-i` option:

```
mondoo scan -t ssh://vagrant@192.168.100.70 -i /path/to/private_key
```

> Note: We recommend using ssh-agent for identity keys since `mondoo` cannot decrypt keys by itself

**Agent Authentication**

Since `mondoo` integrates with `ssh-agent`, you do not need to provide the identity key. This is also the recommended solution for encrypted identity keys:

```
ssh-add /path/to/private_key
mondoo scan -t ssh://vagrant@192.168.100.70
```

**Password Authentication**

> NOTE: We do not recommend this method for any production workloads, since it may expose your password as cleartext in logs

```
mondoo scan -t ssh://vagrant:vagrant@192.168.100.70
```

## Ansible Inventory

Ansible inventory is a list of hosts that is mostly stored in the two common formats `ini` and `yaml`.

![Mondoo using Ansible inventory](../static/ansible-inventory.png)

The ini format allows grouping and easy configuration of additional properties:

```ini
# hosts.ini
[workers]
34.243.41.251 ansible_user=ec2-user
instance1 ansible_host=18.203.250.158 ansible_user=ubuntu
```

Equipped with this inventory, you can ping all the hosts with ansible:

```bash
ansible all -i hosts.ini -m ping
34.243.41.251 | SUCCESS => {
 "changed": false,
 "ping": "pong"
}
instance1 | SUCCESS => {
 "changed": false,
 "ping": "pong"
}
```

Then use `ansible-inventory` with Mondoo:

```bash
ansible-inventory -i hosts.ini --list | mondoo scan --ansible-inventory
```

Further information is available at [Integration/DevOps/Ansible](../integration/devops/ansible#ansible-and-mondoo)

## Local System

Linux bases systems can also be scanned locally:

```
$ mondoo scan
```