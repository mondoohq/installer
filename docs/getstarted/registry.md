# Container Registry Security

## Azure Container Registry

![Mondoo Azure Container Registry scan from CLI](../static/videos/azure-acr-scan.gif)

Log in to the registry via:

```bash
az acr login --name <acrName>
```

Then scan the registry via:

```bash
$ mondoo scan -t cr://yourname.azurecr.io
```

Further information is available at [Integration/Registry/Azure](../registry/azure_acr.md#azure-container-registry)

## AWS Elastic Container Registry

![Mondoo AWS Elastic Container Registry scan from CLI](../static/videos/aws-ec2-scan.gif)

Log in to the registry via:

```bash
$ aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123101453137.dkr.ecr.us-east-1.amazonaws.com
Login Succeeded
```

Then scan the repository via:

```bash
$ mondoo scan -t cr://123456789.dkr.ecr.us-east-1.amazonaws.com/repository
```

Further information is available at [Integration/Registry/AWS](../registry/aws_ecr.md#aws-elastic-container-registry)

## Docker Hub Repository

![Mondoo Docker Hub scan from CLI](../static/videos/docker-hub-scan.gif)

Install the `docker` CLI and [log in to the registry](https://docs.docker.com/engine/reference/commandline/login/):

```bash
docker login
```

Then scan a repository via:

```bash
cr://index.docker.io/namespace/repository
```

Further information is available at [Integration/Registry/DockerHub](../registry/docker_hub.md#docker-hub)

## Google Cloud Container Registry

![Mondoo Google Cloud Container Registry scan from CLI](../static/videos/gcp-gcr-scan.gif)

To authenticate with the registry, [log in with gcloud](https://cloud.google.com/container-registry/docs/advanced-authentication#standalone-helper)

```bash
gcloud auth configure-docker
```

Then scan a repository via:

```bash
mondoo scan -t cr://gcr.io/<projectID>/<repoName>
```

Further information is available at [Integration/Registry/GCP](../registry/gcp_gcr.md#google-cloud-container-registry)

## Harbor Registry

![Mondoo Harbor Container Registry scan from CLI](../static/videos/harbor-scan.gif)

To authenticate with the registry, log in with docker:

```bash
docker login -u admin -p Harbor12345 harbor.yourdomain.com
```

Then scan the registry or a repository via:

```bash
$ mondoo scan -t cr://harbor.yourdomain.com
$ mondoo scan -t cr://harbor.yourdomain.com/project/repository
```

> Note: use the `--insecure` flag to connect to a registry with a self-signed certificate

Further information is available at [Integration/Registry/Harbor](../registry/harbor.md#harbor)