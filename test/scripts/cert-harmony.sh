#!/bin/bash
# Copyright (c) Mondoo, Inc.
# SPDX-License-Identifier: BUSL-1.1


echo "GPG Signing Cert Harmony Checker"

FAIL=0
DIR=/tmp/cert-${RANDOM}
mkdir ${DIR}
cd ${DIR} || exit 1

curl -s -o mondoohq-installer-cert.asc https://raw.githubusercontent.com/mondoohq/installer/main/public-package-signing.gpg
echo "REFERENCE KEY:"
< mondoohq-installer-cert.asc gpg --show-keys --no-default-keyring
echo "--------------"

printf "=> Comparing Github Installer vs RPM Repo..."
curl -s -o mondoo-repo-rpm.asc https://releases.mondoo.com/rpm/pubkey.gpg
if diff mondoohq-installer-cert.asc mondoo-repo-rpm.asc >/dev/null; then
	echo "PASS"
else
	echo "FAIL"
	FAIL=1
fi

printf "=> Comparing Github Installer vs Deb Repo..."
curl -s -o mondoo-repo-deb.asc https://releases.mondoo.com/debian/pubkey.gpg
if diff mondoohq-installer-cert.asc mondoo-repo-deb.asc >/dev/null; then
	echo "PASS"
else
	echo "FAIL"
	FAIL=1
fi

rm -rf ${DIR}

if [[ $FAIL == 1 ]]; then
	echo "Certificates are out of harmony!"
	exit 1
fi
