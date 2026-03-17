#!/bin/bash


if [[ $VERSION = "" ]]; then
	echo "ERROR: You must supply a version number"
	exit 1
fi

rm -rf mql/
mkdir mql && cd mql || exit 1

echo "Generating NuSpec"
cat >mql.nuspec <<NUSPEC
<?xml version="1.0" encoding="utf-8"?>

<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>mql</id>
    <version>${VERSION}</version>
    <packageSourceUrl>https://github.com/mondoohq/mql</packageSourceUrl>
    <owners>Mondoo</owners>

    <title>Mondoo MQL</title>
    <authors>Mondoo</authors>
    <projectUrl>https://github.com/mondoohq/mql</projectUrl>
    <iconUrl>https://mondoo.com/mondoo_choco_logo.jpg</iconUrl>
    <copyright>2026 Mondoo, Inc.</copyright>
    <licenseUrl>https://github.com/mondoohq/mql/blob/main/LICENSE</licenseUrl>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <docsUrl>https://mondoo.com/docs/mql/</docsUrl>
    <bugTrackerUrl>https://github.com/mondoohq/mql/issues</bugTrackerUrl>
    <releaseNotes>[Release Notes](https://mondoo.com/docs/releases/)</releaseNotes>
    <tags>mql mondoo inventory cloud kubernetes server</tags>
    <summary>mql is an open source, cloud-native tool that answers every question about your infrastructure. It provides quick insights into every major technology platform used by developers, security engineers, and DevOps teams today.</summary>
    <description>mql is an open source, cloud-native tool that answers every question about your infrastructure. It provides quick insights into every major technology platform used by developers, security engineers, and DevOps teams today.</description>
  </metadata>
  <files>
    <file src="tools\**" target="tools" />
  </files>
</package>
NUSPEC


CHECKSUM=`curl -s https://install.mondoo.com/package/mql/windows/amd64/zip/${VERSION}/sha256`
if [ $CHECKSUM = "internal server error" ]; then
  echo "--- WARNING: Install service has not yet been updated with the SHAs.  WAITING 3 MINUTES ---"
  sleep 300
fi

CHECKSUM=`curl -s https://install.mondoo.com/package/mql/windows/amd64/zip/${VERSION}/sha256`
if [ $CHECKSUM = "internal server error" ]; then
  echo "--- FATAL ERROR: SHAs not available from https://install.mondoo.com/package/mql/windows/amd64/zip/${VERSION}/sha256"
  exit 1
fi

echo "Generating Install Script"
mkdir tools
cat >tools/chocolateyInstall.ps1 <<CHOCOSTALL
\$ErrorActionPreference = 'Stop'; # stop on all errors
\$toolsDir   = "\$(Split-Path -parent \$MyInvocation.MyCommand.Definition)"

\$version  = '${VERSION}'
\$url      = "https://releases.mondoo.com/mql/${VERSION}/mql_${VERSION}_windows_amd64.zip"
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
