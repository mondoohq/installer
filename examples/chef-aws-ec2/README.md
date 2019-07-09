# Run Cookbook with Chef Run

1. Spin up a new Linux machine on [AWS](https://console.aws.amazon.com/console/home)
2. Create the wrapper cookbook

```
# prepare basic structure of wrapper cookbook
mkdir -p run
mkdir -p run/recipes

# create metadata
cat > run/metadata.rb << EOF
name 'run'
depends "mondoo"
EOF

# create recipe
cat > run/recipes/default.rb << EOF
# mitigate utf8 bug in Chef, where it fails to call `package` on a fresh instance
ENV['LANG'] = 'en_US.utf-8'
ENV['LC_ALL'] = 'en_US.utf-8'

# include chef recipe
include_recipe 'mondoo::default'
EOF

cat > run/Policyfile.rb << EOF
name "run"

run_list "run::default"

default_source :supermarket
cookbook "mondoo"
cookbook "run", path: './'

default['mondoo']['registration_token'] = "changeme"
EOF
```

3. Run

Now we are ready to apply the cookbook to a remote instance:

```
chef-run ssh://ec2-user@3.80.238.169 ./run
```

## References

- [Chef Run Documentation](https://www.chef.sh/docs/chef-workstation/chef-run-users-guide/)
