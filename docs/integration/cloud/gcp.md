# GCP Integration

Mondoo offers a wide range of choices to collect risk information about workload running in your Google Cloud Platform account:

**Gather vulnerability information during build-time**

 - [Risk assessment in GCP CloudBuild](../cicd/gcp-cloudbuild#gcp-cloudbuild)
 - [Risk assessment for GCP Container Registry](../registry/gcp_gcr#google-cloud-container-registry)
 - [Build AMIs with Packer](../devops/packer)
 - [Test Docker Images in GCP Cloudbuild](../cicd/gcp-cloudbuild)

**Gather vulnerability information during run-time**

  - [Scan GCP compute instances from your workstation](#scan-from-workstation)
  - [Install mondoo agent via CloudInit](../../agent/installation/cloudinit)
  - [Terraform deployment](../devops/terraform)
  - [Verify instances managed by Chef/AWS OpsWorks](../../agent/installation/chef)
  - [Verify instances managed by Ansible](../../agent/installation/ansible)

## Scan from Workstation

Install the [gcloud](https://cloud.google.com/sdk/install) CLI and [login](https://cloud.google.com/sdk/gcloud/reference/auth/login) via `gcloud auth login`. Then set your project:

```bash
$ gcloud config set project <projectID>
Updated property [core/project].
```

Now, you can [list all running instances](https://cloud.google.com/sdk/gcloud/reference/compute/instances/list) via:

```bash
gcloud compute instances list
```

Mondoo uses the instance information from GCP and tries to connect via SSH to each instance. Make sure you are able to connect to all instances via SSH. e.g. use [SSH keys in metadata](https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys)

![Mondoo GCP instances scan from CLI](../../assets/videos/gcp-compute-scan.gif)

Once, the ssh key is configured, run `mondoo scan`

```bash
# uses the default project with the ssh username chris
$ mondoo scan -t gcp://user/chris

# you can also scan a different project
$ mondoo scan -t gcp://project/mondoo-demo-1234/user/chris
```

> Note: mondoo uses `~/.ssh/config` to determine the users for each detected public IP

Instead of using the same login name for all instances, you can also configure the SSH config and add each individual instance with their username:

```bash
Host 123.123.123.123 
  User chris

Host yourdomain.com
  IdentityFile /your/path/keyname
````

If you require a specific list of instances with more detailed configuration, consider the use of an [Ansible inventory](../devops/ansible)
