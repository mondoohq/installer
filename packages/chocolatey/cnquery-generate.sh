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

    <title>Mondoo cnquery (transitional package)</title>
    <dependencies>
      <dependency id="mql" version="[$VERSION]" />
    </dependencies>
    <authors>Mondoo</authors>
    <projectUrl>https://github.com/mondoohq/cnquery</projectUrl>
    <iconUrl>https://assets.mondoo.com/mondoo_choco_logo.jpg</iconUrl>
    <copyright>2026 Mondoo, Inc.</copyright>
    <licenseUrl>https://github.com/mondoohq/cnquery/blob/main/LICENSE</licenseUrl>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <docsUrl>https://mondoo.com/docs/cnquery/</docsUrl>
    <bugTrackerUrl>https://github.com/mondoohq/cnquery/issues</bugTrackerUrl>
    <releaseNotes>cnquery has been renamed to mql. This package now installs mql as a dependency. [Release Notes](https://mondoo.com/docs/releases/)</releaseNotes>
    <tags>cnquery mql mondoo inventory cloud kubernetes server</tags>
    <summary>Transitional package: cnquery has been renamed to mql. Installing this package will install mql.</summary>
    <description>cnquery has been renamed to mql. This is a transitional package that depends on mql. Existing cnquery users will receive mql automatically when upgrading this package.</description>
  </metadata>
</package>
NUSPEC

echo "cnquery is now a transitional package that depends on mql — no install script needed"
