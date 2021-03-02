# Scan DigitalOcean droplet with Terraform and Mondoo

This example provisions a new DigitalOcean droplet via Terraform. In case you are not familiar with both Terraform and Digitalocean, have a look at their [guide](https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean). The provided Terraform configuration will spin up a new Ubuntu droplet, install Nginx, and run Mondoo to assess the vulnerabilities of the instance. 

Note: This example is tested with Terraform 0.14.7 and may not work with earlier versions.

## Preconditions

 * [DigitalOcean Account](https://www.digitalocean.com/)
 * [Terraform CLI installed on workstation](https://learn.hashicorp.com/terraform/getting-started/install.html)
 * [Mondoo CLI installed on workstation](https://mondoo.io/docs/agent/installation)

## Build Infrastructure

Verify that everything is in place for the infrastructure:

```bash
# check mondoo installation is okay
$ mondoo status

# check that terraform is okay
$ terraform init
```

Now, since all the tooling is ready, let's plan the build. Terraform will ask you for your ssh fingerprint. Mondoo will use reuse the configured SSH keys automatically. You can find your ssh key fingerprint in [DigitalOcean dashboard](https://cloud.digitalocean.com/account/securitys).

```bash
# set token for DigitalOcean
export DIGITALOCEAN_TOKEN=d1...ef
# run terraform
terraform apply -var do_token=$DIGITALOCEAN_TOKEN
```

You will see tarraform running the `remote-exec` provisioner to install nginx and the `local-exec` to run the mondoo scan

```
digitalocean_droplet.mywebserver (remote-exec): Processing triggers for ureadahead (0.100.0-21) ...
digitalocean_droplet.mywebserver (remote-exec): Processing triggers for libc-bin (2.27-3ubuntu1.2) ...
digitalocean_droplet.mywebserver: Provisioning with 'local-exec'...
digitalocean_droplet.mywebserver (local-exec): Executing: ["/bin/sh" "-c" "mondoo scan -t ssh://root@68.183.132.197 -i ~/.ssh/id_rsa --insecure --exit-0-on-success"]
digitalocean_droplet.mywebserver (local-exec): → loaded configuration from /Users/chris-rock/.mondoo.yml
digitalocean_droplet.mywebserver (local-exec):                         .-.
digitalocean_droplet.mywebserver (local-exec):                         : :
digitalocean_droplet.mywebserver (local-exec): ,-.,-.,-. .--. ,-.,-. .-' : .--.  .--.
digitalocean_droplet.mywebserver (local-exec): : ,. ,. :' .; :: ,. :' .; :' .; :' .; :
digitalocean_droplet.mywebserver (local-exec): :_;:_;:_;`.__.':_;:_;`.__.'`.__.'`.__.'

digitalocean_droplet.mywebserver (local-exec): → resolve assets
digitalocean_droplet.mywebserver (local-exec): → discover related assets for 1 assets
digitalocean_droplet.mywebserver (local-exec): → resolved 1 assets
digitalocean_droplet.mywebserver (local-exec): → execute policies
digitalocean_droplet.mywebserver (local-exec): → establish connection to asset 68.183.132.197 (baremetal)
digitalocean_droplet.mywebserver: Still creating... [1m30s elapsed]
digitalocean_droplet.mywebserver (local-exec): → verify platform access to 68.183.132.197
digitalocean_droplet.mywebserver (local-exec): → gather platform details build= platform=ubuntu release=18.04
digitalocean_droplet.mywebserver (local-exec): → synchronize asset name=sample-tf-droplet
digitalocean_droplet.mywebserver (local-exec): → run policies for asset asset=//assets.api.mondoo.app/spaces/upbeat-haslett-916671/assets/1pDgwHoLlLu6bV4I99cQTvZCR24
digitalocean_droplet.mywebserver: Still creating... [1m40s elapsed]
digitalocean_droplet.mywebserver: Still creating... [1m50s elapsed]
digitalocean_droplet.mywebserver: Still creating... [2m0s elapsed]
digitalocean_droplet.mywebserver: Still creating... [2m10s elapsed]
```

At the end of the Terraform output, you see the report for the provisioned droplet. You can destroy the droplet via:

```bash
# destroy the droplet
terraform destroy -var do_token=$DIGITALOCEAN_TOKEN
```