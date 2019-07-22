# Installation via Ansible

We publish an official [Mondoo role](https://galaxy.ansible.com/mondoolabs/mondoo).

**Example: Apply Ansible Playbook to Amazon EC2 instance**

This playbook demonstrates how to use the Mondoo role to install the agent on many instances: 

1. Create a new `hosts` inventory. Add your host to the group.

```ini
[mondoo-agents]
54.172.7.243  ansible_user=ec2-user
```

2. Create a `playbook.yml` and change the `mondoo_registration_token`:

```yaml
---
- hosts: mondoo-agents
  become: yes
  roles:
    - role: mondoolabs.mondoo
      vars:
        mondoo_registration_token: "changeme"
```

3. Run the playbook with the local hosts file

```bash
# download mondoo role
ansible-galaxy install mondoolabs.mondoo
# apply the playbook
ansible-playbook -i hosts playbook.yml
```

4. All instances [reported their vulnerability status](https://mondoo.app/)