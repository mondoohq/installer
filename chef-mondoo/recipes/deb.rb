#
# Cookbook:: mondoo
# Recipe:: deb
#
# Copyright:: 2019, Mondoo, Inc, All Rights Reserved.

apt_repository 'mondoo' do
  uri        node['mondoo']['deb']['repo']
  key        [node['mondoo']['deb']['gpgkey']]
  distribution 'stable'
  components ['main']
end

package 'mondoo' do
  action :install
end