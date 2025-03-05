#!/bin/bash


if [[ $VERSION = "" ]]; then
	echo "ERROR: You must supply a version number"
	exit 1
fi



rm -rf cnspec/
mkdir cnspec && cd cnspec || exit 1

echo "Generating NuSpec"
cat >cnspec.nuspec <<NUSPEC
<?xml version="1.0" encoding="utf-8"?>

<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>cnspec</id>
    <version>${VERSION}</version>
    <packageSourceUrl>https://github.com/mondoohq/cnspec</packageSourceUrl>
    <owners>Mondoo</owners>
    <dependencies>
      <dependency id="cnquery" />
    </dependencies>

    <title>Mondoo cnspec</title>
    <authors>Mondoo</authors>
    <projectUrl>https://github.com/mondoohq/cnspec</projectUrl>
    <iconUrl>https://mondoo.com/mondoo_choco_logo.jpg</iconUrl>
    <copyright>2024 Mondoo, Inc.</copyright>
    <licenseUrl>https://github.com/mondoohq/cnspec/blob/main/LICENSE</licenseUrl>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <docsUrl>https://mondoo.com/docs/cnspec/</docsUrl>
    <bugTrackerUrl>https://github.com/mondoohq/cnspec/issues</bugTrackerUrl>
    <releaseNotes>[Release Notes](https://mondoo.com/docs/releases/)</releaseNotes>
    <tags>cnspec mondoo security compliance cloud kubernetes server</tags>
    <summary>cnspec is an open source, cloud-native tool that evaluates the security of your entire infrastructure. Using intuitive policy as code, cnspec scans everything and identifies gaps that attackers can use to breach your systems.</summary>
    <description>cnspec is an open source, cloud-native tool that evaluates the security of your entire infrastructure. Using intuitive policy as code, cnspec scans everything and identifies gaps that attackers can use to breach your systems. Scan public and private cloud environments, Kubernetes clusters, containers, container registries, servers and endpoints, SaaS products, infrastructure as code, APIs, and more.</description>
  </metadata>
  <files>
    <file src="tools\**" target="tools" />
  </files>
</package>
NUSPEC


CHECKSUM=`curl -s https://install.mondoo.com/package/cnspec/windows/amd64/zip/${VERSION}/sha256`
if [ $CHECKSUM = "internal server error" ]; then
  echo "--- WARNING: Install service has not yet been updated with the SHAs.  WAITING 3 MINUTES ---"
  sleep 300
fi

CHECKSUM=`curl -s https://install.mondoo.com/package/cnspec/windows/amd64/zip/${VERSION}/sha256`
if [ $CHECKSUM = "internal server error" ]; then
  echo "--- FATAL ERROR: SHAs not available from https://install.mondoo.com/package/cnspec/windows/amd64/zip/${VERSION}/sha256"
  exit 1
fi

echo "Generating Install Script"
mkdir tools
cat >tools/chocolateyInstall.ps1 <<CHOCOSTALL
\$ErrorActionPreference = 'Stop'; # stop on all errors
\$toolsDir   = "\$(Split-Path -parent \$MyInvocation.MyCommand.Definition)"

\$version  = '${VERSION}'
\$url      = "https://releases.mondoo.com/cnspec/${VERSION}/cnspec_${VERSION}_windows_amd64.zip"
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
