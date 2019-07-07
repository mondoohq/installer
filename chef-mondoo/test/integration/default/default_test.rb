# InSpec test for recipe mondoo::default

describe package('mondoo'), :skip do
  it { should be_installed }
end
