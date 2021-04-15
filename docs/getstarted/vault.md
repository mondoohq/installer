# Mondoo Vault

In order to facilitate SSH scanning to a fleet of instances, Mondoo integrates with several vault systems:
 - AWS Secrets Manager
 - AWS SSM Parameter Store
 - Hashivault
 - Keyring

## Use your desired Vault and Mondoo together to scan all your assets

### Set a Vault configuration

```
$ mondoo vault set aws --type awssecretsmanager
$ mondoo vault set hashivault --type hashicorp-vault --option url=http://127.0.0.1:8200 --option token=yourtoken
```

### Add the Vault Secret Query to your configuration file (mondoo.yml)

```
vault:
  name: aws
  query: |
    if (props.labels["env"] == "test-ssh") {
       return { backend: "ssh", user: "ec2-user", secretFormat:"private_key", secretID: "this-is-my-secret"}
    }
    return { backend: "", secretID: ""}
```

### Reference the Vault when running a scan

```
$ mondoo scan -t aws:// --vault aws
```