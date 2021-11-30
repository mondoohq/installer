# This is really mitigating a bug in Chef. The `package` resoruce fails on a
# fresh amazonlinux instance because Chef is not using Utf-8 properly
# This ensures all exec's by Chef use utf8 as locale
ENV['LANG'] = 'en_US.utf-8'
ENV['LC_ALL'] = 'en_US.utf-8'

# include chef recipe
include_recipe 'mondoo::default'