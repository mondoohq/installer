# Mondoo Ansible Role

This role installs the Mondoo agent on Linux servers. 

It does:

 * Installs the signed `mondoo` package
 * Registers the agent with Mondoo Cloud
 * Configures the agent for collector mode
 * Enables the systemd service

It supports:

 * RedHat & CentOS
 * Ubuntu
 * Amazon Linux
 * Debian
 * Suse & openSUSE

## Requirements

 * Ansible > 2.5

## Role Variables

| Name           | Default Value | Description                        |
| -------------- | ------------- | -----------------------------------|
| `mondoo_registration_token`| `changeme` | Mondoo Registration Token that is used to retrieve agent credentials

## Dependencies

This role has no role dependencies

## Example Playbook

This is an example of how to use the mondoo role with the `mondoo_registration_token` variable in an ansible playbook:

```
    - hosts: servers
      roles:
         - { role: mondoo, mondoo_registration_token: "changeme" }
```

## Testing

For testing, this role uses molecule. You can install the dependencies via:

```bash
pip install molecule
pip install python-vagrant
pip install 'molecule[vagrant]'
```

The `molecule` cli covers the test lifecycle: 

```bash
# spin up the vms
molecule create
# converge the machines with ansible
molecule converge
# run molecule tests
molecule test
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