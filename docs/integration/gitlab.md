## Gitlab

Via manual installation:

```
vulnerabilities:
  stage: security
  image:
    name: centos:latest
  before_script:
    - curl --silent --location https://releases.mondoo.io/rpm/mondoo.repo | tee /etc/yum.repos.d/mondoo.repo
    - yum install -y mondoo
  script:
    - mkdir -p /root/.docker/ && echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > /root/.docker/config.json
    - mondoo vuls -t docker://$CI_REGISTRY_IMAGE/mondoo:$CI_COMMIT_SHORT_SHA
  allow_failure: true
```

Via docker container

```
vuln-docker:
  stage: security
  image:
    name: mondoolabs/mondoo:latest
  script:
    - mkdir -p /root/.docker/ && echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > /root/.docker/config.json
    - mondoo vuls -t docker://$CI_REGISTRY_IMAGE/mondoo:$CI_COMMIT_SHORT_SHA
    - mondoo vuls -t docker://index.docker.io/library/ubuntu:18.04
  allow_failure: true
```
