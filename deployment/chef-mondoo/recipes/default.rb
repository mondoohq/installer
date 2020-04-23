#
# Cookbook:: mondoo
# Recipe:: default
#
# Copyright:: 2019, Mondoo, Inc, All Rights Reserved.

require "yaml"

Chef::Log.info("Detected platform: #{ node['platform_family']}")

# install package repository
case node['platform_family']
when 'debian'
  # configure ubuntu, debian
  include_recipe('mondoo::deb')
when 'rhel', 'fedora', 'amazon'
  # configure rhel-family
  include_recipe('mondoo::rpm')
end

directory '/etc/opt/mondoo/' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# register the mondoo agent
execute 'mondoo_register' do
  command "mondoo register --config /etc/opt/mondoo/mondoo.yml --token #{node['mondoo']['registration_token']}"
  user 'root'
  creates '/etc/opt/mondoo/mondoo.yml'
end

# enable the service
service 'mondoo.service' do
  action [:start, :enable]
end