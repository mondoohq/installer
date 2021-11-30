# Apply Ansible to all EC2 machines and Assess the security state

This example runs [DevSec's Ansible server hardening roles](https://github.com/dev-sec/ansible-collection-hardening) for EC2 instances and assesses the state via [Mondoo](https://mondoo.io)

## Precondition

 * [Install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
 * [Mondoo CLI installed on workstation](https://docs.mondoo.io/operating_systems/installation/installation)
 * Launched Linux Instance(s) that are reachable via SSH

## Run Playbook

We are going to secure the Linux Ec2 Instances with the [DevSec's Ansible roles](https://github.com/dev-sec/ansible-collection-hardening)

```bash
ansible-galaxy install dev-sec.os-hardening
ansible-galaxy install dev-sec.ssh-hardening
```

Adapt the hosts.ini:

```ini
[linux_clients]
54.175.34.37 ansible_user=ec2-user
```

Now, run ansible across the fleet via `ansible-playbook -i hosts.ini playbook.yml`
 
```bash
PLAY [all] *******************************************************************************************************************************************************************************************************************************************************************

TASK [Gathering Facts] *******************************************************************************************************************************************************************************************************************************************************
[WARNING]: Platform linux on host 54.175.34.37 is using the discovered Python interpreter at /usr/bin/python, but future installation of another Python interpreter could change the meaning of that path. See https://docs.ansible.com/ansible-
core/2.11/reference_appendices/interpreter_discovery.html for more information.
ok: [54.175.34.37]

TASK [dev-sec.os-hardening : Set OS family dependent variables] **************************************************************************************************************************************************************************************************************
ok: [54.175.34.37]

TASK [dev-sec.os-hardening : Set OS dependent variables] *********************************************************************************************************************************************************************************************************************
ok: [54.175.34.37] => (item=/Users/chris/.ansible/roles/dev-sec.os-hardening/vars/Amazon.yml)

TASK [dev-sec.os-hardening : install auditd package | package-08] ************************************************************************************************************************************************************************************************************
ok: [54.175.34.37]

TASK [dev-sec.os-hardening : configure auditd | package-08] ******************************************************************************************************************************************************************************************************************
changed: [54.175.34.37]

TASK [dev-sec.os-hardening : create limits.d-directory if it does not exist | sysctl-31a, sysctl-31b] ************************************************************************************************************************************************************************
ok: [54.175.34.37]

...

TASK [dev-sec.ssh-hardening : disable SSH server CRYPTO_POLICY] **************************************************************************************************************************************************************************************************************
skipping: [54.175.34.37]

RUNNING HANDLER [dev-sec.ssh-hardening : restart sshd] ***********************************************************************************************************************************************************************************************************************
changed: [54.175.34.37]

PLAY RECAP *******************************************************************************************************************************************************************************************************************************************************************
54.175.34.37               : ok=68   changed=23   unreachable=0    failed=0    skipped=33   rescued=0    ignored=0  

```

## Assess Security via Mondoo

Mondoo leverages the ansible inventory. It can also be executed via ansible, see [Mondoo Docs](https://docs.mondoo.io/operating_systems/automation/ansible/) for further options.

```bash
$ ansible-inventory -i hosts.ini --list | mondoo scan --incognito ../shared/policies/linux-baseline.yaml
→ Mondoo 5.15.0 (Space: "//captain.api.mondoo.app/spaces/musing-saha-952142", Service Account: "1zDY7cJ7bA84JxxNBWDxBdui2xE", Managed Client: "1zDY7auR20SgrFfiGUT5qZWx6mE")
→ loaded configuration from /Users/chris/.config/mondoo/mondoo.yml using source default
                        .-.            
                        : :            
,-.,-.,-. .--. ,-.,-. .-' : .--.  .--. ™
: ,. ,. :' .; :: ,. :' .; :' .; :' .; :
:_;:_;:_;`.__.':_;:_;`.__.'`.__.'`.__.'

→ discover related assets for 1 asset(s)
→ use scp instead of sftp
→ resolved assets resolved-assets=1
→ execute policies
→ enabled incognito mode
→ establish connection to asset ip-172-31-84-13.ec2.internal
→ run policies for asset asset=//assets.api.mondoo.app/spaces/musing-saha-952142/assets/21Z96WwIkZkkLSV6INzTDMaHwuX

███████████████████████████████████████████████████████████████████████████ 100% ip-172-31-84-13.ec2.internal

→ use scp instead of sftp
→ send all results asset=//assets.api.mondoo.app/spaces/musing-saha-952142/assets/21Z96WwIkZkkLSV6INzTDMaHwuX
→ generate report asset=//assets.api.mondoo.app/spaces/musing-saha-952142/assets/21Z96WwIkZkkLSV6INzTDMaHwuX
→ scan complete asset=//assets.api.mondoo.app/spaces/musing-saha-952142/assets/21Z96WwIkZkkLSV6INzTDMaHwuX

ip-172-31-84-13.ec2.internal
============================

┌▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄┐
│    _                       │
│   /_\    Excellent 92/100  │
│  / _ \   100% complete     │
│ /_/ \_\  ▄▄ ▄▄ ▄▄ ▄▄       │
└────────────────────────────┘

...
```