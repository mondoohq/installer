# Installing Mondoo Agent via cloud-init

Most Cloud environments support the configuration of an operating system during launch. In most cases [cloud-init](https://cloudinit.readthedocs.io/en/latest/) is used. For Linux systems, cloud-init supports bash scripts.

We simply leverage the Mondoo [Bash installer script](./bash) for cloud-init. To deploy agents with cloud-init, get an registration token via [Mondoo Dashboard](https://mondoo.app/) -> Select Space -> Agents -> New Agent (➕Icon in action menu) and paste it into the following snippet:

```
#!/bin/bash
export MONDOO_REGISTRATION_TOKEN='ey..gg'
curl -sSL https://mondoo.io/install.sh | bash
```

Once the machine in ready, the first scan will be performed about 30 seconds after the machine booted up.

## Examples

### AWS EC2 Instance User Data

1. Save the snippet shown above to `mondoo-cloudinit.sh` and paste in your registration token:

```
cat > mondoo-cloudinit.sh << EOF
#!/bin/bash
export MONDOO_REGISTRATION_TOKEN='eyJhbG..bn'
curl -sSL https://mondoo.io/install.sh | bash
EOF
```

2. Launch a new instance

```
# Note: you need to adapt the image-id, security-group-ids, key-name to your region and account
aws ec2 run-instances --region us-east-1 --image-id  ami-0ad82a384c06c911e --security-group-ids sg-903004f8 --count 1 --instance-type t2.micro --key-name chris-rock --user-data file://mondoo-cloudinit.sh
```

![Installing Mondoo Agent via cloudinit](../static/videos/mondoo-ec2-cloudinit-cli.gif)

You can see the results of the vulnerability scan in your Mondoo dashboard once the installation is complete:

![See agent in dashboard](../../assets/mondoo-ec2-cloudinit-cli.png)

Once the machine is up and running, it will report vulnerabilities to Mondoo automatically. Further documentation for the AWS CLI is available at [Launch, List, and Terminate Amazon EC2 Instances](https://docs.aws.amazon.com/cli/latest/userguide/cli-services-ec2-instances.html) and [Running Commands on Your Linux Instance at Launch](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)

In case of troubleshooting, have a look at the `/var/log/cloud-init-output.log` to see the cloudinit run output.
