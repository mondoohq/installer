## mondoo scan

Executes one or many polices for one or multiple assets

### Synopsis


This command triggers a new policy scan for an asset. By default, the local system is scanned:

    $ mondoo scan

In addition, mondoo can scan assets remotely via ssh. By default, the operating system
ssh agent and ssh config configuration is used to retrieve the credentials:

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

Mondoo supports scanning EC2 accounts and instances. It will use your AWS configuration and your
local SSH configuration to determine the required username for each individual EC2 instance:

	$ mondoo scan -t aws://profile/name/region/us-east-1
	$ mondoo scan -t aws://region/us-east-1
	$ mondoo scan -t aws://user/ec2-user
	$ mondoo scan -t aws://profile/mondoo-inc/region/us-east-1/user/ec2-user

To scan a your GCP project, you'll have to setup GCP credentials and configure SSH access to all
instances:

	$ mondoo scan -t gcp://project/projectid
	$ mondoo scan -t gcp://project/projectid/user/ec2-user

For Azure Compute, you need to configure your Azure credentials and have SSH access to your
instances:

	$ mondoo scan -t az://subscriptions/subscriptionid/resourceGroups/groupname

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

You can also leverage your existing ansible inventory:

	$ mondoo scan --inventory osts.json
	$ ansible-inventory -i hosts.ini --list | mondoo scan --ansible-inventory

The scan subcommand returns the following exit codes:

    * 0 - A+ rating of all scanned assets/policies
    * 1 - execution error during execution
    * 101 - A rating for any of scanned assets/policies
    * 102 - A- rating for any of scanned assets/policies
    * 110 - B+ rating for any of scanned assets/policies
    * 111 - B rating for any of scanned assets/policies
    * 112 - B- rating for any of scanned assets/policies
    * 120 - C+ rating for any of scanned assets/policies
    * 121 - C rating for any of scanned assets/policies
    * 122 - C- rating for any of scanned assets/policies
    * 130 - D+ rating for any of scanned assets/policies
    * 131 - D rating for any of scanned assets/policies
    * 132 - D- rating for any of scanned assets/policies
    * 150 - F rating for any of scanned assets/policies

Further documentation is available at https://mondoo.io/docs/
	

```
mondoo scan [flags]
```

### Options

```
      --ansible-inventory       skip inventory format detection and set the format to ansible
  -t, --connection string       The connection is the identifier a way to reach the asset. Supported connections are 'local://', 'docker://' and 'ssh://'
      --exit-0-on-success       returns 0 as exit code if the scan execution was successful
  -h, --help                    help for scan
      --host-machines           also scan host machines like ESXi server
  -i, --identity-file string    Selects a file from which the identity (private key) for public key authentication is read
      --incognito               Incognito mode will not store the result on the server
      --insecure                disables TLS/SSL checks or SSH hostkey config
      --instances               also scan instances (only applies to api targets like aws, azure, gcp or vsphere)
      --inventory string        inventory file
      --option stringToString   addition connection options, multiple options can be passed in via --option key=value (default [])
  -o, --output string           Output format. One of json|yaml
  -p, --password string         ssh password (not recommended in production)
      --platform-id string      select an specific asset by providing the platform id for the target
      --policy strings          list of policies to be executed (requires incognito mode), multiple policies can be passed in via --policy POLICY
      --sudo                    runs with sudo
      --vault string            vault name
```

### Options inherited from parent commands

```
      --config string     config file (default is $HOME/.mondoo.yaml)
      --loglevel string   set log-level: error, warn, info, debug, trace (default "info")
  -v, --verbose           verbose output
```

### SEE ALSO

* [mondoo](README.md)	 - Mondoo CLI

