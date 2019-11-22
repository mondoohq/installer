# Mondoo Chef Cookbook

This cookbook installs the Mondoo agent on Linux servers. 

It does:

 * Installs the signed `mondoo` package
 * Registers the agent with Mondoo Cloud
 * Enables the systemd service

It supports:

 * RedHat & CentOS
 * Ubuntu
 * Amazon Linux
 * Debian

## Requirements

* Chef >= 14.0


## Attributes

| Name           | Default Value | Description                        |
| -------------- | ------------- | -----------------------------------|
| `default['mondoo']['registration_token']` | `changeme` | Mondoo Registration Token that is used to retrieve agent credentials


## Testing

This cookbook uses test-kitchen and InSpec for cookbook testing

```bash
# show all test vms 
kitchen list
# converge all vms
kitchen converge
# converge an individual vm
kitchen converge centos
# verify all instances
kitchen verify
# debug instance
kitchen login centos
# destroys all instances
kitchen destroy
```

## Release

We use stove to release the cookbook:

```
bundle install
bundle exec stove login --username login --key ~/.chef/key.pem
bundle exec stove --log-level debug
```

## Author

Mondoo, Inc