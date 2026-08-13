#!/bin/bash
# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# Compares the reference public package signing key against the keys published
# on the Mondoo package repositories.
#
# Usage: cert-harmony.sh <reference-key>

echo "GPG Signing Cert Harmony Checker"

REFERENCE=${1:?usage: cert-harmony.sh <reference-key>}
if [[ ! -s ${REFERENCE} ]]; then
	echo "Reference key ${REFERENCE} is missing or empty!"
	exit 1
fi
REFERENCE=$(realpath "${REFERENCE}")

FAIL=0
DIR=/tmp/cert-${RANDOM}
mkdir ${DIR}
cd ${DIR} || exit 1

echo "REFERENCE KEY:"
gpg --show-keys --no-default-keyring <"${REFERENCE}"
echo "--------------"

printf "=> Comparing reference key vs RPM Repo..."
curl -s -o mondoo-repo-rpm.asc https://releases.mondoo.com/rpm/pubkey.gpg
if diff "${REFERENCE}" mondoo-repo-rpm.asc >/dev/null; then
	echo "PASS"
else
	echo "FAIL"
	FAIL=1
fi

printf "=> Comparing reference key vs Deb Repo..."
curl -s -o mondoo-repo-deb.asc https://releases.mondoo.com/debian/pubkey.gpg
if diff "${REFERENCE}" mondoo-repo-deb.asc >/dev/null; then
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
