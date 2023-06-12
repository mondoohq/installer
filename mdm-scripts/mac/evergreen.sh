#!/bin/bash
# The Mondoo Evergreen Installer for Mac MDM 

## Functions
download () {
  echo "Downloading..."
  cd /tmp
  FILENAME=`curl -sL https://install.mondoo.com/package/mondoo/darwin/universal/pkg/latest/filename`
  curl -sL -o ${FILENAME} https://install.mondoo.com/package/mondoo/darwin/universal/pkg/latest/download
  FILEHASH=$(shasum -a 256 ${FILENAME} | cut -d' ' -f1)
  SRCHASH=$(curl -sL https://install.mondoo.com/package/mondoo/darwin/universal/pkg/latest/sha256)
  if [ "${FILEHASH}" != "${SRCHASH}" ]; then
    echo "WARNING: Download failure, hashes do not match -- KNOWN ISSUE (benr)"
    #exit 1
  fi
}

install () {
  echo "Installing..."
  /usr/sbin/installer -pkg ${FILENAME} -target /
}

cleanup () {
  echo "Cleaning up..."
  rm ${FILENAME}
}

register () {
  echo "Registering..."
  /Library/Mondoo/bin/cnspec login --config /etc/opt/mondoo/mondoo-inc.yml
}

config () {
  echo "Configuring..."
  #if grep -q "us.api.mondoo.com" /etc/opt/mondoo/mondoo-inc.yml; then
  #  echo "Config is already up to date.  Skipping configuration."
  #  return
  #fi


  mkdir -p /etc/opt/mondoo
  if [[ -f /etc/opt/mondoo/mondoo-inc.yml ]]; then
    mv -f /etc/opt/mondoo/mondoo-inc.yml /etc/opt/mondoo/mondoo.yml-inc.old
  fi

  LOCALUSER=`dscl . -read /groups/admin GroupMembership | cut -d' ' -f3`

cat <<EOF | sed -e '/^$/d' >/etc/opt/mondoo/mondoo-inc.yml

####
#### INSERT YOUR MONDOO SPACE CONFIGURATION FILE HERE!!!!
####

EOF

}


launch () {

  echo "Enabling Mondoo Client..."

  ## Remove old launchd plists
  launchctl bootout system/com.mondoo.client
  rm -f /Library/LaunchDaemons/*.mondoo.*.plist

cat <<EOL | sed -e '/^$/d' >/Library/LaunchDaemons/com.mondoo.client.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>Label</key>
        <string>com.mondoo.client</string>
        <key>ProgramArguments</key>
        <array>
                <string>/Library/Mondoo/bin/cnspec</string>
                <string>serve</string>
                <string>--config</string>
                <string>/etc/opt/mondoo/mondoo-inc.yml</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>StandardOutPath</key>
        <string>/var/log/mondoo.log</string>
        <key>StandardErrorPath</key>
        <string>/var/log/mondoo.log</string>
</dict>
</plist>
EOL

  sleep 5
  launchctl load /Library/LaunchDaemons/com.mondoo.client.plist

  echo "Mondoo Client Post-Install Complete"
}



## Main
echo "Checking for Mondoo Client updates..."
LATEST_VERSION=`curl -sL https://install.mondoo.com/package/mondoo/darwin/universal/pkg/latest/version`
CURRENT_VERSION=`/Library/Mondoo/bin/cnspec version 2>/dev/null | cut -d' ' -f2`

if [[ ${CURRENT_VERSION} != ${LATEST_VERSION} ]]
then
  echo "New version ${LATEST_VERSION} available, upgrading from ${CURRENT_VERSION}..."

  config

  download
  install
  cleanup

  launch
  register

else
  echo "Already running the latest version.  Good bye."
  #config
  #launch
  #register
  exit 0
fi
