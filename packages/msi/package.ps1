# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# use: ./package.ps1 -version 0.32.0
param (
    [string]$version = 'x.xx.x',
    [string]$arch = 'amd64|arm64'
)

$platform = $arch -eq "amd64" ? "x64" : $arch

function info($msg) {  Write-Host $msg -f white }

# info "build appx package"
# Remove-Item .\mondoo.appx -ErrorAction Continue
# makeappx pack /d appx /p mondoo.appx
# Remove-Item .\mondoo.msix -ErrorAction Continue
# makeappx pack /d appx /p mondoo.msix

# Windows Installer compares only the first three fields of ProductVersion and
# rejects anything that is not numeric, so a semver pre-release or build
# metadata segment cannot go in it: `14.0.0-rc.4` fails outright, and a fourth
# field would be parsed and then ignored.
#
# Strip it. The MSI is a bootstrap: cnspec updates its own binary afterwards, so
# the version Windows reports already drifts from what is installed, and making
# ProductVersion track every release candidate would not change that. The true
# version stays in the artifact name and in what the binary reports.
$productVersion = ($version -split '[-+]')[0]
if ($productVersion -notmatch '^\d+\.\d+\.\d+$') {
    throw "cannot derive a Windows Installer ProductVersion from '$version'"
}

info "build msi package $version (ProductVersion $productVersion)"
# delete previous build
Remove-Item ".\mondoo.msi" -ErrorAction Ignore
Remove-Item ".\mondoo_${arch}.msi" -ErrorAction Ignore
cd msi
# delete previous intermediate files
Remove-Item .\Product.wixobj -ErrorAction Ignore
Remove-Item .\mondoo.wixpdb -ErrorAction Ignore
# build package
dir 'C:\Program Files (x86)\'
info "run candle (standard)"
& 'C:\Program Files (x86)\WiX Toolset v3.14\bin\candle' -nologo -dMondooSKU="standard" -darch="$platform" -dProductVersion="$productVersion" -dVersion="$version" -ext WixUtilExtension Product.wxs

info "run light (standard)"

& 'C:\Program Files (x86)\WiX Toolset v3.14\bin\light' -nologo -dcl:high -cultures:en-us -loc en-us.wxl -ext WixUIExtension -ext WixUtilExtension product.wixobj -o "mondoo_${arch}.msi"

# delete previous intermediate files
Remove-Item .\Product.wixobj -ErrorAction Ignore
Remove-Item .\mondoo.wixpdb -ErrorAction Ignore
cd ..

Move-Item ".\msi\mondoo_${arch}.msi" .

