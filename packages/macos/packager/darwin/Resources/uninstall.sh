#!/bin/bash
# Copyright (c) Mondoo, Inc.
# SPDX-License-Identifier: BUSL-1.1

# Mondoo Client Uninstaller

#Parameters
DATE=`date +%Y-%m-%d`
TIME=`date +%H:%M:%S`
LOG_PREFIX="[$DATE $TIME]"

#Functions
log_info() {
    echo "${LOG_PREFIX}[INFO]" $1
}

log_warn() {
    echo "${LOG_PREFIX}[WARN]" $1
}

log_error() {
    echo "${LOG_PREFIX}[ERROR]" $1
}

#Check running user
if (( $EUID != 0 )); then
    echo "Please run as root."
    exit
fi

echo "Welcome to the Mondoo Client Uninstaller"
echo "The following packages will be REMOVED:"
echo "  __PRODUCT__-__VERSION__"
while true; do
    read -p "Do you wish to continue [Y/n]?" answer
    [[ $answer == "y" || $answer == "Y" || $answer == "" ]] && break
    [[ $answer == "n" || $answer == "N" ]] && exit 0
    echo "Please answer with 'y' or 'n'"
done


#Need to replace these with install preparation script
#VERSION=__VERSION__
PRODUCT=__PRODUCT__

echo "Application uninstalling process started"
# remove link to shorcut file
for bin in /Library/${PRODUCT_HOME}/bin/*; do
    binary="$(basename ${bin})"
    if [[ -f /usr/local/bin/${binary} ]]; then
        echo "Removing ${binary} link in /usr/local/bin"
        rm /usr/local/bin/${binary}
    fi
done
if [ $? -eq 0 ]
then
  echo "[1/4] [DONE] Successfully deleted shortcut links"
else
  echo "[1/4] [ERROR] Could not delete shortcut links" >&2
fi

# Remove Launchd
launchctl bootout system/com.mondoo.client &&
  rm /Library/LaunchDaemons/com.mondoo.client.plist > /dev/null 2>&1
if [ $? -eq 0 ]
then
  echo "[2/4] [DONE] Successfully stopped and deleted launchd service"
else
  echo "[2/4] [ERROR] Could not stop and/or delete launchd service" >&2
fi

#forget from pkgutil
pkgutil --forget "com.mondoo.client" > /dev/null 2>&1
if [ $? -eq 0 ]
then
  echo "[3/4] [DONE] Successfully deleted application informations"
else
  echo "[3/4] [ERROR] Could not delete application informations" >&2
fi

#remove application source distribution
[ -e "/Library/${PRODUCT}" ] && rm -rf "/Library/${PRODUCT}"
if [ $? -eq 0 ]
then
  echo "[4/4] [DONE] Successfully deleted application"
else
  echo "[4/4] [ERROR] Could not delete application" >&2
fi

echo "Mondoo Client uninstall process finished"
exit 0
