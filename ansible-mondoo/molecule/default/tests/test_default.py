import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_mondoo_installed(host):
    package_mondoo = host.package('mondoo')
    assert package_mondoo.is_installed

def test_mondoo_service(host):
    service_mondoo = host.service('mondoo.service')
    assert service_mondoo.is_enabled
    assert service_mondoo.is_running

def test_mondoo_config(host):
    assert host.file('/etc/opt/mondoo/mondoo.yml').exists