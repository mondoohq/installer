# Mondoo systemd demo with Docker

NOTE: We do NOT recommend running systemd inside of a container. Mondoo does not require systemd. This demo is here to illustrate Mondoo's systemd inntegration and to get a feeling about the setup. For a more production-like setup, please have a look at the `systemd-vagrant` setup.

At first, built the container:

```
docker build -t mondoo-systemd-example .
```

Then run the mondoo service:

```
docker run -it --name mondoo-systemd --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v $(PWD)/mondoo.yml:/etc/opt/mondoo/.mondoo.yml mondoo-systemd-example:latest
```

Note: the running container does not react on ctrl+c commands. Open a new terminal and then run `docker kill mondoo-systemd`