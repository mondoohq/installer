#!/bin/bash

export REGISTRATION_TOKEN='ey..gg'

# install mondoo
echo Installing the mondoo-agent
curl -L https://mondoo.io/install.sh | bash

# register agent
mkdir -p /etc/opt/mondoo/
echo "collector: http" >> /etc/opt/mondoo/mondoo.yml
mondoo register --config /etc/opt/mondoo/mondoo.yml --token $REGISTRATION_TOKEN

# enable systemd service
systemctl enable mondoo.timer
systemctl start mondoo.timer
systemctl daemon-reload
