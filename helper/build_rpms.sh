#!/bin/bash -e
# Copyright (c) Mondoo, Inc.
# SPDX-License-Identifier: BUSL-1.1


MONDOO_VERSION=$VERSION
OUTDIR=packages
mkdir -p ${OUTDIR}

echo "--------- Creating RPM Meta-Package mondoo ${MONDOO_VERSION} ---------"

SCRIPT_LOCATION=$(readlink -f "$0")
REPO_DIR=$(dirname "${SCRIPT_LOCATION}")

TMPDIR=$(mktemp --directory)
cd "$TMPDIR"

# Set up files/directories for a rpmbuild environment
mkdir BUILD BUILDROOT RPMS SOURCES SPECS SRPMS

# The spec file pointing to the location we placed the "release" tarball
cat << EOF > ./SPECS/mondoo.spec
Name:   mondoo
Version: ${MONDOO_VERSION}
Release: 1
Summary: Mondoo checks systems for vulnerabilities, security issues and misconfigurations
License: BUSL-1.1
URL: https://mondoo.com
Vendor: Mondoo, Inc
BuildArch: noarch
Requires: cnspec

%description
Mondoo checks systems for vulnerabilities, security issues and misconfigurations

%prep

%build

%install

%clean

%post

%files
%defattr(-,root,root)

%changelog
* Mon Mar 20 2023 Mondoo, Inc <hello@mondoo.com> 1-1
- Mondoo metapackage for cnspec and cnquery
EOF

# Build
echo "Building RPM..."
rpmbuild --define "_topdir $(pwd)" -v -bb ./SPECS/mondoo.spec

# Save
echo "Creating NOARCH RPM"
cp "RPMS/noarch/mondoo-${MONDOO_VERSION}-1.noarch.rpm" "${REPO_DIR}/${OUTDIR}/mondoo_${MONDOO_VERSION}_linux_noarch.rpm"

cd "${REPO_DIR}"
for arch in 386 amd64 arm64 armv6 armv7 ppc64le; do
  echo "  - Creating RPM for ARCH: ${arch}"
  cp "${OUTDIR}/mondoo_${MONDOO_VERSION}_linux_noarch.rpm" "${OUTDIR}/mondoo_${MONDOO_VERSION}_linux_${arch}.rpm"
done

## To Test:
##   curl -sSL https://releases.mondoo.com/rpm/mondoo.repo > /etc/yum.repos.d/mondoo.repo
##   yum install ./mondoo_0.0.1_linux_noarch.rpm
