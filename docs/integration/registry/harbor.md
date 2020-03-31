# Harbor

The [Harbor Registry](https://goharbor.io/) is an open-source container registry. To set-up, the registry, follow the official [Harbor Installation and Configuration](https://goharbor.io/docs/1.10/install-config/).

![Mondoo Harbor Container Registry scan from CLI](../../assets/videos/harbor-scan.gif)

## Precondition

Login to docker with your Harbor credentials. Mondoo will leverage Docker's configuration.

```bash
docker login -u admin -p Harbor12345 harbor.yourdomain.com
```

## Scan

> Note: If you are running Harbor with self-signed certificates, use the `--insecure` flag. It deactivates Mondoo certificate checks. We do not recommend to use a self-signed certificate in production

To scan the whole registry, run:

```bash
mondoo scan -t cr://harbor.yourdomain.com --insecure
```

To scan an individual repository, run:

```bash
mondoo scan -t cr://harbor.yourdomain.com/library/centos --insecure
```
