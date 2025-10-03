#!/bin/bash


if [[ $VERSION = "" ]]; then
	echo "ERROR: You must supply a version number"
	exit 1
fi

rm -rf cnquery/
mkdir cnquery && cd cnquery || exit 1

echo "Generating NuSpec"
cat >cnquery.nuspec <<NUSPEC
<?xml version="1.0" encoding="utf-8"?>

<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>cnquery</id>
    <version>${VERSION}</version>
    <packageSourceUrl>https://github.com/mondoohq/cnquery</packageSourceUrl>
    <owners>Mondoo</owners>

    <title>Mondoo cnquery</title>
    <authors>Mondoo</authors>
    <projectUrl>https://github.com/mondoohq/cnquery</projectUrl>
    <iconUrl>https://mondoo.com/mondoo_choco_logo.jpg</iconUrl>
    <copyright>2025 Mondoo, Inc.</copyright>
    <licenseUrl>https://github.com/mondoohq/cnquery/blob/main/LICENSE</licenseUrl>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <docsUrl>https://mondoo.com/docs/cnquery/</docsUrl>
    <bugTrackerUrl>https://github.com/mondoohq/cnquery/issues</bugTrackerUrl>
    <releaseNotes>[Release Notes](https://mondoo.com/docs/releases/)</releaseNotes>
    <tags>cnquery mondoo inventory cloud kubernetes server</tags>
    <summary>cnquery is an open source, cloud-native tool that answers every question about your infrastructure. It provides quick insights into every major technology platform used by developers, security engineers, and DevOps teams today.</summary>
    <description>cnquery is an open source, cloud-native tool that answers every question about your infrastructure. It provides quick insights into every major technology platform used by developers, security engineers, and DevOps teams today.</description>
  </metadata>
  <files>
    <file src="tools\**" target="tools" />
  </files>
</package>
NUSPEC


CHECKSUM=`curl -s https://install.mondoo.com/package/cnquery/windows/amd64/zip/${VERSION}/sha256`
if [ $CHECKSUM = "internal server error" ]; then
  echo "--- WARNING: Install service has not yet been updated with the SHAs.  WAITING 3 MINUTES ---"
  sleep 300
fi

CHECKSUM=`curl -s https://install.mondoo.com/package/cnquery/windows/amd64/zip/${VERSION}/sha256`
if [ $CHECKSUM = "internal server error" ]; then
  echo "--- FATAL ERROR: SHAs not available from https://install.mondoo.com/package/cnquery/windows/amd64/zip/${VERSION}/sha256"
  exit 1
fi

echo "Generating Install Script"
mkdir tools
cat >tools/chocolateyInstall.ps1 <<CHOCOSTALL
\$ErrorActionPreference = 'Stop'; # stop on all errors
\$toolsDir   = "\$(Split-Path -parent \$MyInvocation.MyCommand.Definition)"

\$version  = '${VERSION}'
\$url      = "https://releases.mondoo.com/cnquery/${VERSION}/cnquery_${VERSION}_windows_amd64.zip"
\$checksum = '${CHECKSUM}'

\$packageArgs = @{
  packageName   = \$env:ChocolateyPackageName
  unzipLocation = \$toolsDir
  url64bit      = \$url

  checksum64    = \$checksum
  checksumType64= 'sha256' #default is checksumType
}

Install-ChocolateyZipPackage @packageArgs
CHOCOSTALL
