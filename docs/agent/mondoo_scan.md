## mondoo scan

Scans an asset for known vulnerabilities

### Synopsis


This command triggers a vulnerability scan. 

By default, the local system is scanned:

    $ mondoo scan

In addition, mondoo can scan remote ssh targets. Mondoo uses ssh agent and ssh 
config as default to retrieve the credentials for the target.

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
      --assetmrn string         Optional override of the  asset mrn for the asset
      --collector string        The collector reports the packages to Mondoo cloud only and does not print the result on CLI. This is useful for automated environments. Supported values are 'http' and 'awssns'.
      --color string            Highlights text and vulnerability output with colors. The possible values of when can be 'never', 'always' or 'auto'. (default "always")
  -t, --connection string       The connection is the identifier a way to reach the asset. Supported connections are 'local://', 'docker://' and 'ssh://' (default "local://")
      --exit-0-on-success       Returns 0 as exit code of the scan was successful. It ignores the severity of the vulnerability assessment.
      --format string           Set the output format for the vulnerability report. Available options are 'cli' and 'yaml'. (default "cli")
  -h, --help                    help for scan
      --id-detector string      Set the assset id detector (eg. awsec2, hostname)
  -i, --identity-file string    Selects a file from which the identity (private key) for public key authentication is read.
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

