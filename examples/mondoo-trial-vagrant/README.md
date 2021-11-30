# Mondoo Client demo with Vagrant

## Preparation:

1. Login to https://mondoo.app/
2. Create or select a Mondoo space and select `Managed Client` on the sidebar
3. Create a new registration token and set it as an environment variable

## Start VM


```
# set registration token
export MONDOO_REGISTRATION_TOKEN='ey..k6C1TYwOk0J'
# on mac you can use pbpaste to read the token from clipboard
export MONDOO_REGISTRATION_TOKEN=$(pbpaste)

# ensure the registration token is set
echo $MONDOO_REGISTRATION_TOKEN

# spin up centos
vagrant up centos

# spin up Debian
vagrant up debian

# spin up Ubuntu
vagrant up ubuntu
```

## Verify setup

```
vagrant ssh {machine}
$ sudo -i
```

List Mondoo service status
```
$ systemctl status mondoo
● mondoo.service - Mondoo Service
   Loaded: loaded (/etc/systemd/system/mondoo.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2019-11-22 14:53:19 UTC; 39s ago
 Main PID: 3465 (mondoo)
   CGroup: /system.slice/mondoo.service
           └─3465 /usr/bin/mondoo serve --config /etc/opt/mondoo/mondoo.yml

Nov 22 14:53:19 localhost.localdomain mondoo[3465]: →  start mondoo background service
Nov 22 14:53:19 localhost.localdomain mondoo[3465]: →  scan interval is 60 minute(s)
Nov 22 14:53:20 localhost.localdomain mondoo[3465]: →  start the vulnerability scan
Nov 22 14:53:20 localhost.localdomain mondoo[3465]: →  enabled async collector mode
Nov 22 14:53:20 localhost.localdomain mondoo[3465]: [81B blob data]
Nov 22 14:53:20 localhost.localdomain mondoo[3465]: [59B blob data]
Nov 22 14:53:21 localhost.localdomain mondoo[3465]: [93B blob data]
Nov 22 14:53:21 localhost.localdomain mondoo[3465]: [492B blob data]
Nov 22 14:53:21 localhost.localdomain mondoo[3465]: [49B blob data]
Nov 22 14:53:28 localhost.localdomain mondoo[3465]: ✔  sent packages successfully
```

To see the full log, run:

```
$ journalctl -u mondoo.service
-- Logs begin at Fri 2019-11-22 14:52:40 UTC, end at Fri 2019-11-22 14:53:59 UTC. --
Nov 22 14:53:19 localhost.localdomain systemd[1]: Started Mondoo Service.
Nov 22 14:53:19 localhost.localdomain systemd[1]: Starting Mondoo Service...
Nov 22 14:53:19 localhost.localdomain mondoo[3465]: <E2><86><92>  start mondoo background service
Nov 22 14:53:19 localhost.localdomain mondoo[3465]: <E2><86><92>  scan interval is 60 minute(s)
Nov 22 14:53:20 localhost.localdomain mondoo[3465]: <E2><86><92>  start the vulnerability scan
Nov 22 14:53:20 localhost.localdomain mondoo[3465]: <E2><86><92>  enabled async collector mode
Nov 22 14:53:20 localhost.localdomain mondoo[3465]: [81B blob data]
Nov 22 14:53:20 localhost.localdomain mondoo[3465]: [59B blob data]
Nov 22 14:53:21 localhost.localdomain mondoo[3465]: [93B blob data]
Nov 22 14:53:21 localhost.localdomain mondoo[3465]: [492B blob data]
Nov 22 14:53:21 localhost.localdomain mondoo[3465]: [49B blob data]
Nov 22 14:53:28 localhost.localdomain mondoo[3465]: <E2><9C><94>  sent packages successfully
```
