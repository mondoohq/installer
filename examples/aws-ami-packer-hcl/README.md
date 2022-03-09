# Build a secured AMI Image with Packer & Mondoo

This example assumes you have basic knowledge of Packer and AWS. If you are unfamiliar with Packer, have a look at their great [tutorials](https://www.packer.io/intro/getting-started/build-image.html).

## Preconditions

 * [AWS Account](https://aws.amazon.com/free/)
 * [Packer CLI installed on workstation](https://www.packer.io/intro/getting-started/install.html)
 * [Mondoo CLI installed on workstation](https://mondoo.com/docs/installation/)
 * [Mondoo Packer Provisioner](https://mondoo.com/docs/supplychain/packer/#install-mondoo-packer-provisioner)

Verify the Packer configuration:

```bash
$ packer validate amazon-linux.pkr.hcl
The configuration is valid.
```

Set AWS credentials as environment variable:

```bash
export AWS_ACCESS_KEY_ID=MYACCESSKEYID
export AWS_SECRET_ACCESS_KEY=MYSECRETACCESSKEY
export AWS_REGION=us-east-1 
```

Optional:

Instead of using the credentials directly, you can also configure profiles

```bash
export AWS_PROFILE=example-profile
export AWS_REGION=us-east-1 
```

## Build your AMI

Run: `packer build amazon-linux.pkr.hcl`:

```
$ packer build amazon-linux.pkr.hcl
amazon-ebs.example_build: output will be in this color.

==> amazon-ebs.example_build: Prevalidating any provided VPC information
==> amazon-ebs.example_build: Prevalidating AMI Name: aws-ami-example 20211128214800
    amazon-ebs.example_build: Found Image ID: ami-04902260ca3d33422
==> amazon-ebs.example_build: Creating temporary keypair: packer_61a3f910-3a5e-740b-b387-0a3410432431
==> amazon-ebs.example_build: Creating temporary security group for this instance: packer_61a3f914-d9e7-6372-f78b-bf8d5eb7033b
==> amazon-ebs.example_build: Authorizing access to port 22 from [0.0.0.0/0] in the temporary security groups...
==> amazon-ebs.example_build: Launching a source AWS instance...
==> amazon-ebs.example_build: Adding tags to source instance
    amazon-ebs.example_build: Adding tag: "Name": "Packer Builder"
    amazon-ebs.example_build: Instance ID: i-00d752596762cc260
==> amazon-ebs.example_build: Waiting for instance (i-00d752596762cc260) to become ready...
==> amazon-ebs.example_build: Using SSH communicator to connect: 3.85.29.85
==> amazon-ebs.example_build: Waiting for SSH to become available...
==> amazon-ebs.example_build: Connected to SSH!
==> amazon-ebs.example_build: Provisioning with shell script: /var/folders/rw/y7r077vs25l2d43bqjbhq_r80000gn/T/packer-shell3064642275
    amazon-ebs.example_build: total 12
    amazon-ebs.example_build: drwx------ 3 ec2-user ec2-user  74 Nov 28 21:48 .
    amazon-ebs.example_build: drwxr-xr-x 3 root     root      22 Nov 28 21:48 ..
    amazon-ebs.example_build: -rw-r--r-- 1 ec2-user ec2-user  18 Jul 15  2020 .bash_logout
    amazon-ebs.example_build: -rw-r--r-- 1 ec2-user ec2-user 193 Jul 15  2020 .bash_profile
    amazon-ebs.example_build: -rw-r--r-- 1 ec2-user ec2-user 231 Jul 15  2020 .bashrc
    amazon-ebs.example_build: drwx------ 2 ec2-user ec2-user  29 Nov 28 21:48 .ssh
==> amazon-ebs.example_build: Running mondoo (Version: 1.2.0, Build: 20d346a)
==> amazon-ebs.example_build: activated continue on detected issues
==> amazon-ebs.example_build: Executing Mondoo: [mondoo scan]
    amazon-ebs.example_build: → Mondoo 5.15.0 (Space: "//captain.api.mondoo.app/spaces/musing-saha-952142", Service Account: "1zDY7cJ7bA84JxxNBWDxBdui2xE", Managed Client: "1zDY7auR20SgrFfiGUT5qZWx6mE")
    amazon-ebs.example_build:                         .-.
    amazon-ebs.example_build: → loaded configuration from /Users/chris/.config/mondoo/mondoo.yml using source default
    amazon-ebs.example_build:                         : :
    amazon-ebs.example_build: ,-.,-.,-. .--. ,-.,-. .-' : .--.  .--. ™
    amazon-ebs.example_build: : ,. ,. :' .; :: ,. :' .; :' .; :' .; :
    amazon-ebs.example_build: :_;:_;:_;`.__.':_;:_;`.__.'`.__.'`.__.'
    amazon-ebs.example_build:
    amazon-ebs.example_build: → discover related assets for 1 asset(s)
    amazon-ebs.example_build: → resolved assets resolved-assets=1
    amazon-ebs.example_build: → execute policies
    amazon-ebs.example_build: → synchronize asset found=1
    amazon-ebs.example_build: → establish connection to asset ip-172-31-88-180.ec2.internal (unknown)
    amazon-ebs.example_build: → run policies for asset asset=//assets.api.mondoo.app/spaces/musing-saha-952142/assets/21Z6DNywHpBbXabgnQiegHAMpPq
    amazon-ebs.example_build: → marketplace> fetched policy bundle from upstream policy=//assets.api.mondoo.app/spaces/musing-saha-952142/assets/21Z6DNywHpBbXabgnQiegHAMpPq req-id=global
    amazon-ebs.example_build: ! collector.db> failed to store data, types don't match asset=//assets.api.mondoo.app/spaces/musing-saha-952142/assets/21Z6DNywHpBbXabgnQiegHAMpPq checksum=7h0FXwQzzUAyeN13/uCR0rNxlg9+Jg+iXneahnykG08xfxW6z+xwo6wUCfs6IcWZduIE1F06PDmfj7mwwTt9qA== data={"type":"\u001a\u0007\u0007"} expected=string received=map[string]string
    amazon-ebs.example_build: x executor.scoresheet> failed to store collected data error="failed to store data for '7h0FXwQzzUAyeN13/uCR0rNxlg9+Jg+iXneahnykG08xfxW6z+xwo6wUCfs6IcWZduIE1F06PDmfj7mwwTt9qA==', types don't match: expected string, got: map[string]string" asset=//assets.api.mondoo.app/spaces/musing-saha-952142/assets/21Z6DNywHpBbXabgnQiegHAMpPq
    amazon-ebs.example_build: → send all results asset=//assets.api.mondoo.app/spaces/musing-saha-952142/assets/21Z6DNywHpBbXabgnQiegHAMpPq
    amazon-ebs.example_build: → generate report asset=//assets.api.mondoo.app/spaces/musing-saha-952142/assets/21Z6DNywHpBbXabgnQiegHAMpPq
    amazon-ebs.example_build: → scan complete asset=//assets.api.mondoo.app/spaces/musing-saha-952142/assets/21Z6DNywHpBbXabgnQiegHAMpPq

    ...

    amazon-ebs.example_build: Summary
    amazon-ebs.example_build: =======
    amazon-ebs.example_build:
    amazon-ebs.example_build: Asset Overview
    amazon-ebs.example_build:
    amazon-ebs.example_build: ■  A-  ip-172-31-88-180.ec2.internal
    amazon-ebs.example_build:
    amazon-ebs.example_build: Aggregated Policy Overview
    amazon-ebs.example_build:
    amazon-ebs.example_build: CIS Amazon Linux 2 Benchmark - Level 1   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ B: 1
    amazon-ebs.example_build: Mondoo Platform Vulnerability Policy     ███████████████████████████████████████ A: 1
    amazon-ebs.example_build: CIS Distribution Independent Linux       ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ B: 1
    amazon-ebs.example_build: Benchmark Level 1 - Server Profile       ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    amazon-ebs.example_build:                                          ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    amazon-ebs.example_build: Mondoo Platform End-of-Life Policy       ███████████████████████████████████████ A: 1
    amazon-ebs.example_build: Mondoo Linux Security Baseline           ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ C: 1
    amazon-ebs.example_build:
==> amazon-ebs.example_build: Stopping the source instance...
    amazon-ebs.example_build: Stopping instance
==> amazon-ebs.example_build: Waiting for the instance to stop...
==> amazon-ebs.example_build: Creating AMI aws-ami-example 20211128214800 from instance i-00d752596762cc260
    amazon-ebs.example_build: AMI: ami-04bf9e7b4e288688c
==> amazon-ebs.example_build: Waiting for AMI to become ready...
==> amazon-ebs.example_build: Skipping Enable AMI deprecation...
==> amazon-ebs.example_build: Terminating the source AWS instance...
==> amazon-ebs.example_build: Cleaning up any extra volumes...
==> amazon-ebs.example_build: No volumes to clean up, skipping
==> amazon-ebs.example_build: Deleting temporary security group...
==> amazon-ebs.example_build: Deleting temporary keypair...
Build 'amazon-ebs.example_build' finished after 6 minutes 14 seconds.

```

At the end of the Packer build, Packer outputs the Mondoo assessment and the artifacts. The report is stored for future reference.