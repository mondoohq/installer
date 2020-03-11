# Scan targets from your workstation

While the Mondoo agent is designed to run continuously on your server infrastructure, it is also easy to use CLI for quick ad-hoc vulnerability scans. This allows anybody to gather a quick risk assessment for a specific asset. By using Mondoo's agent, you can scan:

- Ssh targets
- Docker images
- Running Docker containers
- Stopped Docker containers
- Local system (where the agent is running on)

The following examples assume you have [installed Mondoo on your workstation](./quickstart).

## SSH Targets

The mondoo agent has full ssh support and picks up configuration from ssh config and credentials from the ssh-agent automatically. Therefore, you do not need to pass in secrets as clear text which prevents storing credentials in shell history. Plus, it is way more convenient :-)

```bash
# scan ssh target with default port 22
$ mondoo scan -t ssh://ec2-user@52.51.185.215

# scan ssh target on a custom port  
$ mondoo scan -t ssh://ec2-user@52.51.185.215:2222
```

![Mondoo SSH scan from CLI](../assets/videos/ssh-scan.gif)

Definitions from ` ~/.ssh/config` are used by the mondoo agent. The following defines the host `shorty` for ssh:

```
Host shorty
  HostName 54.205.49.51
  User ec2-user
```

You can use `shorty` as host identifier with `monndoo`  then:

```
# use hosts defined in ~/.ssh/config 
$ mondoo scan -t ssh://shorty
```

**Identity Authentication**

You can always pass unencrypted keys via the `-i` option:

```
mondoo scan -t ssh://vagrant@192.168.100.70 -i /path/to/private_key
```

> Note: We recommend using ssh-agent for identity keys since `mondoo` cannot decrypt keys by itself

**Agent Authentication**

Since `mondoo` integrates with `ssh-agent`, you do not need to provide the identity key. This is also the recommended solution for encrypted identity keys:

```
ssh-add /path/to/private_key
mondoo scan -t ssh://vagrant@192.168.100.70
```

**Password Authentication**

NOTE: We do not recommended this method for any production workloads, since it may expose your password as cleartext in logs

```
mondoo scan -t ssh://vagrant:vagrant@192.168.100.70
```

## Docker Images

![Mondoo Docker image scan from CLI](../assets/videos/docker-image-scan.gif)

Mondoo can scan Docker container images directly via their registry name: 

```
$ mondoo scan -t docker://ubuntu:latest
$ mondoo scan -t docker://elastic/elasticsearch:7.2.0
$ mondoo scan -t docker://gcr.io/google-containers/ubuntu:14.04
$ mondoo scan -t docker://registry.access.redhat.com/ubi8/ubi
```

If the Docker agent is installed, you can scan images by their id:

```
$ mondoo scan -t docker://docker-image-id
```

## Docker Container

![Mondoo Docker container scan from CLI](../assets/videos/docker-container-scan.gif)

You can easily scan running containers by their id:

```
$ mondoo scan -t docker://docker-container-id
```

Scans also work for stopped containers.

![Mondoo stopped Docker container scan from CLI](../assets/videos/docker-stopped-container-scan.gif)

> Note: Docker container can only be scanned if the Docker engine is installed

## Local System

Linux bases systems can also be scanned locally:

```
$ mondoo scan
```
