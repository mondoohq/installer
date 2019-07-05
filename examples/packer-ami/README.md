# Build an AMI Image with Packer & Mondoo Vulnerability Scan

This example assumes you have basic knowledge Packer and AWS. If you are unfamiliar with Packer, have a look at their great [tutorials](https://www.packer.io/intro/getting-started/build-image.html).

## Preconditions

 * [AWS Account](https://aws.amazon.com/free/)
 * [Packer CLI installed on workstation](https://www.packer.io/intro/getting-started/install.html)
 * [Mondoo CLI installed on workstation](https://mondoo.io/docs/agent/installation)


## Build your image

Verify the packer configuration:

```
$ packer validate example.json
Template validated successfully.
```

Set AWS credentials as environment variable:

```
export AWS_ACCESS_KEY_ID=MYACCESSKEYID
export AWS_SECRET_ACCESS_KEY=MYSECRETACCESSKEY
```

Run packer build:

```
$ packer build example.json

amazon-ebs output will be in this color.
==> amazon-ebs: Prevalidating AMI Name: mondoo-example 1562326441
    amazon-ebs: Found Image ID: ami-0cfee17793b08a293
==> amazon-ebs: Creating temporary keypair: packer_5d1f35a9-bf28-ad76-be7b-a7d1ba0b1a28
==> amazon-ebs: Creating temporary security group for this instance: packer_5d1f35ad-5e30-7a62-7142-05d3371896a9
==> amazon-ebs: Authorizing access to port 22 from [0.0.0.0/0] in the temporary security groups...
==> amazon-ebs: Launching a source AWS instance...
==> amazon-ebs: Adding tags to source instance
    amazon-ebs: Adding tag: "Name": "Packer Builder"
    amazon-ebs: Instance ID: i-077464c074ab682fe
==> amazon-ebs: Waiting for instance (i-077464c074ab682fe) to become ready...
==> amazon-ebs: Using ssh communicator to connect: 54.234.154.92
==> amazon-ebs: Waiting for SSH to become available...
==> amazon-ebs: Connected to SSH!
==> amazon-ebs: Provisioning with shell script: /var/folders/wb/1643zzzx3xn8sdnn0fph19_r0000gn/T/packer-shell496967260
    amazon-ebs: total 28
    amazon-ebs: drwxr-xr-x 4 ubuntu ubuntu 4096 Jul  5 11:34 .
    amazon-ebs: drwxr-xr-x 3 root   root   4096 Jul  5 11:34 ..
    amazon-ebs: -rw-r--r-- 1 ubuntu ubuntu  220 Aug 31  2015 .bash_logout
    amazon-ebs: -rw-r--r-- 1 ubuntu ubuntu 3771 Aug 31  2015 .bashrc
    amazon-ebs: drwx------ 2 ubuntu ubuntu 4096 Jul  5 11:34 .cache
    amazon-ebs: -rw-r--r-- 1 ubuntu ubuntu  655 May  9 20:20 .profile
    amazon-ebs: drwx------ 2 ubuntu ubuntu 4096 Jul  5 11:34 .ssh
==> amazon-ebs: Running mondoo vulnerability scan...
==> amazon-ebs: Executing Mondoo: [mondoo vuln]
    amazon-ebs: Start vulnerability scan:
  →  detected automated runtime environment: Unknown CI
    amazon-ebs: 1:34PM INF ssh uses scp (beta) instead of sftp for file transfer transport=ssh
  →  verify platform access to ssh://chartmann@127.0.0.1:55661
  →  gather platform details................................
  →  detected ubuntu 16.04
  →  gather platform packages for vulnerability scan
  →  found 453 packages
    amazon-ebs:   →  analyse packages for vulnerabilities
    amazon-ebs: Advisory Report:
    amazon-ebs:   ■        PACKAGE                     INSTALLED               VULNERABLE (<)  ADVISORY
    amazon-ebs:   ■   9.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
    amazon-ebs:   ├─  9.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
    amazon-ebs:   ├─  8.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
    amazon-ebs:   ├─  8.1  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
    amazon-ebs:   ├─  7.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
    amazon-ebs:   ├─  7.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
    amazon-ebs:   ├─  7.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
    amazon-ebs:   ├─  7.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
    amazon-ebs:   ├─  7.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
    amazon-ebs:   ├─  7.8  linux-image-4.4.0-1087-aws  4.4.0-1087.98                           https://mondoo.app/advisories/
...
    amazon-ebs:   ■   0    liblzo2-2                   2.08-1.2                                https://mondoo.app/advisories/
    amazon-ebs:   ■   0    man-db                      2.7.5-1                                 https://mondoo.app/advisories/
    amazon-ebs:   ■   0    rsync                       3.1.1-3ubuntu1.2                        https://mondoo.app/advisories/
  →  ■ found 70 advisories: 2 critical, 14 high, 26 medium, 3 low, 25 none, 0 unknown
  →  report is available at https://mondoo.app/v/serene-dhawan-599345/focused-darwin-833545/reports/1NakGz6ysD1MzEGT8hRJ6wow6ZQ
==> amazon-ebs: Stopping the source instance...
    amazon-ebs: Stopping instance
==> amazon-ebs: Waiting for the instance to stop...
==> amazon-ebs: Creating AMI mondoo-example 1562326441 from instance i-077464c074ab682fe
    amazon-ebs: AMI: ami-0cb9729eaa3f53209
==> amazon-ebs: Waiting for AMI to become ready...
```