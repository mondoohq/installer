# Copyright (c) Mondoo, Inc.
# SPDX-License-Identifier: BUSL-1.1

# use: ./package.ps1 -version 0.32.0
param (
    [string]$version = 'x.xx.x'
)

function info($msg) {  Write-Host $msg -f white }

# info "build appx package"
# Remove-Item .\mondoo.appx -ErrorAction Continue
# makeappx pack /d appx /p mondoo.appx
# Remove-Item .\mondoo.msix -ErrorAction Continue
# makeappx pack /d appx /p mondoo.msix

info "build msi package $version"
# delete previous build
Remove-Item .\mondoo.msi -ErrorAction Ignore
cd msi
# delete previous intermediate files
Remove-Item .\Product.wixobj -ErrorAction Ignore
Remove-Item .\mondoo.wixpdb -ErrorAction Ignore
# build package
dir 'C:\Program Files (x86)\WiX Toolset v3.11\bin'
info "run candle (standard)"
& 'C:\Program Files (x86)\WiX Toolset v3.11\bin\candle' -nologo -arch x64 -dMondooSKU="standard" -dProductVersion="$version" -ext WixUtilExtension Product.wxs

info "run light (standard)"
& 'C:\Program Files (x86)\WiX Toolset v3.11\bin\light' -nologo -dcl:high -cultures:en-us -loc en-us.wxl -ext WixUIExtension -ext WixUtilExtension product.wixobj -o mondoo.msi

# delete previous intermediate files
Remove-Item .\Product.wixobj -ErrorAction Ignore
Remove-Item .\mondoo.wixpdb -ErrorAction Ignore
cd ..

Move-Item .\msi\mondoo.msi .
