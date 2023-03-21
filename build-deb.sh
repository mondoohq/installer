#!/bin/bash -e

MONDOO_VERSION=$1
if [ "${MONDOO_VERSION}" == "" ]; then
	echo "no version provided as first parameter"
	exit 1
fi

if [ "$2" == "" ]; then
	echo "no destination directory provided as second parameter"
	exit 1
fi

OUTDIR=$(readlink -f $2)

SCRIPT_LOCATION=$(readlink -f $0)
REPO_DIR=$(dirname ${SCRIPT_LOCATION})

TMPDIR=$(mktemp --directory)
cd $TMPDIR

# Set up files/directories for a debbuild environment
DEBDIR="mondoo_${MONDOO_VERSION}-1"
mkdir -p ${DEBDIR}/DEBIAN ${DEBDIR}/usr/bin

# Place the script in position
cp ${REPO_DIR}/mondoo.sh ${DEBDIR}/usr/bin/mondoo

# The control file with all the metadata
cat << EOF > ./
Package: mondoo
Version: ${MONDOO_VERSION}-1
Architecture: all
Depends: cnspec
Maintainer: hello@mondoo.com
Description: Mondoo checks systems for vulnerabilities, security issues and misconfigurations
Homepage: https://mondoo.com
EOF

# Build
dpkg-deb --build $DEBDIR

# Save
cp mondoo_${MONDOO_VERSION}-1.deb ${OUTDIR}/mondoo_${MONDOO_VERSION}_linux_noarch.deb
