
default['mondoo'].tap do |mondoo|

  mondoo['registration_token'] = 'changeme'

  mondoo['deb']['repo'] = "https://releases.mondoo.io/debian/"
  mondoo['deb']['gpgkey'] = "https://releases.mondoo.io/debian/pubkey.gpg"

  mondoo['rpm']['repo'] = "https://releases.mondoo.io/rpm/$basearch/"
  mondoo['rpm']['gpgkey'] = "https://releases.mondoo.io/rpm/pubkey.gpg"
end
