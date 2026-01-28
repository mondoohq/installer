#!/bin/bash
# Copyright Mondoo, Inc. 2026, 2025, 0
# SPDX-License-Identifier: BUSL-1.1


PKG_NAME=mondoo
if [[ ${VERSION} == "" ]]; then
  echo "ERROR: Please define your version"
  export VERSION=0.0.1
fi

echo "--------- Creating TGZ Package ${PKG_NAME}"

# Create the base tgz:
mkdir -p packages
cd packages || exit
cp ../mondoo.sh mondoo
tar cfvz ${PKG_NAME}.tar.gz mondoo
rm mondoo

# Create Linux TGZ's
echo "Creating Linux TGZs"
for arch in 386 amd64 arm64 armv6 armv7 ppc64le s390x; do
  cp ${PKG_NAME}.tar.gz ${PKG_NAME}_"${VERSION}"_linux_${arch}.tar.gz  
done

# Create Darwin TGZ's
echo "Creating Darwin TGZs"
for arch in amd64 arm64; do
  cp ${PKG_NAME}.tar.gz ${PKG_NAME}_"${VERSION}"_darwin_${arch}.tar.gz
done

# Clean up
rm ${PKG_NAME}.tar.gz

echo "Done"
