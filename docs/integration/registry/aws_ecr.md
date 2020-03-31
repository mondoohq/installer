# Amazon Elastic Container Registry (ECR)

The [Amazon Elastic Container Registry](https://aws.amazon.com/ecr/) allows you to store container images within AWS. To get familiar with the AWS container registry, follow their [Get Started Guide](https://aws.amazon.com/ecr/getting-started/).

![Mondoo AWS Elastic Container Registry scan from CLI](../../assets/videos/aws-ec2-scan.gif)

## Precondition

Ensure you have your AWS credentials configured properly:

```bash
$ cat ~/.aws/credentials
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[mondoo]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

If you want to use a specific profile, set `AWS_PROFILE`

```bash
$ export AWS_PROFILE=mondoo
```

You can also set the region:

```bash
$ export AWS_REGION=us-east-1 
```

The [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) ships with an easy way to login to your ECR container registry:

```bash
$ aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123101453137.dkr.ecr.us-east-1.amazonaws.com
Login Succeeded
```

## Scan

After we completed the login, `mondoo` is ready to scan the registry:

```bash
$ mondoo scan -t cr://123101453137.dkr.ecr.us-east-1.amazonaws.com
  →  loaded configuration from /Users/chris-rock/.mondoo.yml
Start the vulnerability scan:
  →  resolve asset connections
  →  verify platform access to e5dd9dbb37df
  →  gather platform details
  →  detected ubuntu 18.04
  →  gather platform packages for vulnerability scan
  →  found 89 packages
  ✔  completed analysis for e5dd9dbb37df
  →  verify platform access to 61844ceb1dd5
  →  gather platform details
  →  detected ubuntu 19.04
  →  gather platform packages for vulnerability scan
  →  found 89 packages
  ✔  completed analysis for 61844ceb1dd5
Advisory Reports Overview
  ■  SCORE  NAME          SCORE       
  ■  0.0    e5dd9dbb37df  ══════════  
  ■  0.0    61844ceb1dd5  ══════════  
```