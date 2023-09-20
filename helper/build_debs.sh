#!/bin/bash
# Copyright (c) Mondoo, Inc.
# SPDX-License-Identifier: BUSL-1.1


PKG_NAME=mondoo
if [[ ${VERSION} == "" ]]; then
  echo "WARNING: Please define your version. Continuing with version 0.0.1"
  export VERSION=0.0.1
fi

echo "--------- Creating Debian Package ${PKG_NAME}"

# Create the package directory:
mkdir ${PKG_NAME}

# Copy in contents:
mkdir -p ${PKG_NAME}/usr/bin
cp mondoo.sh ${PKG_NAME}/usr/bin/mondoo

# Create Package Metadata (Control File):
mkdir ${PKG_NAME}/DEBIAN
cat > ${PKG_NAME}/DEBIAN/control <<EOF
Package: ${PKG_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: all
Maintainer: Mondoo <hello@mondoo.com>
Description: Mondoo Compatability Wrapper for cnspec
Depends: cnspec (>= 8.0.0)
Installed-Size: 261 B
EOF

# Build Package:
echo "Building..."
dpkg-deb -Zgzip --root-owner-group --build ${PKG_NAME}

# Check the created Deb:
echo "Checking DPKG Contents:"
dpkg -c ${PKG_NAME}.deb
echo "Complete!"

# Create arch varieties for compatability with Legacy Mondoo CLI 
echo "Creating platform varients:"
mkdir packages
for arch in 386 amd64 arm64 armv6 armv7 ppc64le; do 
  # ex: mondoo_8.2.0_linux_amd64.deb
  echo "Creating Deb for ${arch}..."
  cp "${PKG_NAME}.deb" "packages/${PKG_NAME}_${VERSION}_linux_${arch}.deb"
done

# Clean up
rm -rf ${PKG_NAME}

# Test installation locally like this: sudo apt install ./packages/mondoo_0.0.1_linux_amd64.deb

echo "Debian Packaging Complete!  Upload packages/ to Releases & Repo!"
