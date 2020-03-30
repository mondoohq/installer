# Ansible and Mondoo

Mondoo is built to make vulnerability assessment for your infrastructure easy. If you are already using Ansible to manage parts of your infrastructure, you can re-use the setup for Mondoo. This is possible because Mondoo understands the [Ansible's inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) format.

![Mondoo using Ansible inventory](../../assets/ansible-inventory.png)

## Overview about Ansible inventory

Ansible inventory is a list of hosts that is mostly stored in the two common formats `ini` and `yaml`. The following examples illustrate their structure. The ini format allows grouping and easy configuration of additional properties.

```ini
# hosts.ini
[workers]
34.243.41.251 ansible_user=ec2-user
instance1 ansible_host=18.203.250.158 ansible_user=ubuntu
```

The same structure in yaml:

```yml
# hosts.yml
all:
 children:
 workers:
 hosts:
 instance1:
 ansible_host: 18.203.250.158
 ansible_user: ubuntu
 34.243.41.251:
 ansible_user: ec2-user
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

The inventory can also be used with your Ansible playbook via `ansible-playbook myplaybook.yml -i hosts.ini`

## Use Ansible inventory with Mondoo

The use of the inventory is as easy as:

```bash
ansible-inventory -i hosts.ini --list | mondoo scan --ansible-inventory
```

The resolved inventory can also be stored and read directly:

```bash
ansible-inventory -i hosts.ini --list > hosts.json
mondoo scan --inventory osts.json --ansible-inventory
```

We rely on [ansible-inventory](https://docs.ansible.com/ansible/latest/cli/ansible-inventory.html) to be able to support various inventory formats and to be able to re-use [dynamic inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html) too.

Note: At this point, we do not support group [patterns](https://docs.ansible.com/ansible/latest/user_guide/intro_patterns.html). If you need additional support, please do not hesitate to contact us.