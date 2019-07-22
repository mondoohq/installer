# Mondoo Packer Provisioner

Mondoo ships an integration for [Packer](https://www.packer.io) to ease the assessment of vulnerabilities during an image build process. The integration is open source and available in our [Mondoo github repository](https://github.com/mondoolabs/mondoo)

## Install Mondoo Packer Provisioner

The Mondoo Packer Provisioner depends on:

  * [Packer CLI installed on workstation](https://www.packer.io/intro/getting-started/install.html)
  * [Mondoo CLI installed on workstation](../agent/installation)

The provisioner plugin may be installed via:

  * Precompiled binary (recommended)
  * From Source (advanced)

### Install packer plugin from binary

To install the pre-compiled binary, download the appropriate package from [Github](https://github.com/mondoolabs/mondoo/releases/latest) and place the binary in the Packer's plugin directory `~/.packer.d/plugins` (Linux, Mac) or `%USERPROFILE%/packer.d/plugins` (Windows). Other locations that Packer searches for are [documented on their website](https://www.packer.io/docs/extending/plugins.html#installing-plugins).

The following simplifies the installation:

**Linux**

```
mkdir -p ~/.packer.d/plugins
cd ~/.packer.d/plugins
curl https://github.com/mondoolabs/mondoo/releases/0.3.0/latest/packer-provisioner-mondoo_0.3.0_linux_amd64.tar.gz | tar -xz > packer-provisioner-mondoo
chmod +x packer-provisioner-mondoo
```

**Mac**

```
mkdir -p ~/.packer.d/plugins
cd ~/.packer.d/plugins
curl https://github.com/mondoolabs/mondoo/releases/0.3.0/latest/packer-provisioner-mondoo_0.3.0_darwin_amd64.tar.gz | tar -xz > packer-provisioner-mondoo
chmod +x packer-provisioner-mondoo
```

### Compiling the Packer plugin from source

If you wish to compile from source, you need to have [Go](https://golang.org/) installed and configured.

1. Clone the mondoo repository from GitHub into your $GOPATH:

```
$ mkdir -p $(go env GOPATH)/src/github.com/mondoolabs && cd $_
$ git clone https://github.com/mondoolabs/mondoo.git
$ cd mondoo/packer-provisioner-mondoo
```

2. Build the plugin for your current system and place the binary in the packer plugin directory

```
make install
```

### Verifying the Installation 

After installing Packer, Mondoo Agent and the Mondoo Packer Provisioning Plugin run the follow commands to check that everything is configured properly:

```
$  packer
Usage: packer [--version] [--help] <command> [<args>]

Available commands are:
    build       build image(s) from template
    console     check that a template is valid
    fix         fixes templates from old versions of packer
    inspect     see components of a template
    validate    check that a template is valid
    version     Prints the Packer version

$ mondoo status
  →  mondoo cloud: https://api.mondoo.app
  →  space: //captain.api.mondoo.app/spaces/focused-darwin-833545
  →  agent is registered
  ✔  agent //agents.api.mondoo.app/spaces/focused-darwin-833545/agents/1NairOj7L1Gi7BMQqPbBO4LAQ2v authenticated successfully
```

If you get an error, ensure the tools are properly configured for your system path.

## Basic Example

The following example is fully functional and builds and scans an image on DigitalOcean.

```
{
  "provisioners": [
    {
      "type": "mondoo"
    }
  ],

  "builders": [
    {
      "type": "digitalocean",
      "api_token": "DIGITALOCEAN_TOKEN",
      "image": "ubuntu-18-04-x64",
      "ssh_username": "root", 
      "region": "nyc1",
      "size": "s-4vcpu-8gb"
    }
  ]
}
```

Replace the `api_token` with your own and run `packer`

```
packer build do-ubuntu.json
```

## Mondoo Packer Provisioner Configuration Reference

Required Parameters:

  * none

Optional Parameters:

  * `on_failure` (string) - If on_failure is set to `continue` the build continues even if vulnerabilities have been found
  
  ```
  "on_failure": "continue",
  ```

  * `labels` (map of string) - Custom labels can be passed to mondoo. This eases searching for the correct asset report later.

```
"labels": {
  "mondoo.app/ami-name":  "{{user `ami_name`}}",
  "name":"Packer Builder",
  "custom_key":"custom_value"
}
```

Debugging:

To debug the mondoo scan, set the `debug` variable:

```
{
  "type": "mondoo",
  "debug": true
}
```

## AWS AMI Image Build and Scan Example

This example illustrates the combination of Packer & Mondoo to build an AMI image. The source for this example is available on [Github](https://github.com/mondoolabs/mondoo/tree/master/examples/packer-aws). Further examples are available in our [GitHub repo](https://github.com/mondoolabs/mondoo/tree/master/examples), eg. for [DigitalOcean](https://github.com/mondoolabs/mondoo/tree/master/examples/packer-digitalocean).

***Packer Template***

The following packer templates is a simple example that builds on top of the official Ubuntu image, runs a shell provisioner and a mondoo vulnerability scan.

```json
{
  "variables": {
    "aws_access_key": "{{env `AWS_ACCESS_KEY_ID`}}",
    "aws_secret_key": "{{env `AWS_SECRET_ACCESS_KEY`}}",
    "ami_name": "mondoo-example {{timestamp}}"
  },
  "builders": [{
    "type": "amazon-ebs",
    "access_key": "{{user `aws_access_key`}}",
    "secret_key": "{{user `aws_secret_key`}}",
    "region": "us-east-1",
    "source_ami_filter": {
      "filters": {
        "virtualization-type": "hvm",
        "name": "ubuntu/images/*ubuntu-xenial-16.04-amd64-server-*",
        "root-device-type": "ebs"
      },
      "owners": ["099720109477"],
      "most_recent": true
    },
    "instance_type": "t2.micro",
    "ssh_username": "ubuntu",
    "ami_name": "{{user `ami_name`}}"
  }],
  "provisioners": [
    {
      "type": "shell",
      "inline":[
          "ls -al /home/ubuntu"
      ]
    },
    {
      "type": "mondoo",
      "on_failure": "continue",
      "labels": {
        "mondoo.app/ami-name":  "{{user `ami_name`}}",
        "name":"Packer Builder",
        "custom_key":"custom_value"
      }
    }
  ]
}
```

The simplest configuration for mondoo would be:

```
{
  "type": "mondoo"
}
```

The additional `on_failure` allows Packer to continue, even if mondoo found vulnerabilities. Additional labels help you to identify the ami report in mondoo later. To verify the the packer template, run packer `packer validate`:

```
$ packer validate example.json
Template validated successfully.
```

***Packer Build***

Once the packer template is verified, we are ready to build the image. In this case, we are going to build an AMI, therefore we need the the AWS credentials to spin up a new instance. As shown above, the same will work with other cloud providers or Vagrant.

Now, set the AWS credentials

```
export AWS_ACCESS_KEY_ID=MYACCESSKEYID
export AWS_SECRET_ACCESS_KEY=MYSECRETACCESSKEY
```

and start the packer build:

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
  →  ■ found 70 advisories: 2 critical, 14 high, 26 medium, 3 low, 25 none, 0 unknown
  →  report is available at https://mondoo.app/v/serene-dhawan-599345/focused-darwin-833545/reports/1NakGz6ysD1MzEGT8hRJ6wow6ZQ
==> amazon-ebs: Stopping the source instance...
    amazon-ebs: Stopping instance
==> amazon-ebs: Waiting for the instance to stop...
==> amazon-ebs: Creating AMI mondoo-example 1562326441 from instance i-077464c074ab682fe
    amazon-ebs: AMI: ami-0cb9729eaa3f53209
==> amazon-ebs: Waiting for AMI to become ready...
```

As we see as the result, the mondoo scan found vulnerabilities but passed the build.

## Uninstall

You can easily uninstall the provisioner by removing the binary.

```
# linux & mac
rm ~/.packer.d/plugins/packer-provisioner-mondoo
```