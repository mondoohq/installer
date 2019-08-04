# Scan DigitalOcean droplet for vulnerabilities with Terraform and Mondoo

This example provisions a new droplet via Terraform. In case you are not familiar with both Terraform and Digitalocean, have a look at their [guide](https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean). The provided Terraform configuration will spin up a new Ubuntu droplet, install Nginx, and run Mondoo to assess the vulnerabilities of the instance. 

Note: This example is tested with [Terraform 0.12](https://www.terraform.io/upgrade-guides/0-12.html) and may not work with earlier versions.

## Preconditions

 * [DigitalOcean Account](https://www.digitalocean.com/)
 * [Terraform CLI installed on workstation](https://learn.hashicorp.com/terraform/getting-started/install.html)
 * [Mondoo CLI installed on workstation](https://mondoo.io/docs/agent/installation)
 * [Mondoo Terraform Provisioner](https://mondoo.io/docs/apps/terraform)

## Build Infrastructure

Verify that everything is in place for the infrastructure:

```
$ terraform init
```

Now, since all the tooling is ready, let's plan the build. Terraform will ask you for your ssh fingerprint. Mondoo will use reuse the configured SSH keys automatically. You can find your ssh key fingerprint in [DigitalOcean dashboard](https://cloud.digitalocean.com/account/securitys).

```
$ terraform plan                                                                            
var.ssh_fingerprint
  Enter a value: 5e:f8:07:77:14:db:ab:73:b5:62:69:79:66:04:8e:86

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.


------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # digitalocean_droplet.mywebserver will be created
  + resource "digitalocean_droplet" "mywebserver" {
      + backups              = true
      + disk                 = (known after apply)
      + id                   = (known after apply)
      + image                = "ubuntu-18-04-x64"
      + ipv4_address         = (known after apply)
      + ipv4_address_private = (known after apply)
      + ipv6                 = true
      + ipv6_address         = (known after apply)
      + ipv6_address_private = (known after apply)
      + locked               = (known after apply)
      + memory               = (known after apply)
      + monitoring           = false
      + name                 = "sample-tf-droplet"
      + price_hourly         = (known after apply)
      + price_monthly        = (known after apply)
      + private_networking   = true
      + region               = "nyc1"
      + resize_disk          = true
      + size                 = "s-1vcpu-1gb"
      + ssh_keys             = [
          + "5e:f8:07:77:14:db:ab:73:b5:62:69:79:66:04:8e:86",
        ]
      + status               = (known after apply)
      + urn                  = (known after apply)
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```

Now, we are ready to deploy the infrastructure:


```
terraform apply 

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # digitalocean_droplet.mywebserver will be created
  + resource "digitalocean_droplet" "mywebserver" {
      + backups              = true
      + disk                 = (known after apply)
      + id                   = (known after apply)
      + image                = "ubuntu-18-04-x64"
      + ipv4_address         = (known after apply)
      + ipv4_address_private = (known after apply)
      + ipv6                 = true
      + ipv6_address         = (known after apply)
      + ipv6_address_private = (known after apply)
      + locked               = (known after apply)
      + memory               = (known after apply)
      + monitoring           = false
      + name                 = "sample-tf-droplet"
      + price_hourly         = (known after apply)
      + price_monthly        = (known after apply)
      + private_networking   = true
      + region               = "nyc1"
      + resize_disk          = true
      + size                 = "s-1vcpu-1gb"
      + ssh_keys             = [
          + "5e:f8:07:77:14:db:ab:73:b5:62:69:79:66:04:8e:86",
        ]
      + status               = (known after apply)
      + urn                  = (known after apply)
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

digitalocean_droplet.mywebserver: Creating...
digitalocean_droplet.mywebserver: Provisioning with 'remote-exec'...
digitalocean_droplet.mywebserver (remote-exec): Connecting to remote host via SSH...
digitalocean_droplet.mywebserver (remote-exec):   Host: 67.207.85.146
digitalocean_droplet.mywebserver (remote-exec):   User: root
digitalocean_droplet.mywebserver (remote-exec):   Password: false
digitalocean_droplet.mywebserver (remote-exec):   Private key: false
digitalocean_droplet.mywebserver (remote-exec):   Certificate: false
digitalocean_droplet.mywebserver (remote-exec):   SSH Agent: true
digitalocean_droplet.mywebserver (remote-exec):   Checking Host Key: false
digitalocean_droplet.mywebserver (remote-exec): Connected!
...
digitalocean_droplet.mywebserver (mondoo):   →  found 525 packages
digitalocean_droplet.mywebserver (mondoo):   →  analyse packages for vulnerabilities
digitalocean_droplet.mywebserver (mondoo): Advisory Report:
digitalocean_droplet.mywebserver (mondoo):   ■        PACKAGE          INSTALLED            VULNERABLE (<)  ADVISORY
digitalocean_droplet.mywebserver (mondoo):   ■   7.8  bash-completion  1:2.8-1ubuntu1                       https://mondoo.app/advisories/
digitalocean_droplet.mywebserver (mondoo):   ■   7.5  patch            2.7.6-2ubuntu1                       https://mondoo.app/advisories/
digitalocean_droplet.mywebserver (mondoo):   ■   6.5  libxdmcp6        1:1.1.2-3                            https://mondoo.app/advisories/
digitalocean_droplet.mywebserver (mondoo):   ■   5.9  libgcrypt20      1.8.1-4ubuntu1.1                     https://mondoo.app/advisories/
digitalocean_droplet.mywebserver (mondoo):   ■   5.5  cron             3.0pl1-128.1ubuntu1                  https://mondoo.app/advisories/
digitalocean_droplet.mywebserver (mondoo):   ├─  5.5  cron             3.0pl1-128.1ubuntu1                  https://mondoo.app/advisories/
digitalocean_droplet.mywebserver (mondoo):   ├─  5.5  cron             3.0pl1-128.1ubuntu1                  https://mondoo.app/advisories/
digitalocean_droplet.mywebserver (mondoo):   ╰─  0    cron             3.0pl1-128.1ubuntu1                  https://mondoo.app/advisories/
digitalocean_droplet.mywebserver (mondoo):   ■   5.5  tcpdump          4.9.2-3                              https://mondoo.app/advisories/
digitalocean_droplet.mywebserver (mondoo):   ╰─  0    tcpdump          4.9.2-3                              https://mondoo.app/advisories/
digitalocean_droplet.mywebserver (mondoo):   ■   3.3  xdg-user-dirs    0.17-1ubuntu1                        https://mondoo.app/advisories/
digitalocean_droplet.mywebserver (mondoo):   ■   0    bsdmainutils     11.1.2ubuntu1                        https://mondoo.app/advisories/
digitalocean_droplet.mywebserver (mondoo):   ■   0    byobu            5.125-0ubuntu1                       https://mondoo.app/advisories/
digitalocean_droplet.mywebserver (mondoo):   ■   0    coreutils        8.28-1ubuntu1                        https://mondoo.app/advisories/
digitalocean_droplet.mywebserver (mondoo):   ╰─  0    coreutils        8.28-1ubuntu1                        https://mondoo.app/advisories/
digitalocean_droplet.mywebserver (mondoo):   ■   0    liblzo2-2        2.08-1.2                             https://mondoo.app/advisories/
digitalocean_droplet.mywebserver (mondoo):   ■   0    rsync            3.1.2-2.1ubuntu1                     https://mondoo.app/advisories/
digitalocean_droplet.mywebserver (mondoo):   →  ■ found 17 advisories: 0 critical, 2 high, 6 medium, 1 low, 8 none, 0 unknown
digitalocean_droplet.mywebserver (mondoo):   →  report is available at https://mondoo.app/v/serene-dhawan-599345/focused-darwin-833545/reports/1NbXHx7GVaKCNFHc2rymog4ZsML

digitalocean_droplet.mywebserver: Creation complete after 1m48s [id=149924385]

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

Outputs:

name = sample-tf-droplet
public_ip = 67.207.94.130
```

At the end of the Terraform output, you see the vulnerability report for the provisioned droplet.