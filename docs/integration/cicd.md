# CI/CD

Mondoo's vulnerability risk management solution is optimized for [runtime and build-time](../get-started/introduction-mondoo) analysis. Mondoo can be easily used in all CI/CD environments. The general workflow is as follows:

 - Developers push code into the source repository
 - CI/CD retrieves a trigger and starts building VM or container image
 - Mondoo agent scans VM or container image and returns vulnerability rating
 - CI/CD continues or aborts process based on user configuration
 - CI/CD publishes VM or container image

The setup can be used in various scenarios:

 - Scan machines that are deployed via CI/CD (eg. via SSH)
 - Scan AMI images uses (e.g. via [Mondoo's Packer integration](./packer))
 - Scan container images

## General Setup in CI/CD

No matter if you want to scan a container image, a VM or a deployed machine, the setup is always the same. In pre-build, we retrieve the [agent credentials](../agent/credentials) that are passed into the CI/CD job via an environment variable. To verify that everything worked, we run `mondoo version`:

**Pre-Build**
```bash
echo Download Mondoo
echo $MONDOO_AGENT_ACCOUNT > mondoo.json
curl -sSL https://mondoo.io/download.sh | bash 
./mondoo version 
```

More information about `download.sh` script is available at our [binary installation](../agent/binaries) documentation. Alternatively, we provide the alpine-based [mondoolabs/mondoo:latest](https://hub.docker.com/r/mondoolabs/mondoo) docker image which includes the mondoo binary already.

Once the `mondoo` command is set up properly, we can run a vulnerability scan:

**Build**
```
# run mondoo vulnerability scan
mondoo scan -t docker://imageid --config mondoo.json
```

In this case, we pipe the mondoo configuration into the mondoo binary and scan a docker image. If you like to scan an ssh target you can just call `mondoo scan -t ssh://ec2-user@52.51.185.215:2222`. All available options are documented for [mondoo scan](../agent/mondoo_scan)

### Exit Code Handling

Of particular interest in CI/CD is the handling of exit codes to implement project-specific decisions.

**Pass on Threshold**

By default, `mondoo scan` returns specific exit codes for [CVSS v3.0 Ratings](https://nvd.nist.gov/vuln-metrics/cvss#):

  * 0 - scan completed successfully with no vulnerabilities found
  * 1 - error during execution
  * 101 - scan completed successfully with vulnerabilities of low severity found
  * 102 - scan completed successfully with vulnerabilities of medium severity found
  * 103 - scan completed successfully with vulnerabilities of high severity found
  * 104 - scan completed successfully with vulnerabilities of critical severity found

This allows you to implement threshold-bassed deployment blocking. The following example illustrates how to pass a scan with low and medium severity advisories only:

```
# this will run mondoo and pass if the exit code is 0, 101 or 102
x=$(mondoo scan -t docker://centos:7 --config mondoo.json); exitcode="$?"; echo $x; echo $exitcode; test $exitcode -eq 0 -o $exitcode -eq 101 -o $exitcode -eq 102
```

![Use custom threshold for Mondoo](../assets/mondoo-cicd-threshold.png)

**Pass on successful scan**

Another use case is to assess the vulnerability risk only. Instead of blocking the pipeline, you may want to always pass the build if the scan was successful. This can be achieved by passing `--exit-0-on-success` to `mondoo scan`. In most cases, this is a great setting if you just start with vulnerability assessments in CI/CD pipelines.

```
mondoo scan -t docker://a3592cc01fdf --exit-0-on-success
```

![Always pass if the mondoo scan was successful](../assets/mondoo-cicd-exit0.png)

### Store mondoo credentials

Mondoo agents uses a private key to encrypt all communication with Mondoo API. Since CI/CD do not allow persistent configuration on the build nodes, the configuration needs to be passed into the CI/CD job. All CI/CD environments have a method to store environment variables. Some provide extra capabilities to store secrets (preferred if available). Set the `MONDOO_AGENT_ACCOUNT` environment variable with the content of the [agent credentials file](../agent/configuration?id=retrieve-agent-credentials):


```
$ cat mondoo-1OsrpJIaaXmBVXXWvKj8KH1eBxH.json
{"agentMrn":"//agents.api.mondoo.app/spaces/peaceful-euler-123456/agents/1OsrpJIaaXmBVXXWvKj8KH1eBxH","spaceMrn":"//captain.api.mondoo.app/spaces/peaceful-euler-123456","privatekey":"-----BEGIN PRIVATE KEY-----\nMIG2AgEAMBAGByqGSM49AgEGBSuBBAAiBIGeMIGbAgEBBDBehmtGGruVyXLjqvkE\nOa2ieZuVY4wDbaMmtKyr6sofw9p+OQKvVxEDGX4wcY0owp9rqk3alWiRv957VcTn\n17e3FNexFQ4KFu/Ds1cdG5LaOrr5NcPgF+yqYGWux3GLOzT2Nuys7oU=\n-----END PRIVATE KEY-----\n","certificate":"-----BEGIN CERTIFICATE-----\nMIICVTCCAdygAwIBAgIQOzcp1r6SPQYnrn/ZxNm1njAKBggqhkjOPQQDAzBAMT4w\nPAYDVQQKEzUvL2NhcHRhaW4uYXBpLm1vbmRvby5hcHAvc3BhY2VzL3BlYWNlZnVs\nLWV1bGVyLTY3Nzk0NTAeFw0xOTA4MDIyMDIyMDZaFw0xOTA4MDMyMDIyMDZaMEAx\nPjA8BgNVBAoTNS8vY2FwdGFpbi5hcGkubW9uZG9vLmFwcC9zcGFjZXMvcGVhY2Vm\nZWZ1bC1ldWxlci02Nzc5NDUvYWdlbnRzLzFPc3JwSklhYVhtQlZYWFd2S2o4S0gx\nZUJ4SDAKBggqhkjOPQQDAwNnADBkAjBwoqrbPG1cuSZypxGBr2JVCbwKr3s03jSp\nUNG2f+yCViaWoYKyMb0mS1kv/+q3hu0CMGHFYxDdf7NNzFgNlXVr1jY8rUxsaPyz\nMOPM37wX3OrUHyDqSfcEZN1OVp7YN93hwA==\n-----END CERTIFICATE-----\n"}
```

In you pipeline you can easily store the file during every job via:

```
echo $MONDOO_AGENT_ACCOUNT > mondoo.json
```

**Handle certificate authentication error**

The JSON configuration file includes the agent's private key and certificate. The pem format requires proper newlines and some CI/CD systems interpret the newline. In those cases you recieve an error like `cannot configure certificate authentication`. The following illustrates that error in AWS CodePipeline:

![Certificate authentication error in CI/CD](../assets/mondoo-cicd-missingbase64.png)

To prevent the CI/CD system from interpreting the configuration content, you can encode the file as base64:

```
$ base64 mondoo-docs.json 
eyJhZ2VudE1ybiI6Ii8vYWdlbnRzLmFwaS5tb25kb28uYXBwL3NwYWNlcy9wZWFjZWZ1bC1ldWxlci0xMjM0NTYvYWdlbnRzLzFPc3JwSklhYVhtQlZYWFd2S2o4S0gxZUJ4SCIsInNwYWNlTXJuIjoiLy9jYXB0YWluLmFwaS5tb25kb28uYXBwL3NwYWNlcy9wZWFjZWZ1bC1ldWxlci0xMjM0NTYiLCJwcml2YXRla2V5IjoiLS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tXG5NSUcyQWdFQU1CQUdCeXFHU000OUFnRUdCU3VCQkFBaUJJR2VNSUdiQWdFQkJEQmVobXRHR3J1VnlYTGpxdmtFXG5PYTJpZVp1Vlk0d0RiYU1tdEt5cjZzb2Z3OXArT1FLdlZ4RURHWDR3Y1kwb3dwOXJxazNhbFdpUnY5NTdWY1RuXG4xN2UzRk5leEZRNEtGdS9EczFjZEc1TGFPcnI1TmNQZ0YreXFZR1d1eDNHTE96VDJOdXlzN29VPVxuLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLVxuIiwiY2VydGlmaWNhdGUiOiItLS0tLUJFR0lOIENFUlRJRklDQVRFLS0tLS1cbk1JSUNWVENDQWR5Z0F3SUJBZ0lRT3pjcDFyNlNQUVlucm4vWnhObTFuakFLQmdncWhrak9QUVFEQXpCQU1UNHdcblBBWURWUVFLRXpVdkwyTmhjSFJoYVc0dVlYQnBMbTF2Ym1SdmJ5NWhjSEF2YzNCaFkyVnpMM0JsWVdObFpuVnNcbkxXVjFiR1Z5TFRZM056azBOVEFlRncweE9UQTRNREl5TURJeU1EWmFGdzB4T1RBNE1ETXlNREl5TURaYU1FQXhcblBqQThCZ05WQkFvVE5TOHZZMkZ3ZEdGcGJpNWhjR2t1Ylc5dVpHOXZMbUZ3Y0M5emNHRmpaWE12Y0dWaFkyVm1cblpXWjFiQzFsZFd4bGNpMDJOemM1TkRVdllXZGxiblJ6THpGUGMzSndTa2xoWVZodFFsWllXRmQyUzJvNFMwZ3hcblpVSjRTREFLQmdncWhrak9QUVFEQXdObkFEQmtBakJ3b3FyYlBHMWN1U1p5cHhHQnIySlZDYndLcjNzMDNqU3BcblVORzJmK3lDVmlhV29ZS3lNYjBtUzFrdi8rcTNodTBDTUdIRll4RGRmN05OekZnTmxYVnIxalk4clV4c2FQeXpcbk1PUE0zN3dYM09yVUh5RHFTZmNFWk4xT1ZwN1lOOTNod0E9PVxuLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLVxuIn0K
```


In you pipeline you can easily store the file with base64  decoding during every job via:

```
echo $MONDOO_AGENT_ACCOUNT | base64 -d > mondoo.json
```

## AWS CodeBuild

![Illustration of AWS CodePipeline integration](../assets/integration-aws-codepipeline.png)

The following example illustrates how to scan a Docker image before its being pushed to ECR. At first, we install the agent, then we scan the freshly built image by Docker. If `mondoo scan` passes successfully, the image is pushed ECR. Based on your pipeline configuration, you can auto-deploy it to ECS then.

```
# AWS CodeBuild buildspec.yml to build Docker Image
# Built a Docker Image, Scan it for security vulnerabilities using Mondoo and push it to ECR

# Set the following variables as CodeBuild Project Environment Variables
# ECR_REPOSITORY_URI
# MONDOO_AGENT_ACCOUNT

version: 0.2
phases:
  pre_build:
    commands:
      - echo Fetching ECR Login
      - ECR_LOGIN=$(aws ecr get-login --region $AWS_DEFAULT_REGION --no-include-email)
      - echo Logging in to Amazon ECR...
      - $ECR_LOGIN
      - IMAGE_TAG=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)

      - echo Configure Mondoo
      # for static analysis of rpm-based operating systems, mondoo requires a local rpm command
      # AWS uses Ubuntu as default
      - apt-get update && apt-get install -y rpm
      - echo $MONDOO_AGENT_ACCOUNT | base64 -d > mondoo.json
      - curl -sSL https://mondoo.io/download.sh | bash
      - ./mondoo version
  build:
    commands:
      - echo Build started on `date`  
      - echo Building the Docker image...
      - docker build -t $ECR_REPOSITORY_URI:latest .
      - docker tag $ECR_REPOSITORY_URI:latest $ECR_REPOSITORY_URI:$IMAGE_TAG
  post_build:
    commands:
      - bash -c "if [ /"$CODEBUILD_BUILD_SUCCEEDING/" == /"0/" ]; then exit 1; fi"
      - echo Build completed on `date`
      - echo Verify Docker images for vulnerabilities with Mondoo
      - ./mondoo scan -t docker://$ECR_REPOSITORY_URI:$IMAGE_TAG --config mondoo.json
      - echo Pushing the Docker images...
      - docker push $ECR_REPOSITORY_URI:latest
      - docker push $ECR_REPOSITORY_URI:$IMAGE_TAG
      - echo Writing image definitions file...
      - printf '[{"name":"dockerimage","imageUri":"%s"}]' $ECR_REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json
artifacts:
  files: imagedefinitions.json
``` 

Additionally, you need to configure your AWS CodeBuild project to store the credentials for the Mondoo agent in `MONDOO_AGENT_ACCOUNT`. You can [download the credentials](../agent/configuration). For AWS CodeBuild, you need to encode the [credentials as base64](#store-mondoo-credentials).

Next, you create a new `MONDOO_AGENT_ACCOUNT` variable and paste the content of the agent credentials:

![Paste the configuration in AWS CodeBuild environment variables](../assets/mondoo-cicd-awscodebuild-setup.png)

You can see the vulnerability report as part of the CI/CD job.

![Run a mondoo scan in AWS CodeBuild](../assets/mondoo-cicd-awscodebuild-result-text.png)

Also, it is easy to see the result in your Mondoo dashboard:

![See report in Mondoo dashboard](../assets/mondoo-cicd-awscodebuild-result-dashboard.png)

Note: We prefer to store the agent credentials as secrets. By default, AWS CodeBuild supports retrieving values for environment variables via plaintext and AWS Parameter Store. It also allows  the use of AWS Secrets Manager to pass secrets via [AWS Parameter Store into the pipeline](https://docs.aws.amazon.com/systems-manager/latest/userguide/integration-ps-secretsmanager.html). Please be aware that AWS Secrets Manager comes with  an additional cost per secret.

## Azure DevOps

![Illustration of Azure DevOps integration](../assets/integration-azure-devops.png)

To use Mondoo with Azure DevOps, you simply add another build step in `azure-pipelines.yml`. It is designed to block image push if vulnerabilities have been found. 

```
# Docker starter pipeline
#
# The script uses the following secrets:
# - dockerUser - Replace with your Docker ID for Docker Hub or the admin user name for the Azure Container Registry
# - dockerPassword - Password or Token
# - MONDOO_AGENT_ACCOUNT - Mondoo agent credentials

trigger:
- master

pool:
  vmImage: 'ubuntu-latest'

variables:
  # docker image namespace
  imageNamespace: my-docker-id
  # docker image name
  imageName: my-image-name


steps:
- task: DockerInstaller@0
  inputs:
    dockerVersion: '17.09.0-ce'

- script: |
    docker build -t $(imageNamespace)/$(imageName) .
  displayName: 'Build Docker image'

- script: |
    curl -sSL https://mondoo.io/download.sh | bash 
    echo ${MONDOO_AGENT_ACCOUNT} | base64 -d > mondoo.json
    ./mondoo scan -t docker://$(imageNamespace)/$(imageName) --config mondoo.json 
  displayName: 'Run mondoo vulnerability scan'
  env:
    MONDOO_AGENT_ACCOUNT: $(MONDOO_AGENT_ACCOUNT)

- script: |
    docker build -t $(imageNamespace)/$(imageName) .
    docker login -u $(dockerUser) -p $(pswd)
    docker push $(imageNamespace)/$(imageName)
  env:
    pswd: $(dockerPassword)
```

Additionally, you need to configure your build to store the credentials for the Mondoo agent in `MONDOO_AGENT_ACCOUNT`. You can [download the credentials](../agent/configuration). For Azure, you need to encode the [credentials as base64](#store-mondoo-credentials). Next, you create a new `MONDOO_AGENT_ACCOUNT` [Azure secret](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#secret-variables) and paste the content of the agent credentials:

![Open Azure secrets configuration](../assets/mondoo-cicd-azuredevops-setup1.png)
![Paste the configuration as Azure secret](../assets/mondoo-cicd-azuredevops-setup2.png)

Once configured, you can see the vulnerability report as part of the CI/CD job.

![Run a mondoo scan in Azure DevOps](../assets/mondoo-cicd-azuredevops-result-text.png)

## Circle CI

![Illustration of Circle CI integration](../assets/integration-circleci.png)

CircleCI allows you to build Docker images as part of your [CI/CD pipeline](https://circleci.com/docs/2.0/building-docker-images/). Mondoo can be easily used in combination to verify the docker image before yoou push it to the registry. The following configuration runs a `docker build` and a `mondoo scan`:


```
version: 2
jobs:
  build:
    docker:
      - image: centos:7
    steps:
      - setup_remote_docker
      - checkout
      # use a primary image that already has Docker (recommended)
      # or install it during a build like we do here
      - run:
          name: Install Docker client
          command: |
            set -x
            VER="18.09.3"
            curl -L -o /tmp/docker-$VER.tgz https://download.docker.com/linux/static/stable/x86_64/docker-$VER.tgz
            tar -xz -C /tmp -f /tmp/docker-$VER.tgz
            mv /tmp/docker/* /usr/bin
      - run:
          name: Install Mondoo agent
          command: |
            echo $MONDOO_AGENT_ACCOUNT > mondoo.json
            curl -sSL https://mondoo.io/download.sh | bash
            ./mondoo version
      # - run: docker login -u $DOCKER_USER -p $DOCKER_PASS
      - run: docker build -t yourorg/docker-image:0.1.$CIRCLE_BUILD_NUM .
      - run: ./mondoo scan -t docker://yourorg/docker-image:0.1.$CIRCLE_BUILD_NUM --config mondoo.json
      # - run: docker push docker://yourorg/docker-image:0.1.$CIRCLE_BUILD_NUM
```

Additionally, you need to configure your Circle CI project to store the credentials for the Mondoo agent in `MONDOO_AGENT_ACCOUNT`. You can either [download the credentials](../agent/configuration) or use the CircleCI integration page. Just select Sidebar -> Apps -> CircleCI and generate new credentials. Next, you create a new `MONDOO_AGENT_ACCOUNT` variable and paste the content of the agent credentials:

![Paste the configuration in Circle CI environment variables](../assets/mondoo-cicd-circleci-setup.png)

You can see the vulnerability report as part of the CI/CD job.

![Run a mondoo scan in Circle CI](../assets/mondoo-cicd-circleci-result-text.png)

Also, it is easy to see the result in your Mondoo dashboard:

![See report in Mondoo dashboard](../assets/mondoo-cicd-circleci-result-dashboard.png)

## GCP Cloud Build

![Illustration of GCP Cloud Build integration](../assets/integration-gcp-cloudbuild.png)

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

You need to configure a [substitution variable](https://cloud.google.com/cloud-build/docs/configuring-builds/substitute-variable-values) to store the credentials for the Mondoo agent in `_MONDOO_AGENT_ACCOUNT`. You can either [download the credentials](../agent/configuration) or use the GCP Cloud Build integration page. For GCP Code Build, you need to encode the [credentials as base64](#store-mondoo-credentials). Next, you create a new `_MONDOO_AGENT_ACCOUNT` variable and paste the content of the agent credentials:

![Paste the configuration as GCP substitution variable](../assets/mondoo-cicd-cloudbuild-setup.png)

You can see the vulnerability report as part of the CI/CD job.

![Run a mondoo scan in GCP Cloud Build](../assets/mondoo-cicd-cloudbuild-result-text.png)

## Gitlab

![Illustration of Gitlab CI integration](../assets/integration-gitlabci.png)

Since Gitlab makes heavy use of Docker containers as a runtime environment, it is the easiest to use Mondoo's docker image. It is very easy to add a vulnerability job in your `.gitlab-ci.yml`:

```yaml
# Build docker image
build-master:
  image: docker:latest
  stage: build
  services:
    - docker:dind
  before_script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY
  script:
    - docker build --pull -t "$CI_REGISTRY_IMAGE" .
    - docker push "$CI_REGISTRY_IMAGE"

  only:
    - master

# Scan docker image
vulnerabilities-master:
  stage: test
  image:
    name: mondoolabs/mondoo:latest
    entrypoint: [""]
  script:
    - mkdir -p /root/.docker/ && echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > /root/.docker/config.json
    - echo $MONDOO_AGENT_ACCOUNT > /tmp/$CI_PIPELINE_ID-mondoo.json
    - mondoo scan -t docker://$CI_REGISTRY_IMAGE --config /tmp/$CI_PIPELINE_ID-mondoo.json
  # allow_failure: true
  only:
    - master
  dependencies:
    - build-master
```

Additionally, you need to configure your Gitlab project to store the credentials for the Mondoo agent in `MONDOO_AGENT_ACCOUNT`. You can either [download the credentials](../agent/configuration) or use the Gitlab integration page. Just select Sidebar -> Apps -> Gitlab and generate new credentials:
 
![Generate Gitlab agent credentials in Mondoo](../assets/mondoo-cicd-gitlab-config-token.png)

Next, you create a new `MONDOO_AGENT_ACCOUNT` variable and paste the content of the agent credentials:

![Paste the configuration in Gitlab CI environment variables](../assets/mondoo-cicd-gitlab-config.png)

You can see the vulnerability report as part of the CI/CD job.

![Run a mondoo scan in Gitlab](../assets/mondoo-cicd-gitlab-result-text.png)

Also, it is easy to see the result in your Mondoo dashboard:

![See report in Mondoo dashboard](../assets/mondoo-cicd-gitlab-result-dashboard.png)