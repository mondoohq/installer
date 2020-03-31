# Docker Hub

The [Docker Hub](https://hub.docker.com/) is a well-known registry, where the major public container images are listed. To get familiar with the Docker Hub, follow their [Get Started Guide](https://docs.docker.com/docker-hub/).

![Mondoo Docker Hub scan from CLI](../../assets/videos/docker-hub-scan.gif)

## Precondition

Install the `docker` CLI and [login to the registry](https://docs.docker.com/engine/reference/commandline/login/):

```bash
docker login
```

## Scan

Once logged in, you can run `mondoo scan` to asses the risks:

```bash
$ mondoo scan -t cr://index.docker.io/mondoolabs/mondoo
  →  loaded configuration from /Users/chris-rock/.mondoo.yml
Start the vulnerability scan:
  →  resolve asset connections
  →  verify platform access to cf5442b2d681
  →  gather platform details
  →  detected alpine 3.10.1
  →  gather platform packages for vulnerability scan
  →  found 38 packages
  ✔  completed analysis for cf5442b2d681
  →  verify platform access to 23ae745857f8
  →  gather platform details
  →  detected alpine 3.10.1
  →  gather platform packages for vulnerability scan
  →  found 38 packages
  ✔  completed analysis for 23ae745857f8
...
  →  verify platform access to b419fd9f16ae
  →  gather platform details
  →  detected alpine 3.10.2
  →  gather platform packages for vulnerability scan
  →  found 38 packages
  ✔  completed analysis for b419fd9f16ae
Advisory Reports Overview
  ■  SCORE  NAME          SCORE       
  ■  0.0    331cf0232075  ══════════  
  ■  0.0    747afbd1fb74  ══════════  
  ■  0.0    eafc9d1d5537  ══════════  
  ■  0.0    b419fd9f16ae  ══════════  
  ■  0.0    9b4ae77d28b6  ══════════  
  ■  0.0    cb01bf407dc2  ══════════  
  ■  0.0    d16b8960ff5f  ══════════  
  ■  0.0    0b811b267d65  ══════════  
  ■  0.0    c601ebfd35b4  ══════════  
  ■  0.0    087756d58892  ══════════  
  ■  0.0    5a2cd2cd75f3  ══════════  
  ■  0.0    1e6c181819f1  ══════════  
  ■  0.0    f36d3fba0066  ══════════  
  ■  0.0    9908ccbd6449  ══════════  
  ■  0.0    23ae745857f8  ══════════  
  ■  0.0    4f81f1be7364  ══════════  
  ■  0.0    487a85aea611  ══════════  
  ■  0.0    69bd294493a0  ══════════  
  ■  0.0    f59925492ed6  ══════════  
  ■  0.0    cf5442b2d681  ══════════  
```