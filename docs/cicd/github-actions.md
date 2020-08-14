## Github Actions

![Illustration of Github Actions integration](../../assets/integration-github-actions.png)

[Github Actions](https://github.com/features/actionshttps://github.com/features/actions)  makes it easy to automate all your software workflows. The following example demonstrates how to build a docker image in Github Actions and use Mondoo to verify the image for vulnerabilities before its being uploaded to a Docker registry.

```
name: Docker Image CI

on: [push]

jobs:

  build:

    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@master
    - name: Build Docker image
      run: docker build . --file Dockerfile --tag my-image-name:${GITHUB_SHA}
    - name: Scan Docker image
      env:
        MONDOO_AGENT_ACCOUNT: ${{ secrets.MONDOO_AGENT_ACCOUNT }}
      run: |
        echo ${MONDOO_AGENT_ACCOUNT} | base64 -d > mondoo.json
        curl -sSL https://mondoo.io/download.sh | bash
        ./mondoo scan -t docker://my-image-name:${GITHUB_SHA} --config mondoo.json
```

The Mondoo agent requires a secret to authenticate. Generate the base64-encoded secret in Mondoo Dashboard and store it as a [Github Actions Secret](https://help.github.com/en/articles/virtual-environments-for-github-actions#creating-and-using-secrets-encrypted-variables) `MONDOO_AGENT_ACCOUNT`. You can either [download the credentials](../../agent/installation/registration) or use the CI/CD integration page. For Github Actions, you need to encode the [credentials as base64](#store-mondoo-credentials).

![Paste the configuration as GCP substitution variable](../../assets/mondoo-cicd-githubactions-credentials.png)

You can see the vulnerability report as part of the CI/CD job.

![Run a mondoo scan in Github Actions](../../assets/mondoo-cicd-githubactions-result-text.png)