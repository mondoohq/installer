#!/bin/bash

PKG_NAME=mondoo
if [[ ${VERSION} == "" ]]; then
  echo "ERROR: Please define your version"
  export VERSION=0.0.1
fi

echo "- Creating TGZ Package ${PKG_NAME}"

# Create the base tgz:
mkdir packages  || true
cd packages
cp ../mondoo.sh mondoo
tar cfvz ${PKG_NAME}.tar.gz mondoo
rm mondoo

# Create Linux TGZ's
echo "Creating Linux TGZs"
for arch in 386 amd64 arm64 armv6 armv7 ppc64le; do
  cp ${PKG_NAME}.tar.gz ${PKG_NAME}_${VERSION}_linux_${arch}.tar.gz  
done

# Create Darwin TGZ's
echo "Creating Darwin TGZs"
for arch in amd64 arm64; do
  cp ${PKG_NAME}.tar.gz ${PKG_NAME}_${VERSION}_linux_${arch}.tar.gz
done

echo "Done"
