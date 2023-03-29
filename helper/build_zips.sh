#!/bin/bash

PKG_NAME=mondoo
if [[ ${VERSION} == "" ]]; then
  echo "ERROR: Please define your version"
  export VERSION=0.0.1
fi

echo "--------- Creating ZIP Package ${PKG_NAME}"

# Create the base tgz:
mkdir -p packages
cd packages || exit
zip ${PKG_NAME}_"${VERSION}"_windows_amd64.zip ../mondoo.ps1

echo "Done"
