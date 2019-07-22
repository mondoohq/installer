# Installation via Chef

We publish an official [mondoo cookbook](https://supermarket.chef.io/cookbooks/mondoo) on Chef Supermarket. You can use the cookbook in your own [wrapper cookbooks](https://blog.chef.io/2017/02/14/writing-wrapper-cookbooks/) or [Chef Roles](https://www.digitalocean.com/community/tutorials/how-to-use-roles-and-environments-in-chef-to-control-server-configurations)

To apply the cookbook, set the Mondoo Registration Token via:

```
default['mondoo']['registration_token'] = "changeme"
```

**Example: Apply Cookbook to Amazon EC2 instance**

1. Spin up a new Linux machine on [AWS](https://console.aws.amazon.com/console/home)
2. Create the `run` wrapper cookbook as documented in our [example](https://github.com/mondoolabs/mondoo/tree/master/examples/chef-aws-ec2)
3. Run `chef-run ssh://user@host ./run`
4. All instances [reported their vulnerability status](https://mondoo.app/)