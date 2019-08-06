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

1. Save the snippet shown above to `mondoo-cloudinit.sh`

```
cat > mondoo-cloudinit.sh << EOF
#!/bin/bash
export MONDOO_REGISTRATION_TOKEN='eyJhbGciOiJFUzM4NCIsImtpZCI6IiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsibW9uZG9vIl0sImV4cCI6MTU2NTEwMDgzMywiaWF0IjoxNTY1MTAwNzczLCJpc3MiOiJtb25kb28vYW1zIiwibmJmIjoxNTY1MTAwNzczLCJzcGFjZSI6Ii8vY2FwdGFpbi5hcGkubW9uZG9vLmFwcC9zcGFjZXMvcm9tYW50aWMtc2FoYS00NTc2MTciLCJzdWIiOiJhZ2VudCJ9.91QldQc9HEj_gj45bPJ-Ye5XaMFKwa53xEEnX1TsOhDtJXEI8joMedwbVhfqDm-eaeHVaVMkAEBjs65VCDSe51QyjKVUpqygRYq1z-SxqhCs9otNR2DGSSz7Wu-LAubn'
curl -sSL https://mondoo.io/install.sh | bash
EOF
```

2. Launch a new instance

```
aws ec2 run-instances --region us-east-1 --image-id  ami-0ad82a384c06c911e --security-group-ids sg-903004f8 --count 1 --instance-type t2.micro --key-name chris-rock --user-data file://mondoo-cloudinit.sh 
```

Once the machine is up and running, it will report vulnerabilities to Mondoo automatically. Further documentation for the AWS CLI is available at [Launch, List, and Terminate Amazon EC2 Instances](https://docs.aws.amazon.com/cli/latest/userguide/cli-services-ec2-instances.html) and [Running Commands on Your Linux Instance at Launch](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)

In case of troubleshooting, have a look at the `/var/log/cloud-init-output.log` to see the cloudinit run output.


<img src="../assets/mondoo-ec2-cloudinit-cli.png">

