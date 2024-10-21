# Copyright (c) Mondoo, Inc.
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

info "build msi package $version"
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
& 'C:\Program Files (x86)\WiX Toolset v3.14\bin\candle' -nologo -dMondooSKU="standard" -darch="$platform" -dProductVersion="$version" -ext WixUtilExtension Product.wxs

info "run light (standard)"

& 'C:\Program Files (x86)\WiX Toolset v3.14\bin\light' -nologo -dcl:high -cultures:en-us -loc en-us.wxl -ext WixUIExtension -ext WixUtilExtension product.wixobj -o "mondoo_${arch}.msi"

# delete previous intermediate files
Remove-Item .\Product.wixobj -ErrorAction Ignore
Remove-Item .\mondoo.wixpdb -ErrorAction Ignore
cd ..

Move-Item ".\msi\mondoo_${arch}.msi" .

