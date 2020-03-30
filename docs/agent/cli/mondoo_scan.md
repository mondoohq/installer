## mondoo scan

Scans an asset for known vulnerabilities

### Synopsis


This command triggers a vulnerability scan.

By default, the local system is scanned:

    $ mondoo scan

In addition, mondoo can scan assetes remotely via ssh. Mondoo uses the operating system 
ssh agent and ssh config as default to retrieve the credentials for the target.

    $ mondoo scan -t ssh://ec2-user@52.51.185.215
    $ mondoo scan -t ssh://ec2-user@52.51.185.215:2222

You can also access docker images located in docker registries:

    $ mondoo scan -t docker://ubuntu:latest
    $ mondoo scan -t docker://elastic/elasticsearch:7.2.0
    $ mondoo scan -t docker://gcr.io/google-containers/ubuntu:14.04
    $ mondoo scan -t docker://registry.access.redhat.com/ubi8/ubi

If docker is installed locally, containers and images can be also
be accessed via their id:

    $ mondoo scan -t docker://docker-image-id
    $ mondoo scan -t docker://docker-container-id

If you like to store the report locally, pipe the output into a file:

	$ mondoo scan --format yaml > myreport.yaml
	
Mondoo supports scanning EC2 instances via SSH. It will use your AWS configuration and your 
local SSH config to determine the required username for each individual EC2 instance:

	$ mondoo scan -t ec2://profile/name/region/us-east-1
	$ mondoo scan -t ec2://region/us-east-1
	$ mondoo scan -t ec2://user/ec2-user
	$ mondoo scan -t ec2://profile/mondoo-inc/region/us-east-1/user/ec2-user

To scan a your GCP project, you'll to setup the GCP credentials configure SSH access to all
instances:

	$ mondoo scan -t gcp://project

For Azure Compute, you need to configure your Azure credentials and have SSH access to your 
instances:

	$ mondoo scan -t az://subscriptions/subscriptionid/resourceGroups/groupname

To quickly assess the risk of a complete Kubernetes cluster just run:

	$ mondoo scan -t k8s://context/c1
	$ mondoo scan -t k8s://context/c1/namespace/n1
	$ mondoo scan -t k8s://namespace/n1

Mondoo CLI allows you to quickly scan a container registry:

	$ mondoo scan -t cr://registry
	$ mondoo scan -t cr://registry/namespace/repository
	$ mondoo scan -t cr://harbor.yourdomain.com
	$ mondoo scan -t cr://harbor.yourdomain.com/project/repository
	$ mondoo scan -t cr://yourname.azurecr.io
	$ mondoo scan -t cr://123456789.dkr.ecr.us-east-1.amazonaws.com/repository

GCR also allows to scan on project level:

	$ mondoo scan -t gcr://gcr.io/project
	$ mondoo scan -t gcr://gcr.io/project/repository

You can also leverage your exising ansible inventory:

	$ mondoo scan --inventory osts.json
	$ ansible-inventory -i hosts.ini --list | mondoo scan --ansible-inventory
		
The scan subcommand returns the following exit codes:

    * 0 - scan completed successfully with no vulnerabilities found
    * 1 - error during execution
    * 101 - scan completed successfully with low vulnerabilities found
    * 102 - scan completed successfully with medium vulnerabilities found
    * 103 - scan completed successfully with high vulnerabilities found
    * 104 - scan completed successfully with critical vulnerabilities found

Further documentation is available at https://mondoo.io/docs/
	

```
mondoo scan [flags]
```

### Options

```
      --ansible-inventory       skip inventory format detection and set the format to ansible
      --assetmrn string         Optional override of the  asset mrn for the asset
      --async                   The async options reports the packages to Mondoo cloud-only and does not print the result on CLI. 
      --collector string        This is useful to overwrite the collector endpoint. Supported values are 'https' urls and 'awssns' topics.
      --color string            Highlights text and vulnerability output with colors. The possible values of when can be 'never', 'always' or 'auto'. (default "always")
  -t, --connection string       The connection is the identifier a way to reach the asset. Supported connections are 'local://', 'docker://' and 'ssh://'
      --exit-0-on-success       Returns 0 as exit code of the scan was successful. It ignores the severity of the vulnerability assessment.
      --format string           Set the output format for the vulnerability report. Available options are 'cli', 'yaml' & 'json'. (default "cli")
  -h, --help                    help for scan
      --id-detector string      Set the assset id detector (eg. awsec2, hostname)
  -i, --identity-file string    Selects a file from which the identity (private key) for public key authentication is read.
      --incognito               Incognito mode will not store the result on the server
      --insecure                Disables TLS/SSL checks
      --inventory string        inventory file
      --labels stringToString   Additional labels enrich the asset with additional information. Multiple labels can be passed in via --labels key=value). (default [])
  -p, --password string         ssh password (not recommended in production)
      --referenceid string      Optional override of the reference id for the target
```

### Options inherited from parent commands

```
      --config string   config file (default is $HOME/.mondoo.yaml)
```

### SEE ALSO

* [mondoo](mondoo.md)	 - Mondoo CLI

