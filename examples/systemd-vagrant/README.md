# Mondoo systemd demo with Vagrant

## Preparation:

1. Login to https://mondoo.app/
2. Create or select a mondoo space and select `Agents` on the sidebar
3. Download agent credentials and copy the content into the `mondoo.yml`

## Start VM

**Centos**
```
vagrant up centos
```

**Debian**
```
vagrant up debian
```

**Ubuntu**
```
vagrant up ubuntu
```

## Verify setup

```
vagrant ssh {machine}
$ sudo -i
```

List mondoo service status
```
$ systemctl status mondoo
● mondoo.service - mondoo vuln
   Loaded: loaded (/etc/systemd/system/mondoo.service; static; vendor preset: disabled)
   Active: inactive (dead)

Jun 14 12:35:17 localhost.localdomain mondoo[3668]: Start vulnerability scan:
Jun 14 12:35:18 localhost.localdomain mondoo[3668]: [59B blob data]
Jun 14 12:35:18 localhost.localdomain mondoo[3668]: [43B blob data]
Jun 14 12:35:18 localhost.localdomain mondoo[3668]: [32B blob data]
Jun 14 12:35:18 localhost.localdomain mondoo[3668]: [33B blob data]
Jun 14 12:35:19 localhost.localdomain mondoo[3668]: [63B blob data]
Jun 14 12:35:19 localhost.localdomain mondoo[3668]: [27B blob data]
Jun 14 12:35:19 localhost.localdomain mondoo[3668]: →  enabled collector
Jun 14 12:35:24 localhost.localdomain mondoo[3668]: ✔  sent packages successfully
Jun 14 12:35:24 localhost.localdomain systemd[1]: Started mondoo vuln.
```

To see the full log, run:

```
$ journalctl -u mondoo.service
-- Logs begin at Fri 2019-06-14 12:24:28 UTC, end at Fri 2019-06-14 12:35:24 UTC. --
Jun 14 12:35:17 localhost.localdomain systemd[1]: Starting mondoo vuln...
Jun 14 12:35:17 localhost.localdomain mondoo[3668]: Start vulnerability scan:
Jun 14 12:35:18 localhost.localdomain mondoo[3668]: [59B blob data]
Jun 14 12:35:18 localhost.localdomain mondoo[3668]: [43B blob data]
Jun 14 12:35:18 localhost.localdomain mondoo[3668]: [32B blob data]
Jun 14 12:35:18 localhost.localdomain mondoo[3668]: [33B blob data]
Jun 14 12:35:19 localhost.localdomain mondoo[3668]: [63B blob data]
Jun 14 12:35:19 localhost.localdomain mondoo[3668]: [27B blob data]
Jun 14 12:35:19 localhost.localdomain mondoo[3668]: <E2><86><92>  enabled collector
Jun 14 12:35:24 localhost.localdomain mondoo[3668]: <E2><9C><94>  sent packages successfully
```

