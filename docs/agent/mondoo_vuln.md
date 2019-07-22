## mondoo vuln

Scans an asset for known vulnerabilities

### Synopsis


This command triggers a vulnerability scan. 

By default, the local system is scanned:

    $ mondoo vuln

In addition, mondoo can scan remote ssh targets. Mondoo uses ssh agent and ssh 
config as default to retrieve the credentials for the target.

    $ mondoo vuln -t ssh://ec2-user@52.51.185.215

You can also access docker images located in docker registries:

    $ mondoo vuln -t docker://ubuntu:latest
    $ mondoo vuln -t docker://elastic/elasticsearch:7.2.0
    $ mondoo vuln -t docker://gcr.io/google-containers/ubuntu:14.04
    $ mondoo vuln -t docker://registry.access.redhat.com/ubi8/ubi

If docker is installed locally, containers and images can be also
be accessed via their id:

    $ mondoo vuln -t docker://docker-image-id
    $ mondoo vuln -t docker://docker-container-id

If you like to store the report locally, pipe the output into a file:

    $ mondoo vuln --format yaml > myreport.yaml

Further documentation is available at https://mondoo.io/docs/
	

```
mondoo vuln [flags]
```

### Options

```
      --assetmrn string         Optional override of the  asset mrn for the asset
      --collector http          The collector reports the packages to Mondoo cloud only and does not print the result on CLI. This is useful for automated environments. Supported values are http and `awssns`.
  -t, --connection string       The connection is the identifier a way to reach the asset. Supported connections are 'local://', 'docker://' and 'ssh://' (default "local://")
      --exit-0-on-success       Returns 0 as exit code of the scan was successful. It ignores the severity of the vulnerability assessment.
      --format string           Set the output format for the vulnerability report. Available options are 'cli' and 'yaml'. (default "cli")
  -h, --help                    help for vuln
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

