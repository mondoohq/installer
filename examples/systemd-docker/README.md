# Mondoo systemd demo with Docker

NOTE: We do NOT recommend running systemd inside of a container. Mondoo does not require systemd. This demo is here to illustrate Mondoo's systemd inntegration and to get a feeling about the setup. For a more production-like setup, please have a look at the `systemd-vagrant` setup.

At first, built the container:

```
docker build -t mondoo-systemd-example .
```

Then run the Mondoo service:

```bash
# first-time (only required once to register the agent)
$ docker run -it --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v $(PWD):/etc/opt/mondoo/ mondoo-systemd-example:latest mondoo register --token $TOKEN --config /etc/opt/mondoo/mondoo.yml
$ echo "collector: http" >> mondoo.yml

# start the mondoo systemd service in background
$ docker run -it --name mondoo-systemd -d --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v $(PWD):/etc/opt/mondoo/ mondoo-systemd-example:latest

# to inspec the container
$ docker exec -it mondoo-systemd /bin/bash
bash-4.4# systemctl status mondoo
● mondoo.service - mondoo vuln
   Loaded: loaded (/etc/systemd/system/mondoo.service; static; vendor preset: disabled)
   Active: inactive (dead)

# delete container
$ docker rm mondoo-systemd  
```

Note: Please be aware that the default /sbin/init process does not on ctrl+c commands. This is important if you decide to run the container in foreground. To stop the container, open a new terminal and then run `docker kill mondoo-systemd`