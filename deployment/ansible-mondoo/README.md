# Mondoo Ansible Role

This role installs the Mondoo CLI on Linux servers. 

It does:

 * Installs the signed `mondoo` package
 * Registers the agent with Mondoo Cloud
 * Enables the systemd service

It supports:

 * RedHat & CentOS
 * Ubuntu
 * Amazon Linux
 * Debian
 * Suse & openSUSE

The role is published at Ansible Galaxy: [Mondoo role](https://galaxy.ansible.com/mondoolabs/mondoo).

## Requirements

 * Ansible > 2.5

## Role Variables

| Name           | Default Value | Description                        |
| -------------- | ------------- | -----------------------------------|
| `registration_token_retrieval` | `manual` | `manual` requires to set ``registration_token`. `cli` call a local mondoo agent to automatically retrieve a new registration token |
| `registration_token`|  n/a | manually set the Mondoo Registration Token that is used to register new agents

## Dependencies

This role has no role dependencies

## Example: Apply Ansible Playbook to Amazon EC2 instance

This playbook demonstrates how to use the Mondoo role to install the agent on many instances:

1. Create a new `hosts` inventory. Add your host to the group.

```ini
[mondoo-agents]
54.172.7.243  ansible_user=ec2-user
```

2. Create a `playbook.yml` and change the `registration_token`:

```yaml
---
- hosts: mondoo_agents
  become: yes
  roles:
    - role: mondoolabs.mondoo
      vars:
        registration_token: "changeme"
```

If you do not want to re-register existing agents, then set `force_registration: false` in vars:

```
---
- hosts: mondoo_agents
  become: yes
  roles:
    - role: mondoolabs.mondoo
      vars:
        registration_token: "changeme"
        force_registration: false
```

3. Run the playbook with the local hosts file

```bash
# download mondoo role
ansible-galaxy install mondoolabs.mondoo
# apply the playbook
ansible-playbook -i hosts playbook.yml
```

4. All instances [reported their vulnerability status](https://mondoo.app/)


## Testing

For testing, this role uses molecule. You can install the dependencies via:

```bash
pip install molecule
pip install python-vagrant
pip install molecule-vagrant
```

The `molecule` cli covers the test lifecycle: 

```bash
# spin up the vms
molecule create
# converge the machines with ansible
molecule converge
# run molecule tests
molecule verify
# for degugging, you can login to individual hosts
molecule login --host ubuntu
# destroy the test setup
molecule destroy
```

## Author

Mondoo, Inc


## FAQ

**Error 'module' object has no attribute 'HTTPSHandler'**

```
TASK [mondoo : Download Mondoo RPM key] ********************************
    fatal: [suse]: FAILED! => {"changed": false, "module_stderr": "Shared connection to 127.0.0.1 closed.\r\n", "module_stdout": "Traceback (most recent call last):\r\n  File \"/home/vagrant/.ansible/tmp/ansible-tmp-1562450830.52-85510064926638/AnsiballZ_get_url.py\", line 113, in <module>\r\n    _ansiballz_main()\r\n  File \"/home/vagrant/.ansible/tmp/ansible-tmp-1562450830.52-85510064926638/AnsiballZ_get_url.py\", line 105, in _ansiballz_main\r\n    invoke_module(zipped_mod, temp_path, ANSIBALLZ_PARAMS)\r\n  File \"/home/vagrant/.ansible/tmp/ansible-tmp-1562450830.52-85510064926638/AnsiballZ_get_url.py\", line 48, in invoke_module\r\n    imp.load_module('__main__', mod, module, MOD_DESC)\r\n  File \"/tmp/ansible_get_url_payload_103dVU/__main__.py\", line 308, in <module>\r\n  File \"/tmp/ansible_get_url_payload_103dVU/ansible_get_url_payload.zip/ansible/module_utils/urls.py\", line 346, in <module>\r\nAttributeError: 'module' object has no attribute 'HTTPSHandler'\r\n", "msg": "MODULE FAILURE\nSee stdout/stderr for the exact error", "rc": 1}
```

```
sudo zypper install python python2-urllib3 python3 python3-urllib3
```