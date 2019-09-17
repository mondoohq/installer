## Circle CI

![Illustration of Circle CI integration](../../assets/integration-circleci.png)

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

![Paste the configuration in Circle CI environment variables](../../assets/mondoo-cicd-circleci-setup.png)

You can see the vulnerability report as part of the CI/CD job.

![Run a mondoo scan in Circle CI](../../assets/mondoo-cicd-circleci-result-text.png)

Also, it is easy to see the result in your Mondoo dashboard:

![See report in Mondoo dashboard](../../assets/mondoo-cicd-circleci-result-dashboard.png)