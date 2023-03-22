#!/bin/bash -e

MONDOO_VERSION=$VERSION
OUTDIR=packages
mkdir -p ${OUTDIR}

echo "--------- Creating RPM Package"

SCRIPT_LOCATION=$(readlink -f $0)
REPO_DIR=$(dirname ${SCRIPT_LOCATION})

TMPDIR=$(mktemp --directory)
cd $TMPDIR

# Set up files/directories for a rpmbuild environment
mkdir BUILD BUILDROOT RPMS SOURCES SPECS SRPMS

# Make a "release" tarball
mkdir mondoo-wrapper
cp ${REPO_DIR}/mondoo.sh mondoo-wrapper/
tar czf ./SOURCES/mondoo-${MONDOO_VERSION}.tar.gz ./mondoo-wrapper
SOURCES_PATH=${TMPDIR}/SOURCES/mondoo-${MONDOO_VERSION}.tar.gz

# The spec file pointing to the location we placed the "release" tarball
cat << EOF > ./SPECS/mondoo.spec
Name:   mondoo
Version: ${MONDOO_VERSION}
Release: 1
Summary: Mondoo checks systems for vulnerabilities, security issues and misconfigurations
License: MPL 2.0
URL: https://mondoo.com
Vendor: Mondoo, Inc
Source: ${SOURCES_PATH}
BuildArch: noarch
BuildRoot: \${_tmppath}/\${name}-root
Requires: cnspec

%description
Mondoo checks systems for vulnerabilities, security issues and misconfigurations

%prep
%setup -q -n mondoo-wrapper

%build
# it's a shell script

%install
mkdir -p \${RPM_BUILD_ROOT}/%{_bindir}
pwd
ls *
cp mondoo.sh \${RPM_BUILD_ROOT}/%{_bindir}/mondoo

%files
%defattr(-,root,root)
%{_bindir}/mondoo

%changelog

* Mon Mar 20 2023 Mondoo, Inc <hello@mondoo.com>
Initial Mondoo shell wrapper script.
EOF

# Build
echo "Building RPM..."
rpmbuild --define "_topdir `pwd`" -v -ba ./SPECS/mondoo.spec

# Save
echo "Creating NOARCH RPM"
cp RPMS/noarch/mondoo-${MONDOO_VERSION}-1.noarch.rpm ${REPO_DIR}/${OUTDIR}/mondoo_${MONDOO_VERSION}_linux_noarch.rpm

cd ${REPO_DIR}
for arch in 386 amd64 arm64 armv7 armv8 ppc64le; do
  echo "  - Creating RPM for ARCH: ${arch}"
  cp ${OUTDIR}/mondoo_${MONDOO_VERSION}_linux_noarch.rpm ${OUTDIR}/mondoo_${MONDOO_VERSION}_linux_${arch}.rpm
done

## To Test:  
##   curl -sSL https://releases.mondoo.com/rpm/mondoo.repo > /etc/yum.repos.d/mondoo.repo
##   yum install ./mondoo_0.0.1_linux_noarch.rpm