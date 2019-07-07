# Ansible Playbook Example

This playbook allows you to install the Mondoo agent via Ansible.

1. Adapt the hosts inventory. Add your host to the group.

```
[mondoo-agents]
54.172.7.243  ansible_user=ec2-user
```

2. Change the `mondoo_registration_token` in `playbook.yml`:

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