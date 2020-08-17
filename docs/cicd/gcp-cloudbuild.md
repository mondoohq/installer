# GCP Cloud Build

![Illustration of GCP Cloud Build integration](./integration-gcp-cloudbuild.png)

GCP Cloud Build is a Docker-based pipeline where each task executes in its own Docker container. To run a vulnerability scan, we use the Mondoo's docker image and verify the image before its being uploaded to GCR.

```
# Scan Docker image with Mondoo before pushing to GCR
substitutions:
  _IMAGE_NAME: demoimage
  _MONDOO_AGENT_ACCOUNT: ""
steps:
# build docker image
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', 'gcr.io/$PROJECT_ID/${_IMAGE_NAME}', '.']
# store docker image in workspace
- name: 'gcr.io/cloud-builders/docker'
  args: ['save', '-o', '/workspace/${_IMAGE_NAME}.tar', 'gcr.io/$PROJECT_ID/${_IMAGE_NAME}']
# store mondoo credentials into workspace
- name: 'mondoolabs/mondoo'
  entrypoint: /bin/sh
  args: ['-c', 'echo ${_MONDOO_AGENT_ACCOUNT} | base64 -d > /workspace/mondoo.json']
# run mondoo config
- name: 'mondoolabs/mondoo'
  args: ['scan', '-t', 'docker:///workspace/${_IMAGE_NAME}.tar', '--config', '/workspace/mondoo.json']
  # optional environment variables, those enable you to reference the mondoo report with your build
  env:
  - 'CLOUDBUILD=true'
  - 'BUILD=$BUILD_ID'
  - 'PROJECT=$PROJECT_ID'
  - 'COMMIT_SHA=$COMMIT_SHA'
  - 'SHORT_SHA=$SHORT_SHA'
  - 'REPO_NAME=$REPO_NAME'
  - 'BRANCH_NAME=$BRANCH_NAME'
  - 'TAG_NAME=$TAG_NAME'
  - 'REVISION_ID=$REVISION_ID'
images: ['gcr.io/$PROJECT_ID/${_IMAGE_NAME}']
```

You need to configure a [substitution variable](https://cloud.google.com/cloud-build/docs/configuring-builds/substitute-variable-values) to store the credentials for the Mondoo agent in `_MONDOO_AGENT_ACCOUNT`. You can either [download the credentials](../../agent/installation/registration) or use the GCP Cloud Build integration page. For GCP Code Build, you need to encode the [credentials as base64](#store-mondoo-credentials). Next, you create a new `_MONDOO_AGENT_ACCOUNT` variable and paste the content of the agent credentials:

![Paste the configuration as GCP substitution variable](./mondoo-cicd-cloudbuild-setup.png)

You can see the vulnerability report as part of the CI/CD job.

![Run a mondoo scan in GCP Cloud Build](./mondoo-cicd-cloudbuild-result-text.png)