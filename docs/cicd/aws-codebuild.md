## AWS CodeBuild

![Illustration of AWS CodePipeline integration](./assets/integration-aws-codepipeline.png)

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

Additionally, you need to configure your AWS CodeBuild project to store the credentials for the Mondoo agent in `MONDOO_AGENT_ACCOUNT`. You can [download the credentials](../../agent/installation/registration). For AWS CodeBuild, you need to encode the [credentials as base64](#store-mondoo-credentials).

Next, you create a new `MONDOO_AGENT_ACCOUNT` variable and paste the content of the agent credentials:

![Paste the configuration in AWS CodeBuild environment variables](./assets/mondoo-cicd-awscodebuild-setup.png)

You can see the vulnerability report as part of the CI/CD job.

![Run a mondoo scan in AWS CodeBuild](../assets/mondoo-cicd-awscodebuild-result-text.png)

Also, it is easy to see the result in your Mondoo dashboard:

![See report in Mondoo dashboard](./assets/mondoo-cicd-awscodebuild-result-dashboard.png)

Note: We prefer to store the agent credentials as secrets. By default, AWS CodeBuild supports retrieving values for environment variables via plaintext and AWS Parameter Store. It also allows  the use of AWS Secrets Manager to pass secrets via [AWS Parameter Store into the pipeline](https://docs.aws.amazon.com/systems-manager/latest/userguide/integration-ps-secretsmanager.html). Please be aware that AWS Secrets Manager comes with  an additional cost per secret.