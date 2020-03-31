# Scan targets from your workstation

While the Mondoo agent is designed to run continuously on your server infrastructure, it is also easy to use CLI for quick ad-hoc vulnerability scans. This allows anybody to gather a quick risk assessment for a specific asset. By using Mondoo's agent, you can scan:

*Inventory*

- [SSH Targets](./#ssh-targets)
- [Ansible Inventory](./#ansible-inventory)
- [Local System](./#local-system)

*Cloud*

- [Azure Compute Instances](./#azure-instances)
- [AWS EC2 Instances](./#aws-ec2-instances)
- [GCP Compute Instances](./#gcp-instances)

*Container & Kubernetes*

- [Kubernetes](./#kubernetes)
- [Docker Images](./#docker-images)
- [Docker Container](./#docker-container)

*Container Registry*

- [Azure Container Registry](./#azure-container-registry)
- [AWS Elastic Container Registry](./#aws-elastic-container-registry)
- [Docker Hub Repository](./#aws-elastic-container-registry)
- [Google Cloud Container Registry](./#google-cloud-container-registry)
- [Harbor Registry](./#harbor-registry)

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

## Ansible Inventory

Ansible inventory is a list of hosts that is mostly stored in the two common formats `ini` and `yaml`. 

![Mondoo using Ansible inventory](../assets/ansible-inventory.png)

The ini format allows grouping and easy configuration of additional properties:

```ini
# hosts.ini
[workers]
34.243.41.251 ansible_user=ec2-user
instance1 ansible_host=18.203.250.158 ansible_user=ubuntu
```

Equipped with this inventory, you can ping all the hosts with ansible:

```bash
ansible all -i hosts.ini -m ping
34.243.41.251 | SUCCESS => {
 "changed": false, 
 "ping": "pong"
}
instance1 | SUCCESS => {
 "changed": false, 
 "ping": "pong"
}
```

Then use `ansible-inventory` with Mondoo:

```bash
ansible-inventory -i hosts.ini --list | mondoo scan --ansible-inventory
```

Further information is available at [Integration/DevOps/Ansible](../integration/devops/ansible#ansible-and-mondoo)

## Local System

Linux bases systems can also be scanned locally:

```
$ mondoo scan
```

## Azure Instances

![Mondoo Azure instances scan from CLI](../assets/videos/azure-compute-scan.gif)

```bash
az login
```

You need your subscription id and the resource group. Run `az account list` and ` az vm list` to determine those values:

```bash
$ az account list
Name                  CloudName    SubscriptionId                        State    IsDefault
--------------------  -----------  ------------------------------------  -------  -----------
Azure subscription 1  AzureCloud   10192451-09aa-4782-1016-1cdfede1026b  Enabled  True

$ az vm list
Name     ResourceGroup    Location    Zones
-------  ---------------  ----------  -------
centos   DEMO             westus
ubuntu   DEMO             westus
win2019  DEMO             westus
```

Then scan your resource group via: 

```
$ mondoo scan -t az://subscriptions/subscriptionid/resourceGroups/groupname
```

This will determine all instances running in Azure and try to connect via SSH. 

> Note: we recommend to use ssh config to configure the login names and ssh agent to manage your credentials 

Further information is available at [Integration/Cloud/Azure](../integration/cloud/azure#azure-integration)

## AWS EC2 Instances

![Mondoo EC2 instances scan from CLI](../assets/videos/aws-ec2-scan.gif)

Configure your AWS credentials in `~/.aws/credentials`. If required, set the `AWS_PROFILE` and `AWS_REGION`:

```bash
$ export AWS_PROFILE=mondoo
$ export AWS_REGION=us-east-1 
```

Now, scan instances in your region via:

```
$ mondoo scan -t ec2://user/ec2-user
```

This will determine all instances running in AWS and try to connect via SSH.

You can also overwrite the region and profile via the mondoo target identifier:

```bash
$ mondoo scan -t ec2://profile/name/region/us-east-1
$ mondoo scan -t ec2://region/us-east-1
$ mondoo scan -t ec2://profile/mondoo-inc/region/us-east-1/user/ec2-user
```

To scan individual instances, use:

```
$ mondoo scan -t ssh://ec2-user@52.51.185.215
$ mondoo scan -t ssh://ec2-user@52.51.185.215:2222
```

> Note: we recommend to use ssh config to configure the login names and ssh agent to manage your credentials 

Further information is available at [Integration/Cloud/AWS](../integration/cloud/aws#aws-integration)

## GCP Instances

![Mondoo GCP instances scan from CLI](../assets/videos/gcp-compute-scan.gif)

Install the [gcloud](https://cloud.google.com/sdk/install) CLI and [login](https://cloud.google.com/sdk/gcloud/reference/auth/login) via `gcloud auth login`. Then set your project:

```bash
$ gcloud config set project <projectID>
Updated property [core/project].
```

Then list all instances:

```bash
gcloud compute instances list
```

Then scan all instances:

```
$ mondoo scan -t gcp://
```

You can also override the GCP project via the mondoo target identifier:

```
mondoo scan -t gcp://project/projectid
```

To scan individual instances, use:

```
$ mondoo scan -t ssh://user@52.51.185.215
$ mondoo scan -t ssh://user@52.51.185.215:2222
```

> Note: we recommend to use ssh config to configure the login names and ssh agent to manage your credentials 


Further information is available at [Integration/Cloud/GCP](../integration/cloud/gcp#gcp-integration)

## Kubernetes

![Mondoo Kubernetes scan from CLI](../assets/videos/k8s-scan.gif)

Ensure you can connect to your cluster via `kubectl`:

```bash
kubectl get pods                                                          
NAME                          READY   STATUS                 RESTARTS   AGE
centos-6b88594b-jm7bp         0/1     CreateContainerError   0          5d1h
hello-node-7676b5fb8d-xck5l   1/1     Running                0          5d1h
```

Then you can scan your cluster via:

```
$ mondoo scan -t k8s://
```

You can also override the context and the namespace:

```bash
$ mondoo scan -t k8s://context/c1
$ mondoo scan -t k8s://context/c1/namespace/n1
$ mondoo scan -t k8s://namespace/n1
```

Further information is available at [Integration/Cloud/K8S](../integration/cloud/k8s#k8s-integration)

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

## Azure Container Registry

![Mondoo Azure Container Registry scan from CLI](../assets/videos/azure-acr-scan.gif)

Login to the registry via:

```bash
az acr login --name <acrName>
```

Then scan the registry via:

```bash
$ mondoo scan -t cr://yourname.azurecr.io
```

Further information is available at [Integration/Registry/Azure](../integration/registry/azure_acr#azure-container-registry)

## AWS Elastic Container Registry

![Mondoo AWS Elastic Container Registry scan from CLI](../assets/videos/aws-ec2-scan.gif)

Login to the registry via:

```bash
$ aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123101453137.dkr.ecr.us-east-1.amazonaws.com
Login Succeeded
```

Then scan the repository via:

```
$ mondoo scan -t cr://123456789.dkr.ecr.us-east-1.amazonaws.com/repository
```

Further information is available at [Integration/Registry/AWS](../integration/registry/aws_ecr#aws-elastic-container-registry)

## Docker Hub

![Mondoo Docker Hub scan from CLI](../assets/videos/docker-hub-scan.gif)

Install the `docker` CLI and [login to the registry](https://docs.docker.com/engine/reference/commandline/login/):

```bash
docker login
```

Then scan a repository via:

```bash
cr://index.docker.io/namespace/repository
```

Further information is available at [Integration/Registry/DockerHub](../integration/registry/docker_hub#docker-hub)

## Google Cloud Container Registry

![Mondoo Google Cloud Container Registry scan from CLI](../assets/videos/gcp-gcr-scan.gif)

To authenticate with the registry, [login with gcloud](https://cloud.google.com/container-registry/docs/advanced-authentication#standalone-helper)

```
gcloud auth configure-docker
```

Then scan a repository via:

```bash
mondoo scan -t cr://gcr.io/<projectID>/<repoName>
```

Further information is available at [Integration/Registry/GCP](../integration/registry/gcp_gcr#google-cloud-container-registry)

## Harbor Registry

![Mondoo Harbor Container Registry scan from CLI](../assets/videos/harbor-scan.gif)

To authenticate with the registry, login with docker:

```bash
docker login -u admin -p Harbor12345 harbor.yourdomain.com
```

Then scan the registry or a repository via:

```
$ mondoo scan -t cr://harbor.yourdomain.com
$ mondoo scan -t cr://harbor.yourdomain.com/project/repository
```

> Note: use the `--insecure` flag to connect to a registry with a self-signed certificate

Further information is available at [Integration/Registry/Harbor](../integration/registry/harbor#harbor)