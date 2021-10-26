# Mondoo Ansible Role

This role installs the Mondoo Client on Linux and Windows servers. 

It does:

 * Installs the signed `mondoo` package
 * Registers Mondoo Client with Mondoo Platform
 * Enables the systemd service

It supports:

 * RedHat & CentOS
 * Ubuntu
 * Amazon Linux
 * Debian
 * Suse & openSUSE
 * Windows 10, 2016, 2019, 2022

The role is published at Ansible Galaxy: [Mondoo role](https://galaxy.ansible.com/mondoolabs/mondoo).

## Requirements

 * Ansible > 2.5

## Role Variables

| Name           | Default Value | Description                        |
| -------------- | ------------- | -----------------------------------|
| `registration_token_retrieval` | `manual` | `manual` requires to set ``registration_token`. `cli` call a local Mondoo Client to automatically retrieve a new registration token |
| `registration_token`|  n/a | manually set the Mondoo Registration Token that is used to register new Mondoo Clients
| `force_registration`|  true | forces re-registration for each run

## Dependencies

This role has no role dependencies

## Example: Apply Ansible Playbook to Amazon EC2 Linux instance

This playbook demonstrates how to use the Mondoo role to install the Mondoo Client on many instances:

1. Create a new `hosts` inventory. Add your host to the group.

```ini
[mondoo_linux]
54.172.7.243  ansible_user=ec2-user
```

2. Create a `playbook.yml` and change the `registration_token`:

```yaml
---
- hosts: mondoo_linux
  become: yes
  roles:
    - role: mondoolabs.mondoo
      vars:
        registration_token: "changeme"
```

In addition we support the following variables:

| variable                      | description                                                               |
|-------------------------------|---------------------------------------------------------------------------|
| `force_registration: true`    | set to true if you want to re-register existing Mondoo Clients            |
| `ensure_managed_client: true` | ensures the configured clients are configured as managed Client in Mondoo |


```yaml
---
- hosts: mondoo_linux
  become: yes
  roles:
    - role: mondoolabs.mondoo
      vars:
        registration_token: "changeme"
        force_registration: true
        ensure_managed_client: true
```

3. Run the playbook with the local hosts file

```bash
# download mondoo role
ansible-galaxy install mondoolabs.mondoo
# apply the playbook
ansible-playbook -i hosts playbook.yml
```

4. All instances [reported their vulnerability status](https://mondoo.app/)

## Apply Ansible Playbook to Amazon EC2 Windows instance

If you are using Windows, please read the ansible documentation about [WinRM setup](https://docs.ansible.com/ansible/latest/user_guide/windows_setup.html#id4) or the [SSH setup](https://docs.ansible.com/ansible/latest/user_guide/windows_setup.html#windows-ssh-setup).

1. Create a new `hosts` inventory. Add your host to the group.

```ini
[mondoo_windows]
123.123.247.76 ansible_port=5986 ansible_connection=winrm ansible_user=Administrator ansible_password=changeme ansible_shell_type=powershell ansible_winrm_server_cert_validation=ignore
```

or if you are going to use ssh:
```ini
3.235.247.76 ansible_port=22 ansible_connection=ssh ansible_user=admin ansible_shell_type=cmd
```

2. Create a `playbook.yml` and change the `registration_token`:

If you are targeting windows, the configuration is slightly different since `become` needs to be deactivated:

```yaml
- hosts: mondoo_windows
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

**Error `ansible.legacy.setup` on Windows with SSH**

```
fatal: [123.123.247.76]: FAILED! => {"ansible_facts": {}, "changed": false, "failed_modules": {"ansible.legacy.setup": {"failed": true, "module_stderr": "Parameter format not correct - ;\r\n", "module_stdout": "", "msg": "MODULE FAILURE\nSee stdout/stderr for the exact error", "rc": 1}}, "msg": "The following modules failed to execute: ansible.legacy.setup\n"}
```

Ansible in combination with Win32-OpenSSH versions older than v7.9.0.0p1-Beta do not work when `powershell` is the shell type, set the shell type to `cmd`
