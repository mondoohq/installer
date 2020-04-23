# InSpec test for recipe mondoo::default

describe package('mondoo') do
  it { should be_installed }
end

describe service('mondoo.service') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe file('/etc/opt/mondoo/mondoo.yml') do
  it { should exist }
end