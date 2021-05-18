# CI/CD

Mondoo's vulnerability risk management solution is optimized for runtime and build-time analysis. Mondoo can be easily used in all CI/CD environments. The general workflow is as follows:

- Developers push code into the source repository
- CI/CD retrieves a trigger and starts building VM or container image
- Mondoo agent scans VM or container image and returns vulnerability rating
- CI/CD continues or aborts process based on user configuration
- CI/CD publishes VM or container image

The setup can be used in various scenarios:

- Scan machines that are deployed via CI/CD (eg. via SSH)
- Scan AMI images uses (e.g. via [Mondoo's Packer integration](../devops/packer.md))
- Scan container images

## General Setup in CI/CD

No matter if you want to scan a container image, a VM or a deployed machine, the setup is always the same. In pre-build, we retrieve the [agent credentials](../installation/registration.md) that are passed into the CI/CD job via an environment variable. To verify that everything worked, we run `mondoo version`:

**Pre-Build**

```bash
echo Download Mondoo
echo $MONDOO_AGENT_ACCOUNT > mondoo.json
curl -sSL https://mondoo.io/download.sh | bash
./mondoo version
```

More information about `download.sh` script is available at our [binary installation](../installation/binaries.md) documentation. Alternatively, we provide the alpine-based [mondoolabs/mondoo:latest](https://hub.docker.com/r/mondoolabs/mondoo) docker image which includes the mondoo binary already.

Once the `mondoo` command is set up properly, we can run a vulnerability scan:

**Build**

```bash
# run mondoo vulnerability scan
mondoo scan -t docker://imageid --config mondoo.json
```

In this case, we pipe the mondoo configuration into the mondoo binary and scan a docker image. If you like to scan an ssh target you can just call `mondoo scan -t ssh://ec2-user@52.51.185.215:2222`. All available options are documented for [mondoo scan](../cli/mondoo_scan.md#mondoo-scan)

### Exit Code Handling

Of particular interest in CI/CD is the handling of exit codes to implement project-specific decisions.

**Pass on Threshold**

By default, `mondoo scan` returns specific exit codes for [CVSS v3.0 Ratings](https://nvd.nist.gov/vuln-metrics/cvss#):

- 0 - scan completed successfully with no vulnerabilities found
- 1 - error during execution
- 101 - scan completed successfully with vulnerabilities of low severity found
- 102 - scan completed successfully with vulnerabilities of medium severity found
- 103 - scan completed successfully with vulnerabilities of high severity found
- 104 - scan completed successfully with vulnerabilities of critical severity found

This allows you to implement threshold-bassed deployment blocking. The following example illustrates how to pass a scan with low and medium severity advisories only:

```bash
# this will run mondoo and pass if the exit code is 0, 101 or 102
x=$(mondoo scan -t docker://centos:7 --config mondoo.json); exitcode="$?"; echo $x; echo $exitcode; test $exitcode -eq 0 -o $exitcode -eq 101 -o $exitcode -eq 102
```

![Use custom threshold for Mondoo](./mondoo-cicd-threshold.png)

**Pass on successful scan**

Another use case is to assess the vulnerability risk only. Instead of blocking the pipeline, you may want to always pass the build if the scan was successful. This can be achieved by passing `--exit-0-on-success` to `mondoo scan`. In most cases, this is a great setting if you just start with vulnerability assessments in CI/CD pipelines.

```bash
mondoo scan -t docker://a3592cc01fdf --exit-0-on-success
```

![Always pass if the mondoo scan was successful](./mondoo-cicd-exit0.png)

### Store mondoo credentials

Mondoo agents uses a private key to encrypt all communication with Mondoo API. Since CI/CD do not allow persistent configuration on the build nodes, the configuration needs to be passed into the CI/CD job. All CI/CD environments have a method to store environment variables. Some provide extra capabilities to store secrets (preferred if available). Set the `MONDOO_AGENT_ACCOUNT` environment variable with the content of the [agent credentials file](../installation/registration.md#retrieve-agent-credentials):

```bash
$ cat mondoo-1OsrpJIaaXmBVXXWvKj8KH1eBxH.json
{"agentMrn":"//agents.api.mondoo.app/spaces/peaceful-euler-123456/agents/1OsrpJIaaXmBVXXWvKj8KH1eBxH","spaceMrn":"//captain.api.mondoo.app/spaces/peaceful-euler-123456","privatekey":"-----BEGIN PRIVATE KEY-----\nMIG2AgEAMBAGByqGSM49AgEGBSuBBAAiBIGeMIGbAgEBBDBehmtGGruVyXLjqvkE\nOa2ieZuVY4wDbaMmtKyr6sofw9p+OQKvVxEDGX4wcY0owp9rqk3alWiRv957VcTn\n17e3FNexFQ4KFu/Ds1cdG5LaOrr5NcPgF+yqYGWux3GLOzT2Nuys7oU=\n-----END PRIVATE KEY-----\n","certificate":"-----BEGIN CERTIFICATE-----\nMIICVTCCAdygAwIBAgIQOzcp1r6SPQYnrn/ZxNm1njAKBggqhkjOPQQDAzBAMT4w\nPAYDVQQKEzUvL2NhcHRhaW4uYXBpLm1vbmRvby5hcHAvc3BhY2VzL3BlYWNlZnVs\nLWV1bGVyLTY3Nzk0NTAeFw0xOTA4MDIyMDIyMDZaFw0xOTA4MDMyMDIyMDZaMEAx\nPjA8BgNVBAoTNS8vY2FwdGFpbi5hcGkubW9uZG9vLmFwcC9zcGFjZXMvcGVhY2Vm\nZWZ1bC1ldWxlci02Nzc5NDUvYWdlbnRzLzFPc3JwSklhYVhtQlZYWFd2S2o4S0gx\nZUJ4SDAKBggqhkjOPQQDAwNnADBkAjBwoqrbPG1cuSZypxGBr2JVCbwKr3s03jSp\nUNG2f+yCViaWoYKyMb0mS1kv/+q3hu0CMGHFYxDdf7NNzFgNlXVr1jY8rUxsaPyz\nMOPM37wX3OrUHyDqSfcEZN1OVp7YN93hwA==\n-----END CERTIFICATE-----\n"}
```

In you pipeline you can easily store the file during every job via:

```bash
echo $MONDOO_AGENT_ACCOUNT > mondoo.json
```

**Handle certificate authentication error**

The JSON configuration file includes the agent's private key and certificate. The pem format requires proper newlines and some CI/CD systems interpret the newline. In those cases you recieve an error like `cannot configure certificate authentication`. The following illustrates that error in AWS CodePipeline:

![Certificate authentication error in CI/CD](./mondoo-cicd-missingbase64.png)

To prevent the CI/CD system from interpreting the configuration content, you can encode the file as base64:

```bash
$ base64 mondoo-docs.json
eyJhZ2VudE1ybiI6Ii8vYWdlbnRzLmFwaS5tb25kb28uYXBwL3NwYWNlcy9wZWFjZWZ1bC1ldWxlci0xMjM0NTYvYWdlbnRzLzFPc3JwSklhYVhtQlZYWFd2S2o4S0gxZUJ4SCIsInNwYWNlTXJuIjoiLy9jYXB0YWluLmFwaS5tb25kb28uYXBwL3NwYWNlcy9wZWFjZWZ1bC1ldWxlci0xMjM0NTYiLCJwcml2YXRla2V5IjoiLS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tXG5NSUcyQWdFQU1CQUdCeXFHU000OUFnRUdCU3VCQkFBaUJJR2VNSUdiQWdFQkJEQmVobXRHR3J1VnlYTGpxdmtFXG5PYTJpZVp1Vlk0d0RiYU1tdEt5cjZzb2Z3OXArT1FLdlZ4RURHWDR3Y1kwb3dwOXJxazNhbFdpUnY5NTdWY1RuXG4xN2UzRk5leEZRNEtGdS9EczFjZEc1TGFPcnI1TmNQZ0YreXFZR1d1eDNHTE96VDJOdXlzN29VPVxuLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLVxuIiwiY2VydGlmaWNhdGUiOiItLS0tLUJFR0lOIENFUlRJRklDQVRFLS0tLS1cbk1JSUNWVENDQWR5Z0F3SUJBZ0lRT3pjcDFyNlNQUVlucm4vWnhObTFuakFLQmdncWhrak9QUVFEQXpCQU1UNHdcblBBWURWUVFLRXpVdkwyTmhjSFJoYVc0dVlYQnBMbTF2Ym1SdmJ5NWhjSEF2YzNCaFkyVnpMM0JsWVdObFpuVnNcbkxXVjFiR1Z5TFRZM056azBOVEFlRncweE9UQTRNREl5TURJeU1EWmFGdzB4T1RBNE1ETXlNREl5TURaYU1FQXhcblBqQThCZ05WQkFvVE5TOHZZMkZ3ZEdGcGJpNWhjR2t1Ylc5dVpHOXZMbUZ3Y0M5emNHRmpaWE12Y0dWaFkyVm1cblpXWjFiQzFsZFd4bGNpMDJOemM1TkRVdllXZGxiblJ6THpGUGMzSndTa2xoWVZodFFsWllXRmQyUzJvNFMwZ3hcblpVSjRTREFLQmdncWhrak9QUVFEQXdObkFEQmtBakJ3b3FyYlBHMWN1U1p5cHhHQnIySlZDYndLcjNzMDNqU3BcblVORzJmK3lDVmlhV29ZS3lNYjBtUzFrdi8rcTNodTBDTUdIRll4RGRmN05OekZnTmxYVnIxalk4clV4c2FQeXpcbk1PUE0zN3dYM09yVUh5RHFTZmNFWk4xT1ZwN1lOOTNod0E9PVxuLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLVxuIn0K
```

In you pipeline you can easily store the file with base64  decoding during every job via:

```bash
echo $MONDOO_AGENT_ACCOUNT | base64 -d > mondoo.json
```
