#
# Cookbook:: mondoo
# Recipe:: rpm
#
# Copyright:: 2019, Mondoo, Inc, All Rights Reserved.

yum_repository 'mondoo' do
  description 'Mondoo Repository'
  baseurl node['mondoo']['rpm']['repo']
  gpgkey node['mondoo']['rpm']['gpgkey']
  action :create
end

package 'mondoo' do
  action :install
end
