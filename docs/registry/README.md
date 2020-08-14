# Container Registry Auditing

Mondoo supports a wide-range of Docker registries:

- [Azure Container Registry](azure_acr.md#azure-container-registry)
- [AWS Elastic Container Registry](aws_ecr#aws-elastic-container-registry)
- [Docker Hub](docker_hub#docker-hub)
- [Google Cloud Container Registry](gcp_gcr#google-cloud-container-registry)
- [Harbor Registry](harbor#harbor-registry)

You can scan a container registry from CLI via:

```
$ mondoo scan -t cr://registry
$ mondoo scan -t cr://registry/namespace/repository
$ mondoo scan -t cr://harbor.yourdomain.com
$ mondoo scan -t cr://harbor.yourdomain.com/project/repository
$ mondoo scan -t cr://yourname.azurecr.io
$ mondoo scan -t cr://123456789.dkr.ecr.us-east-1.amazonaws.com/repository
```