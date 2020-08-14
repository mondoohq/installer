# Google Cloud Platform Container Registry (GCR)

The [Container Registry](https://cloud.google.com/container-registry) allows you to store container images within GCP. To get familiar with the GCP container registry, follow their [Get Started Guide](https://cloud.google.com/container-registry/docs/quickstart).

![Mondoo Google Cloud Container Registry scan from CLI](../static/videos/gcp-gcr-scan.gif)

## Precondition

Install the [gcloud](https://cloud.google.com/sdk/install) command and [login](https://cloud.google.com/sdk/gcloud/reference/auth/login) via `gcloud auth login`.

Then set your project:

```bash
$ gcloud config set project <projectID>
Updated property [core/project].
```

Then list all available container repositories:

```bash
$ gcloud container images list
NAME
gcr.io/<projectID>/<repoName>
```

and their tags:

```bash
$ gcloud container images list-tags gcr.io/<projectID>/<repoName>
DIGEST        TAGS    TIMESTAMP
e5dd9dbb37df  latest  2020-03-20T20:20:23
a98d9dcf3a34  16.04   2020-02-21T23:22:30
0925d0867157  18.04   2020-02-21T23:20:44
61844ceb1dd5  19.04   2020-01-16T02:20:47
```

To authenticate with the registry, [login with gcloud](https://cloud.google.com/container-registry/docs/advanced-authentication#standalone-helper)

```
gcloud auth configure-docker
```

# Scan

To scan an individual repository, use:

```bash
mondoo scan -t cr://gcr.io/<projectID>/<repoName>
  →  loaded configuration from /Users/chris-rock/.mondoo.yml
Start the vulnerability scan:
  →  resolve asset connections
  →  verify platform access to a98d9dcf3a34
  →  gather platform details
  →  detected ubuntu 16.04
  →  gather platform packages for vulnerability scan
  →  found 96 packages
  ✔  completed analysis for a98d9dcf3a34
  →  verify platform access to 0925d0867157
  →  gather platform details
  →  detected ubuntu 18.04
  →  gather platform packages for vulnerability scan
  →  found 89 packages
  ✔  completed analysis for 0925d0867157
  →  verify platform access to 61844ceb1dd5
  →  gather platform details
  →  detected ubuntu 19.04
  →  gather platform packages for vulnerability scan
  →  found 89 packages
  ✔  completed analysis for 61844ceb1dd5
  →  verify platform access to e5dd9dbb37df
  →  gather platform details
  →  detected ubuntu 18.04
  →  gather platform packages for vulnerability scan
  →  found 89 packages
  ✔  completed analysis for e5dd9dbb37df
Advisory Reports Overview
  ■  SCORE  NAME          SCORE
  ■  0.0    a98d9dcf3a34  ══════════
  ■  0.0    0925d0867157  ══════════
  ■  4.6    61844ceb1dd5  ══════════
  ■  0.0    e5dd9dbb37df  ══════════
```

GCP also ships with non-standard extensions to search images on your project level. To leverage those extensions, use the `gcr://` prefix:

```bash
mondoo scan -t gcr://gcr.io/<projectID>
```