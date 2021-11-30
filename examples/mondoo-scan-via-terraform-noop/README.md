# Terraform Example with Null Resource

This example is the simplest to demonstrate how to run `mondoo` in combination with the [local-exec](https://www.terraform.io/docs/language/resources/provisioners/local-exec.html) provisioner.

```
terraform init
TF_LOG=ERROR terraform apply -auto-approve -var conn=ssh -var user=chris -var host=34.72.165.42
```

```
9576975]
null_resource.example1: Destruction complete after 0s
null_resource.example1: Creating...
null_resource.example1: Provisioning with 'local-exec'...
null_resource.example1 (local-exec): Executing: ["/bin/sh" "-c" "mondoo scan -t ssh://chris@34.72.165.42 --password  --exit-0-on-success"]
null_resource.example1 (local-exec): → loaded configuration from /Users/chris-rock/.mondoo.yml
null_resource.example1 (local-exec):                         .-.
null_resource.example1 (local-exec):                         : :
null_resource.example1 (local-exec): ,-.,-.,-. .--. ,-.,-. .-' : .--.  .--.
null_resource.example1 (local-exec): : ,. ,. :' .; :: ,. :' .; :' .; :' .; :
null_resource.example1 (local-exec): :_;:_;:_;`.__.':_;:_;`.__.'`.__.'`.__.'

null_resource.example1 (local-exec): → resolve assets
null_resource.example1 (local-exec): → discover related assets for 1 assets
null_resource.example1 (local-exec): → resolved 1 assets
null_resource.example1 (local-exec): → execute policies
null_resource.example1 (local-exec): → establish connection to asset 34.72.165.42 (baremetal)
null_resource.example1 (local-exec): → verify platform access to 34.72.165.42
null_resource.example1 (local-exec): → gather platform details build= platform=sles release=12.5
null_resource.example1 (local-exec): → synchronize asset name=sles12
...
```