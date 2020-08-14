# Azure Container Registry

The [Azure Container Registry](https://azure.microsoft.com/en-us/services/container-registry/) allows you to store container images within Azure. To get familiar with the Azure registry, follow their [Get Started Guide](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-docker-cli).

![Mondoo Azure Container Registry scan from CLI](../static/videos/azure-acr-scan.gif)

## Precondition

The `mondoo` CLI leverages the configuration from [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest). Install the `az` command and login to Azure:

```bash
az login
```

Then, you can display all available registries:

```bash
$ az acr list --output table
NAME       RESOURCE GROUP    LOCATION    SKU       LOGIN SERVER
---------  ----------------  ----------  --------  --------------------
<acrName>  <resourceGroup>   eastus      Standard  <acrLoginServer>
```

Now, you can list available container images

```bash
$ az acr repository list --name <acrName> --output table
Result
-----------
centos
hello-world
ubuntu
```

Login to `docker` to ensure the Azure CLI creates the correct docker configuration. Mondoo uses the `docker` configuration to connect to Azure as well.

```bash
az acr login --name <acrName>
```

## Scan

After we completed the login, `mondoo` is ready to scan the registry:

```bash
# scan the complete registry
$ mondoo scan -t cr://<acrLoginServer>
  →  loaded configuration from /Users/chris-rock/.mondoo.yml
Start the vulnerability scan:
  →  resolve asset connections
  →  verify platform access to 7e5330839326
  →  gather platform details
  →  detected centos 6.10
  →  gather platform packages for vulnerability scan
  →  found 129 packages
  ✔  completed analysis for 7e5330839326
  →  verify platform access to 92c7f9c92844
  →  gather platform details
  →  detected scratch
  →  gather platform packages for vulnerability scan
  →  found 0 packages
  ✔  completed analysis for 92c7f9c92844
  →  verify platform access to 61844ceb1dd5
  →  gather platform details
  →  detected ubuntu 19.04
  →  gather platform packages for vulnerability scan
  →  found 89 packages
  ✔  completed analysis for 61844ceb1dd5
Advisory Reports Overview
  ■  SCORE  NAME          SCORE
  ■  9.8    7e5330839326  ══════════
  ■  0.0    92c7f9c92844  ══════════
  ■  0.0    61844ceb1dd5  ══════════
```

You can also scan individual repositories:

```bash
$ mondoo scan -t cr://<acrLoginServer>/centos
  →  loaded configuration from /Users/chris-rock/.mondoo.yml
Start the vulnerability scan:
  →  resolve asset connections
  →  verify platform access to 7e5330839326
  →  gather platform details
  →  detected centos 6.10
  →  gather platform packages for vulnerability scan
  →  found 129 packages
  ✔  completed analysis for 7e5330839326
Advisory Report ( asset 7e5330839326):
  ■   SCORE  PACKAGE                   INSTALLED              VULNERABLE (<)              AVAILABLE              ADVISORY
  ■   9.8    python                    2.6.6-66.el6_8         2.6.6-68.el6_10             2.6.6-66.el6_8         https://mondoo.app/vuln/CESA-2019%3A1467
  ...
  →  ■ found 10 advisories: ■ 1 critical, ■ 5 high, ■ 4 medium, ■ 0 low, ■ 0 informational, ■ 0 unknown
```

If you want to scan a specific container image, use:

```bash
mondoo scan -t docker://mondooacr.azurecr.io/centos:6.10
```