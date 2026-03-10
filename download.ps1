# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

#Requires -Version 5

<#
    .SYNOPSIS
    # Automatic Mondoo downloader to be used with
    # [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex (new-object net.webclient).downloadstring('https://mondoo.com/download.ps1')

    .PARAMETER Product
    Set 'cnspec' (default) to download and extract the 'zip', possible values: 'mql', 'cnspec', 'mondoo'
    .PARAMETER Version
    If provided, tries to download the specific version instead of the latest
    .EXAMPLE
    download.ps1 -Product cnspec
    download.ps1 -Version 6.14.0
    download.ps1 -Path 'C:\Users\Administrator\mondoo'
#>

Param(
      [string]   $Product = 'cnspec',
      [string]   $Path = '',
      [string]   $Version = ''
  )

function fail($msg) {
  Write-Error -ErrorAction Stop -Message $msg
}

function info($msg) {
  $host.ui.RawUI.ForegroundColor = "white"
  Write-Output $msg
}

function success($msg) {
  $host.ui.RawUI.ForegroundColor = "darkgreen"
  Write-Output $msg
}

function purple($msg) {
  $host.ui.RawUI.ForegroundColor = "magenta"
  Write-Output $msg
}

function Get-UserAgent() {
  return "MondooDownloadScript/1.0 (+https://mondoo.com/) PowerShell/$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor) (Windows NT $([System.Environment]::OSVersion.Version.Major).$([System.Environment]::OSVersion.Version.Minor);$PSEdition)"
}

function download($url,$to) {
  $wc = New-Object Net.Webclient
  $wc.Headers.Add('User-Agent', (Get-UserAgent))
  $wc.downloadFile($url,$to)
}

function getenv($name,$global) {
  $target = 'User'; if($global) {$target = 'Machine'}
  [System.Environment]::GetEnvironmentVariable($name,$target)
}

function setenv($name,$value,$global) {
  $target = 'User'; if($global) {$target = 'Machine'}
  [System.Environment]::SetEnvironmentVariable($name,$value,$target)
}

purple "$Product Binary Download Script"
purple "
                        .-.
                        : :
,-.,-.,-. .--. ,-.,-. .-`' : .--.  .--.
: ,. ,. :`' .; :: ,. :`' .; :`' .; :`' .; :
:_;:_;:_;``.__.`':_;:_;``.__.`'``.__.`'``.__.
"

info "Welcome to the $Product Binary Download Script. It downloads the $Product binary for
Windows into $ENV:UserProfile\$Product and adds the path to the user's environment PATH. If
you are experiencing any issues, please do not hesitate to reach out:

  * Mondoo Community GitHub Discussions https://github.com/orgs/mondoohq/discussions

This script source is available at: https://github.com/mondoohq/installer
"

# Any subsequent commands which fails will stop the execution of the shell script
$previous_erroractionpreference = $erroractionpreference
$erroractionpreference = 'stop'

# verify powershell pre-conditions
If (($PSVersionTable.PSVersion.Major) -lt 5) {
  fail "
The install script requires PowerShell 5 or later.
To upgrade PowerShell, visit https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows
"
}

# show notification to change execution policy:
If ((Get-ExecutionPolicy) -gt 'RemoteSigned' -or (Get-ExecutionPolicy) -eq 'ByPass') {
  fail "
PowerShell requires an execution policy of 'RemoteSigned'. Please change the policy by running:
Set-ExecutionPolicy RemoteSigned -scope CurrentUser
"
}

 # check if we are on either a 64-bit intel or 64-bit arm system:
  If ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64' -and $env:PROCESSOR_ARCHITECTURE -ne 'ARM64') {
    fail "
  Your processor architecture $env:PROCESSOR_ARCHITECTURE is not supported yet. Please come join us in
  our Mondoo Community GitHub Discussions https://github.com/orgs/mondoohq/discussions or email us at hello@mondoo.com
  "
  }

info "Arguments:"
  info ("  Product:           {0}" -f $Product)
  info ("  Path:              {0}" -f $Path)
  info ("  Version:           {0}" -f $Version)
  info ""

# set download location
If ([string]::IsNullOrEmpty($Path)) {
  $path = Get-Location
} Else {
  # Check if Path exists
  $path = $Path.trim('\')
  If (!(Test-Path $path)) {New-Item -Path $path -ItemType Directory}
}

$filetype = 'zip'
$arch = $($env:PROCESSOR_ARCHITECTURE).ToLower()
$releaseurl = ''

If ([string]::IsNullOrEmpty($version)) {
    # latest release
    $releaseurl = "https://install.mondoo.com/package/${product}/windows/${arch}/${filetype}/latest/download"
  } Else {
    # specific version
    $releaseurl = "https://install.mondoo.com/package/${product}/windows/${arch}/${filetype}/${Version}/download"
  }

# download windows binary zip
$downloadlocation = "$path\$Product.$filetype"
info " * Downloading $Product from $releaseurl to $downloadlocation"
download $releaseurl $downloadlocation

# build checksum URL
$checksumurl = $releaseurl -replace "download$", "sha256"
$checksumfile = "$downloadlocation.sha256"
info " * Downloading checksum from $checksumurl to $checksumfile"
download $checksumurl $checksumfile

# read expected hash from file (it's usually in the format: "<hash> <filename>")
$expectedHash = (Get-Content $checksumfile).Split(" ")[0].Trim()

# compute actual file hash
$actualHash = (Get-FileHash -Algorithm SHA256 -Path $downloadlocation).Hash.ToLower()

info " * Validating checksum..."
if ($expectedHash.ToLower() -ne $actualHash) {
    Write-Error " x SHA256 checksum mismatch! Expected: $expectedHash, Got: $actualHash"
    exit 1
}

info ' + Checksum validated successfully!'
info ' * Extracting zip...'
# remove older version if it is still there
Remove-Item "$path\$Product.exe" -Force -ErrorAction Ignore
Add-Type -Assembly "System.IO.Compression.FileSystem"
[IO.Compression.ZipFile]::ExtractToDirectory($downloadlocation,$path)
Remove-Item $downloadlocation -Force
Remove-Item $checksumfile -Force

success " * $Product was downloaded successfully!"

# Display final message
info "Thank you for downloading $Product!"
info "
  If you have any questions, please come join us in our Mondoo Community on GitHub Discussions:

    * https://github.com/orgs/mondoohq/discussions
  "

# reset erroractionpreference
$erroractionpreference = $previous_erroractionpreference

# SIG # Begin signature block
# MII9/wYJKoZIhvcNAQcCoII98DCCPewCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDQhOoLx3cAr+Np
# xtzgXzX+OMG5Lc7PyzoOrEiiW4ymG6CCIqQwggXMMIIDtKADAgECAhBUmNLR1FsZ
# lUgTecgRwIeZMA0GCSqGSIb3DQEBDAUAMHcxCzAJBgNVBAYTAlVTMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xSDBGBgNVBAMTP01pY3Jvc29mdCBJZGVu
# dGl0eSBWZXJpZmljYXRpb24gUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAy
# MDAeFw0yMDA0MTYxODM2MTZaFw00NTA0MTYxODQ0NDBaMHcxCzAJBgNVBAYTAlVT
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xSDBGBgNVBAMTP01pY3Jv
# c29mdCBJZGVudGl0eSBWZXJpZmljYXRpb24gUm9vdCBDZXJ0aWZpY2F0ZSBBdXRo
# b3JpdHkgMjAyMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALORKgeD
# Bmf9np3gx8C3pOZCBH8Ppttf+9Va10Wg+3cL8IDzpm1aTXlT2KCGhFdFIMeiVPvH
# or+Kx24186IVxC9O40qFlkkN/76Z2BT2vCcH7kKbK/ULkgbk/WkTZaiRcvKYhOuD
# PQ7k13ESSCHLDe32R0m3m/nJxxe2hE//uKya13NnSYXjhr03QNAlhtTetcJtYmrV
# qXi8LW9J+eVsFBT9FMfTZRY33stuvF4pjf1imxUs1gXmuYkyM6Nix9fWUmcIxC70
# ViueC4fM7Ke0pqrrBc0ZV6U6CwQnHJFnni1iLS8evtrAIMsEGcoz+4m+mOJyoHI1
# vnnhnINv5G0Xb5DzPQCGdTiO0OBJmrvb0/gwytVXiGhNctO/bX9x2P29Da6SZEi3
# W295JrXNm5UhhNHvDzI9e1eM80UHTHzgXhgONXaLbZ7LNnSrBfjgc10yVpRnlyUK
# xjU9lJfnwUSLgP3B+PR0GeUw9gb7IVc+BhyLaxWGJ0l7gpPKWeh1R+g/OPTHU3mg
# trTiXFHvvV84wRPmeAyVWi7FQFkozA8kwOy6CXcjmTimthzax7ogttc32H83rwjj
# O3HbbnMbfZlysOSGM1l0tRYAe1BtxoYT2v3EOYI9JACaYNq6lMAFUSw0rFCZE4e7
# swWAsk0wAly4JoNdtGNz764jlU9gKL431VulAgMBAAGjVDBSMA4GA1UdDwEB/wQE
# AwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTIftJqhSobyhmYBAcnz1AQ
# T2ioojAQBgkrBgEEAYI3FQEEAwIBADANBgkqhkiG9w0BAQwFAAOCAgEAr2rd5hnn
# LZRDGU7L6VCVZKUDkQKL4jaAOxWiUsIWGbZqWl10QzD0m/9gdAmxIR6QFm3FJI9c
# Zohj9E/MffISTEAQiwGf2qnIrvKVG8+dBetJPnSgaFvlVixlHIJ+U9pW2UYXeZJF
# xBA2CFIpF8svpvJ+1Gkkih6PsHMNzBxKq7Kq7aeRYwFkIqgyuH4yKLNncy2RtNwx
# AQv3Rwqm8ddK7VZgxCwIo3tAsLx0J1KH1r6I3TeKiW5niB31yV2g/rarOoDXGpc8
# FzYiQR6sTdWD5jw4vU8w6VSp07YEwzJ2YbuwGMUrGLPAgNW3lbBeUU0i/OxYqujY
# lLSlLu2S3ucYfCFX3VVj979tzR/SpncocMfiWzpbCNJbTsgAlrPhgzavhgplXHT2
# 6ux6anSg8Evu75SjrFDyh+3XOjCDyft9V77l4/hByuVkrrOj7FjshZrM77nq81YY
# uVxzmq/FdxeDWds3GhhyVKVB0rYjdaNDmuV3fJZ5t0GNv+zcgKCf0Xd1WF81E+Al
# GmcLfc4l+gcK5GEh2NQc5QfGNpn0ltDGFf5Ozdeui53bFv0ExpK91IjmqaOqu/dk
# ODtfzAzQNb50GQOmxapMomE2gj4d8yu8l13bS3g7LfU772Aj6PXsCyM2la+YZr9T
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggbmMIIEzqADAgECAhMzAAdbPKux
# V+LY3kBUAAAAB1s8MA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBFT0MgQ0EgMDIwHhcNMjYwMzEwMDM0NjQ4WhcNMjYwMzEz
# MDM0NjQ4WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAiup0
# V1a1VYgyjr+DmhU2hvjaNkoGPn1oyVyOeHsb9bFSLNW99SeVHlHt4ZQ56NQeyGVs
# M2r56Y+q7ZOUQABFXehQVJOIctREvYlxTdOo4tY0IXhHCRxTULeDxxfpI0hCIm8O
# TZJjCGKdXNbZl9R2cUjXZJjvGHvBr5iCawni2nHkeMc0Jb0+75FKwW5mu+uOMqC/
# 0E86A24Nui1Ivgc2LUyBDOcOmbNkhuUHOkHO5mucyrg42offr1ybYtLIf57ZveUm
# m47JcyKxv5lCFEckDscgbCX6t5c8YW3jmutRJ7x5ArsBNGxlGRRB4arQgK8p85Fi
# 3QjUSkCDGiXZ48DU0stQCVZM0JV8PstUIj9MiNnppNK7IFYofhCSAsJjKWvPnEYO
# ykO6vsguqHBJfYGxDQ/YB7KHgTRLUGZoUkwXEhElSqPtfXv5ng0e5f/2XphYxatX
# fj2JrF4b6yEvFPA47X7fHT4i0kQIPiAuuYhJtYn8BMNiogNx1M4GRihXG0L1AgMB
# AAGjggIaMIICFjAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQUWI2wGKeqjdWeRtbjq9jW0skn/kYwHwYDVR0jBBgw
# FoAUZZ9RzoVofy+KRYiq3acxux4NAF4wZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwRU9DJTIwQ0ElMjAwMi5jcmwwgaUGCCsGAQUFBwEBBIGY
# MIGVMGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L2NlcnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENB
# JTIwMDIuY3J0MC0GCCsGAQUFBzABhiFodHRwOi8vb25lb2NzcC5taWNyb3NvZnQu
# Y29tL29jc3AwZgYDVR0gBF8wXTBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcC
# ARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRv
# cnkuaHRtMAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAQagqhhLuyYFSZVJp
# NPKNiSOnmscIXimdt8kcK7pySu6ImeJkgglKn51sYOu6Axox2hmga+Ty5D/2UtZC
# 7SdG5VsIb59T0KKQUGkYuT1gFbahHT8fw+18zHA89FINgWlvNbAARQGmHYa+O457
# bPpOIye6vUtZuhlALwCyGv+ztpoR11CVdITqouy/64p6OVZioJVi3YbKyeonVuTa
# gfazyX/N4s17Wm/yrLnr9B7atTha5xoDAzZH4hUgFGvQv+Dn5N5tQ6EaiiT8ycwk
# X3DnJ10/5VugyKo7E+aaL/qLyrnBWxjFw0Qdi2c7ckHnhp6WUxrjJlvE6LgChupr
# FCGlRsTGcBlQHQECSGLV2T9Y/ltWb0Wa8n7goEOlk7zWXLKsYU0odm1+a2c2kv18
# Muasr8nV5lw08laPQuxe9INxHWGz2O3AQUuWLR8V25YeoAPvVzT4j//jrY5hIlq8
# 9sRJQlG3AnKGGNnj2rAVSrQy+Xsv2y6YaxLCSYVwuzNGvQTIHfGapoCo380ZGKDI
# gQzItyC2gROzVcqeKnvo4UAkwJA/4byrsl+ikiHj43WzZJ3+RTCk+Tq4DJjr6Z8M
# AclYvNRuIyySs6Fv1DjOPHL0Li2ywzn/4kaC+u/rT7inYK6X4HU9m7EzAQDkHoox
# BBNIuLxAi/ybJ3C1drTlGVQMSwcwggbmMIIEzqADAgECAhMzAAdbPKuxV+LY3kBU
# AAAAB1s8MA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJp
# ZmllZCBDUyBFT0MgQ0EgMDIwHhcNMjYwMzEwMDM0NjQ4WhcNMjYwMzEzMDM0NjQ4
# WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmExDTALBgNV
# BAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMMTW9uZG9v
# LCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAiup0V1a1VYgy
# jr+DmhU2hvjaNkoGPn1oyVyOeHsb9bFSLNW99SeVHlHt4ZQ56NQeyGVsM2r56Y+q
# 7ZOUQABFXehQVJOIctREvYlxTdOo4tY0IXhHCRxTULeDxxfpI0hCIm8OTZJjCGKd
# XNbZl9R2cUjXZJjvGHvBr5iCawni2nHkeMc0Jb0+75FKwW5mu+uOMqC/0E86A24N
# ui1Ivgc2LUyBDOcOmbNkhuUHOkHO5mucyrg42offr1ybYtLIf57ZveUmm47JcyKx
# v5lCFEckDscgbCX6t5c8YW3jmutRJ7x5ArsBNGxlGRRB4arQgK8p85Fi3QjUSkCD
# GiXZ48DU0stQCVZM0JV8PstUIj9MiNnppNK7IFYofhCSAsJjKWvPnEYOykO6vsgu
# qHBJfYGxDQ/YB7KHgTRLUGZoUkwXEhElSqPtfXv5ng0e5f/2XphYxatXfj2JrF4b
# 6yEvFPA47X7fHT4i0kQIPiAuuYhJtYn8BMNiogNx1M4GRihXG0L1AgMBAAGjggIa
# MIICFjAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUENjA0Bgor
# BgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY/W+D3Nur
# KjAdBgNVHQ4EFgQUWI2wGKeqjdWeRtbjq9jW0skn/kYwHwYDVR0jBBgwFoAUZZ9R
# zoVofy+KRYiq3acxux4NAF4wZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBWZXJpZmll
# ZCUyMENTJTIwRU9DJTIwQ0ElMjAwMi5jcmwwgaUGCCsGAQUFBwEBBIGYMIGVMGQG
# CCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRz
# L01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIwMDIu
# Y3J0MC0GCCsGAQUFBzABhiFodHRwOi8vb25lb2NzcC5taWNyb3NvZnQuY29tL29j
# c3AwZgYDVR0gBF8wXTBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0
# cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRt
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAQagqhhLuyYFSZVJpNPKNiSOn
# mscIXimdt8kcK7pySu6ImeJkgglKn51sYOu6Axox2hmga+Ty5D/2UtZC7SdG5VsI
# b59T0KKQUGkYuT1gFbahHT8fw+18zHA89FINgWlvNbAARQGmHYa+O457bPpOIye6
# vUtZuhlALwCyGv+ztpoR11CVdITqouy/64p6OVZioJVi3YbKyeonVuTagfazyX/N
# 4s17Wm/yrLnr9B7atTha5xoDAzZH4hUgFGvQv+Dn5N5tQ6EaiiT8ycwkX3DnJ10/
# 5VugyKo7E+aaL/qLyrnBWxjFw0Qdi2c7ckHnhp6WUxrjJlvE6LgChuprFCGlRsTG
# cBlQHQECSGLV2T9Y/ltWb0Wa8n7goEOlk7zWXLKsYU0odm1+a2c2kv18Muasr8nV
# 5lw08laPQuxe9INxHWGz2O3AQUuWLR8V25YeoAPvVzT4j//jrY5hIlq89sRJQlG3
# AnKGGNnj2rAVSrQy+Xsv2y6YaxLCSYVwuzNGvQTIHfGapoCo380ZGKDIgQzItyC2
# gROzVcqeKnvo4UAkwJA/4byrsl+ikiHj43WzZJ3+RTCk+Tq4DJjr6Z8MAclYvNRu
# IyySs6Fv1DjOPHL0Li2ywzn/4kaC+u/rT7inYK6X4HU9m7EzAQDkHooxBBNIuLxA
# i/ybJ3C1drTlGVQMSwcwggdaMIIFQqADAgECAhMzAAAABft6XDITYd9dAAAAAAAF
# MA0GCSqGSIb3DQEBDAUAMGMxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xNDAyBgNVBAMTK01pY3Jvc29mdCBJRCBWZXJpZmllZCBD
# b2RlIFNpZ25pbmcgUENBIDIwMjEwHhcNMjEwNDEzMTczMTUzWhcNMjYwNDEzMTcz
# MTUzWjBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgRU9DIENBIDAy
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA0hqZfD8ykKTA6CDbWvsh
# mBpDoBf7Lv132RVuSqVwQO3aALLkuRnnTIoRmMGo0fIMQrtwR6UHB06xdqOkAfqB
# 6exubXTHu44+duHUCdE4ngjELBQyluMuSOnHaEdveIbt31OhMEX/4nQkph4+Ah0e
# R4H2sTRrVKmKrlOoQlhia73Qg2dHoitcX1uT1vW3Knpt9Mt76H7ZHbLNspMZLkWB
# abKMl6BdaWZXYpPGdS+qY80gDaNCvFq0d10UMu7xHesIqXpTDT3Q3AeOxSylSTc/
# 74P3og9j3OuemEFauFzL55t1MvpadEhQmD8uFMxFv/iZOjwvcdY1zhanVLLyplz1
# 3/NzSoU3QjhPdqAGhRIwh/YDzo3jCdVJgWQRrW83P3qWFFkxNiME2iO4IuYgj7Rw
# seGwv7I9cxOyaHihKMdT9NeoSjpSNzVnKKGcYMtOdMtKFqoV7Cim2m84GmIYZTBo
# rR/Po9iwlasTYKFpGZqdWKyYnJO2FV8oMmWkIK1iagLLgEt6ZaR0rk/1jUYssyTi
# RqWr84Qs3XL/V5KUBEtUEQfQ/4RtnI09uFFUIGJZV9mD/xOUksWodGrCQSem6Hy2
# 61xMJAHqTqMuDKgwi8xk/mflr7yhXPL73SOULmu1Aqu4I7Gpe6QwNW2TtQBxM3vt
# STmdPW6rK5y0gED51RjsyK0CAwEAAaOCAg4wggIKMA4GA1UdDwEB/wQEAwIBhjAQ
# BgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUZZ9RzoVofy+KRYiq3acxux4NAF4w
# VAYDVR0gBE0wSzBJBgRVHSAAMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTAZBgkrBgEEAYI3
# FAIEDB4KAFMAdQBiAEMAQTASBgNVHRMBAf8ECDAGAQH/AgEAMB8GA1UdIwQYMBaA
# FNlBKbAPD2Ns72nX9c0pnqRIajDmMHAGA1UdHwRpMGcwZaBjoGGGX2h0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMElEJTIwVmVy
# aWZpZWQlMjBDb2RlJTIwU2lnbmluZyUyMFBDQSUyMDIwMjEuY3JsMIGuBggrBgEF
# BQcBAQSBoTCBnjBtBggrBgEFBQcwAoZhaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlmaWVkJTIwQ29kZSUy
# MFNpZ25pbmclMjBQQ0ElMjAyMDIxLmNydDAtBggrBgEFBQcwAYYhaHR0cDovL29u
# ZW9jc3AubWljcm9zb2Z0LmNvbS9vY3NwMA0GCSqGSIb3DQEBDAUAA4ICAQBFSWDU
# d08X4g5HzvVfrB1SiV8pk6XPHT9jPkCmvU/uvBzmZRAjYk2gKYR3pXoStRJaJ/lh
# jC5Dq/2R7P1YRZHCDYyK0zvSRMdE6YQtgGjmsdhzD0nCS6hVVcgfmNQscPJ1WHxb
# vG5EQgYQ0ZED1FN0MOPQzWe1zbH5Va0dSxtnodBVRjnyDYEm7sNEcvJHTG3eXzAy
# d00E5KDCsEl4z5O0mvXqwaH2PS0200E6P4WqLwgs/NmUu5+Aa8Lw/2En2VkIW7Pk
# ir4Un1jG6+tj/ehuqgFyUPPCh6kbnvk48bisi/zPjAVkj7qErr7fSYICCzJ4s4YU
# NVVHgdoFn2xbW7ZfBT3QA9zfhq9u4ExXbrVD5rxXSTFEUg2gzQq9JHxsdHyMfcCK
# LFQOXODSzcYeLpCd+r6GcoDBToyPdKccjC6mAq6+/hiMDnpvKUIHpyYEzWUeatty
# KXtMf+QrJeQ+ny5jBL+xqdOOPEz3dg7qn8/oprUrUbGLBv9fWm18fWXdAv1PCtLL
# /acMLtHoyeSVMKQYqDHb3Qm0uQ+NQ0YE4kUxSQa+W/cCzYAI32uN0nb9M4Mr1pj4
# bJZidNkM4JyYqezohILxYkgHbboJQISrQWrm5RYdyhKBpptJ9JJn0Z63LjdnzlOU
# xjlsAbQir2Wmz/OJE703BbHmQZRwzPx1vu7S5zCCB54wggWGoAMCAQICEzMAAAAH
# h6M0o3uljhwAAAAAAAcwDQYJKoZIhvcNAQEMBQAwdzELMAkGA1UEBhMCVVMxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjFIMEYGA1UEAxM/TWljcm9zb2Z0
# IElkZW50aXR5IFZlcmlmaWNhdGlvbiBSb290IENlcnRpZmljYXRlIEF1dGhvcml0
# eSAyMDIwMB4XDTIxMDQwMTIwMDUyMFoXDTM2MDQwMTIwMTUyMFowYzELMAkGA1UE
# BhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjE0MDIGA1UEAxMr
# TWljcm9zb2Z0IElEIFZlcmlmaWVkIENvZGUgU2lnbmluZyBQQ0EgMjAyMTCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALLwwK8ZiCji3VR6TElsaQhVCbRS
# /3pK+MHrJSj3Zxd3KU3rlfL3qrZilYKJNqztA9OQacr1AwoNcHbKBLbsQAhBnIB3
# 4zxf52bDpIO3NJlfIaTE/xrweLoQ71lzCHkD7A4As1Bs076Iu+mA6cQzsYYH/Cbl
# 1icwQ6C65rU4V9NQhNUwgrx9rGQ//h890Q8JdjLLw0nV+ayQ2Fbkd242o9kH82RZ
# sH3HEyqjAB5a8+Ae2nPIPc8sZU6ZE7iRrRZywRmrKDp5+TcmJX9MRff241UaOBs4
# NmHOyke8oU1TYrkxh+YeHgfWo5tTgkoSMoayqoDpHOLJs+qG8Tvh8SnifW2Jj3+i
# i11TS8/FGngEaNAWrbyfNrC69oKpRQXY9bGH6jn9NEJv9weFxhTwyvx9OJLXmRGb
# AUXN1U9nf4lXezky6Uh/cgjkVd6CGUAf0K+Jw+GE/5VpIVbcNr9rNE50Sbmy/4RT
# CEGvOq3GhjITbCa4crCzTTHgYYjHs1NbOc6brH+eKpWLtr+bGecy9CrwQyx7S/Bf
# YJ+ozst7+yZtG2wR461uckFu0t+gCwLdN0A6cFtSRtR8bvxVFyWwTtgMMFRuBa3v
# mUOTnfKLsLefRaQcVTgRnzeLzdpt32cdYKp+dhr2ogc+qM6K4CBI5/j4VFyC4QFe
# UP2YAidLtvpXRRo3AgMBAAGjggI1MIICMTAOBgNVHQ8BAf8EBAMCAYYwEAYJKwYB
# BAGCNxUBBAMCAQAwHQYDVR0OBBYEFNlBKbAPD2Ns72nX9c0pnqRIajDmMFQGA1Ud
# IARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wGQYJKwYBBAGCNxQCBAwe
# CgBTAHUAYgBDAEEwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTIftJqhSob
# yhmYBAcnz1AQT2ioojCBhAYDVR0fBH0wezB5oHegdYZzaHR0cDovL3d3dy5taWNy
# b3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSWRlbnRpdHklMjBWZXJp
# ZmljYXRpb24lMjBSb290JTIwQ2VydGlmaWNhdGUlMjBBdXRob3JpdHklMjAyMDIw
# LmNybDCBwwYIKwYBBQUHAQEEgbYwgbMwgYEGCCsGAQUFBzAChnVodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElkZW50aXR5
# JTIwVmVyaWZpY2F0aW9uJTIwUm9vdCUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5
# JTIwMjAyMC5jcnQwLQYIKwYBBQUHMAGGIWh0dHA6Ly9vbmVvY3NwLm1pY3Jvc29m
# dC5jb20vb2NzcDANBgkqhkiG9w0BAQwFAAOCAgEAfyUqnv7Uq+rdZgrbVyNMul5s
# kONbhls5fccPlmIbzi+OwVdPQ4H55v7VOInnmezQEeW4LqK0wja+fBznANbXLB0K
# rdMCbHQpbLvG6UA/Xv2pfpVIE1CRFfNF4XKO8XYEa3oW8oVH+KZHgIQRIwAbyFKQ
# 9iyj4aOWeAzwk+f9E5StNp5T8FG7/VEURIVWArbAzPt9ThVN3w1fAZkF7+YU9kbq
# 1bCR2YD+MtunSQ1Rft6XG7b4e0ejRA7mB2IoX5hNh3UEauY0byxNRG+fT2MCEhQl
# 9g2i2fs6VOG19CNep7SquKaBjhWmirYyANb0RJSLWjinMLXNOAga10n8i9jqeprz
# SMU5ODmrMCJE12xS/NWShg/tuLjAsKP6SzYZ+1Ry358ZTFcx0FS/mx2vSoU8s8HR
# vy+rnXqyUJ9HBqS0DErVLjQwK8VtsBdekBmdTbQVoCgPCqr+PDPB3xajYnzevs7e
# idBsM71PINK2BoE2UfMwxCCX3mccFgx6UsQeRSdVVVNSyALQe6PT12418xon2iDG
# E81OGCreLzDcMAZnrUAx4XQLUz6ZTl65yPUiOh3k7Yww94lDf+8oG2oZmDh5O1Qe
# 38E+M3vhKwmzIeoB1dVLlz4i3IpaDcR+iuGjH2TdaC1ZOmBXiCRKJLj4DT2uhJ04
# ji+tHD6n58vhavFIrmcxghqxMIIarQIBATBxMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBFT0MgQ0EgMDICEzMAB1s8q7FX4tjeQFQAAAAHWzwwDQYJ
# YIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQgXiA+Ggqq0hMnXErpnN02eXqrLJOR
# QxsX7Sn2GMReaYEwDQYJKoZIhvcNAQEBBQAEggGAh+nC0dGZpMhPi7j8ikIVdLJ4
# aVbNUcT1SySGyQLV98neg3+RDiIbpAGywfkLfbtm2aXu2er4rYaJFrxh7Dw0T1TB
# MIPqhac9e4IXEFRfO2jmGNOLnV3F0s5Lk+xWUwL2OAs7wuPdamD9QCu8JZ8OtZWM
# p5TdOVT6BTTWz3WZU5d8q5HI8FMVYDE6ocBc1m1wZESE1vavBgcTNX0cAZOhoUqb
# c9Bo2n916UrRmvT3ppUyhmM2gwbTdp0yy1P4sZ7zCaptvQPpk4Y4QtdCnofRSXr1
# fxjSrVajaXmYPeovugFzRhU0UPSwMJltnQ0bxelD9vE+XYJC9bfMwTxb+2seELUA
# szUh78C+F2AtOZSnbIlCspYBxwZgKZj/XobI2rV/6JY1a4Mx9633eBsa4IOjG3Cn
# RczGur6Brw2N9mXNZtoPPhkyC4o53GV/SX5e0xY7NM8ju3X1jRVJvrS3pWcFvIqi
# sE0jyVovkzhBt9LkVwt2JhwFPzceCf61k0jbbVJ1oYIYMTCCGC0GCisGAQQBgjcD
# AwExghgdMIIYGQYJKoZIhvcNAQcCoIIYCjCCGAYCAQMxDzANBglghkgBZQMEAgIF
# ADCCAXIGCyqGSIb3DQEJEAEEoIIBYQSCAV0wggFZAgEBBgorBgEEAYRZCgMBMEEw
# DQYJYIZIAWUDBAICBQAEMPYERL9omGR0IWV6mr8VZ8cdeNhp3ZbwAzPxGcCT/M9c
# 9PdaWoDSylPqnUDYNAojwAIGaZRrxYBnGBMyMDI2MDMxMDE0MzAwMy4yMDhaMASA
# AgH0oIHhpIHeMIHbMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
# MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScwJQYDVQQL
# Ex5uU2hpZWxkIFRTUyBFU046N0QwMC0wNUUwLUQ5NDcxNTAzBgNVBAMTLE1pY3Jv
# c29mdCBQdWJsaWMgUlNBIFRpbWUgU3RhbXBpbmcgQXV0aG9yaXR5oIIPITCCB4Iw
# ggVqoAMCAQICEzMAAAAF5c8P/2YuyYcAAAAAAAUwDQYJKoZIhvcNAQEMBQAwdzEL
# MAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjFIMEYG
# A1UEAxM/TWljcm9zb2Z0IElkZW50aXR5IFZlcmlmaWNhdGlvbiBSb290IENlcnRp
# ZmljYXRlIEF1dGhvcml0eSAyMDIwMB4XDTIwMTExOTIwMzIzMVoXDTM1MTExOTIw
# NDIzMVowYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5n
# IENBIDIwMjAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCefOdSY/3g
# xZ8FfWO1BiKjHB7X55cz0RMFvWVGR3eRwV1wb3+yq0OXDEqhUhxqoNv6iYWKjkMc
# LhEFxvJAeNcLAyT+XdM5i2CgGPGcb95WJLiw7HzLiBKrxmDj1EQB/mG5eEiRBEp7
# dDGzxKCnTYocDOcRr9KxqHydajmEkzXHOeRGwU+7qt8Md5l4bVZrXAhK+WSk5Cih
# NQsWbzT1nRliVDwunuLkX1hyIWXIArCfrKM3+RHh+Sq5RZ8aYyik2r8HxT+l2hmR
# llBvE2Wok6IEaAJanHr24qoqFM9WLeBUSudz+qL51HwDYyIDPSQ3SeHtKog0ZubD
# k4hELQSxnfVYXdTGncaBnB60QrEuazvcob9n4yR65pUNBCF5qeA4QwYnilBkfnme
# AjRN3LVuLr0g0FXkqfYdUmj1fFFhH8k8YBozrEaXnsSL3kdTD01X+4LfIWOuFzTz
# uoslBrBILfHNj8RfOxPgjuwNvE6YzauXi4orp4Sm6tF245DaFOSYbWFK5ZgG6cUY
# 2/bUq3g3bQAqZt65KcaewEJ3ZyNEobv35Nf6xN6FrA6jF9447+NHvCjeWLCQZ3M8
# lgeCcnnhTFtyQX3XgCoc6IRXvFOcPVrr3D9RPHCMS6Ckg8wggTrtIVnY8yjbvGOU
# sAdZbeXUIQAWMs0d3cRDv09SvwVRd61evQIDAQABo4ICGzCCAhcwDgYDVR0PAQH/
# BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRraSg6NS9IY0DPe9iv
# Sek+2T3bITBUBgNVHSAETTBLMEkGBFUdIAAwQTA/BggrBgEFBQcCARYzaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMG
# A1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMA8G
# A1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUyH7SaoUqG8oZmAQHJ89QEE9oqKIw
# gYQGA1UdHwR9MHsweaB3oHWGc2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY3JsL01pY3Jvc29mdCUyMElkZW50aXR5JTIwVmVyaWZpY2F0aW9uJTIwUm9v
# dCUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5JTIwMjAyMC5jcmwwgZQGCCsGAQUF
# BwEBBIGHMIGEMIGBBggrBgEFBQcwAoZ1aHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJZGVudGl0eSUyMFZlcmlmaWNhdGlv
# biUyMFJvb3QlMjBDZXJ0aWZpY2F0ZSUyMEF1dGhvcml0eSUyMDIwMjAuY3J0MA0G
# CSqGSIb3DQEBDAUAA4ICAQBfiHbHfm21WhV150x4aPpO4dhEmSUVpbixNDmv6Tvu
# IHv1xIs174bNGO/ilWMm+Jx5boAXrJxagRhHQtiFprSjMktTliL4sKZyt2i+SXnc
# M23gRezzsoOiBhv14YSd1Klnlkzvgs29XNjT+c8hIfPRe9rvVCMPiH7zPZcw5nNj
# thDQ+zD563I1nUJ6y59TbXWsuyUsqw7wXZoGzZwijWT5oc6GvD3HDokJY401uhnj
# 3ubBhbkR83RbfMvmzdp3he2bvIUztSOuFzRqrLfEvsPkVHYnvH1wtYyrt5vShiKh
# eGpXa2AWpsod4OJyT4/y0dggWi8g/tgbhmQlZqDUf3UqUQsZaLdIu/XSjgoZqDja
# mzCPJtOLi2hBwL+KsCh0Nbwc21f5xvPSwym0Ukr4o5sCcMUcSy6TEP7uMV8RX0eH
# /4JLEpGyae6Ki8JYg5v4fsNGif1OXHJ2IWG+7zyjTDfkmQ1snFOTgyEX8qBpefQb
# F0fx6URrYiarjmBprwP6ZObwtZXJ23jK3Fg/9uqM3j0P01nzVygTppBabzxPAh/h
# Hhhls6kwo3QLJ6No803jUsZcd4JQxiYHHc+Q/wAMcPUnYKv/q2O444LO1+n6j01z
# 5mggCSlRwD9faBIySAcA9S8h22hIAcRQqIGEjolCK9F6nK9ZyX4lhthsGHumaABd
# WzCCB5cwggV/oAMCAQICEzMAAABV2d1pJij5+OIAAAAAAFUwDQYJKoZIhvcNAQEM
# BQAwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENB
# IDIwMjAwHhcNMjUxMDIzMjA0NjQ5WhcNMjYxMDIyMjA0NjQ5WjCB2zELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0
# IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjdE
# MDAtMDVFMC1EOTQ3MTUwMwYDVQQDEyxNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1l
# IFN0YW1waW5nIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAL25H5IeWUiz9DAlFmn2sPymaFWbvYkMfK+ScIWb3a1IvOlIwghUDjY0Gp6y
# MRhfYURiGS0GedIB6ywvuH6VBCX3+bdOFcAclgtv21jrpOjZmk4fSaT2Q3BszUfe
# UJa8o3xI7ZfoMY9dszTxHQAz6ZVX87fHGEVhQcfxW33IdPJOj/ae419qtYxT21MV
# mCfsTshgtWioQxmOW/vMC9/b+qgtBxSMf798vm3qfmhF6KCvFaHlivrM32hY16PG
# E3L0PFC+LM7vRxU7mTb+r76CeybvqOWk4+dbKYftPhV1t/E5S/6wwXeYmu/Y7JC7
# Tnh2w45G5Y4pcM3oHMb/YuPRdOWa0v+RC2QgmNVWqjuxDiylWscXQDuaMtb29Acd
# GUVV9ZsRY2M2sthAtOdZOshiR5ufMtaHtiCkWv0jNfgUxrHurxzYuUNneWZ6EfQD
# gFAw8CSCKkSOK2c9jEop4ddVq10xvbqxdrqMneVXvvIcXrPQAXj9j2ECpV2EwMb3
# Wnmpw00P78JpzPsk3Fs61ZvOGd/F1RcOBu6f2TWdp7HL7+rq7tgHr13MldbfIWu4
# lpoYYE1gTQa1Yrg5XN4j7zs9klT2z3qocmPzV8DWQgIHNh+aTs7bujMEMQyI7Xt1
# zPxZCgcR6H0tmmzU/9BxvsWbRalCQ2sYGyWupTdc4e7KY7kPAgMBAAGjggHLMIIB
# xzAdBgNVHQ4EFgQUVgRfEG3cCAPwyL+pyRbKwdesZbYwHwYDVR0jBBgwFoAUa2ko
# OjUvSGNAz3vYr0npPtk92yEwbAYDVR0fBGUwYzBhoF+gXYZbaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNB
# JTIwVGltZXN0YW1waW5nJTIwQ0ElMjAyMDIwLmNybDB5BggrBgEFBQcBAQRtMGsw
# aQYIKwYBBQUHMAKGXWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0El
# MjAyMDIwLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
# MA4GA1UdDwEB/wQEAwIHgDBmBgNVHSAEXzBdMFEGDCsGAQQBgjdMg30BATBBMD8G
# CCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3Mv
# UmVwb3NpdG9yeS5odG0wCAYGZ4EMAQQCMA0GCSqGSIb3DQEBDAUAA4ICAQBSHuGS
# VHvalCnFnlsqXIQefH1xP2SFr9g+Vz+f5P7QeywjfQb5jUlSmd1XnJUDPe/MHxL7
# r3TEElL+mNtG6CDPAytStSFPXD9tTBtBMYh8Wqo64pH9qm361yIqeBH979mzWCkM
# QsTd0nM6dUl9B+7qiti+ToXwxIl39eYqLuYYfhD2mqqePXMzUKSQzkf73yYIVHP6
# nLJQz4aAmaWcfG9jg78sBkDV8KpW7JgktuLhphJEN1B+SVHjenPdcmrFXIUu/K4j
# K5ukfWaQIjuaXzSjBlNjC5tQN6adPfA3GxUwHPeR4ekL5If/9vBf13tmzBW+gy+0
# sNGTveb9IL9GU8iX8UvywsX62nhCCPRUhTigDBKdczRUrNrntBhowbfchBDFML8a
# vRMRc9Gmc2JvIryX336SFQ51//q1UU2HMSJEMhWLJSIWJVhfUowsOa+PampIzETY
# fFvTu2mqKJUlWZXkGYxrdCvCczJcqeoadpW1ul6kcdnDh228SQ8ZhDc6IRlM4iNd
# 5SNoNgX+aom3wuGyjUaSaPZWxPB1G2NKiYhPLt0lPHg0Gskj1zhISY8UQkMMDr3o
# 2JgRuT+wnJEDQUp55ddvhSkSoD6I9DL/s+TjIY/c9jLaW5xywJHqdKHUApRMsghv
# 7kebSua1upmR+TquelFktDSOjVdSRkuya4uoxTGCB1MwggdPAgEBMHgwYTELMAkG
# A1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UE
# AxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIwMjACEzMA
# AABV2d1pJij5+OIAAAAAAFUwDQYJYIZIAWUDBAICBQCgggSsMBEGCyqGSIb3DQEJ
# EAIPMQIFADAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZIhvcNAQkF
# MQ8XDTI2MDMxMDE0MzAwM1owPwYJKoZIhvcNAQkEMTIEMAVz4DsK0QWNV2jbx7ru
# dRBEHtNdJEdGcRLdSkjO+3dRVoiTnUKB0fDdGtjCzDdQNjCBuQYLKoZIhvcNAQkQ
# Ai8xgakwgaYwgaMwgaAEINi5PJdkhmK7v33+/g9qqyZ5LMHGHSuqRiruxhhq+P7N
# MHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVzdGFtcGlu
# ZyBDQSAyMDIwAhMzAAAAVdndaSYo+fjiAAAAAABVMIIDXgYLKoZIhvcNAQkQAhIx
# ggNNMIIDSaGCA0UwggNBMIICKQIBATCCAQmhgeGkgd4wgdsxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVy
# aWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo3RDAwLTA1
# RTAtRDk0NzE1MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZSBTdGFt
# cGluZyBBdXRob3JpdHmiIwoBATAHBgUrDgMCGgMVAB07VAGCZb+24FlXkQaOF+xX
# hw3qoGcwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVzdGFt
# cGluZyBDQSAyMDIwMA0GCSqGSIb3DQEBCwUAAgUA7VqZmDAiGA8yMDI2MDMxMDEz
# MjIzMloYDzIwMjYwMzExMTMyMjMyWjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDt
# WpmYAgEAMAcCAQACAglgMAcCAQACAhNsMAoCBQDtW+sYAgEAMDYGCisGAQQBhFkK
# BAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJ
# KoZIhvcNAQELBQADggEBAL+qp6qpN2ERN99kwHwKYKYsa7+pubZQ4H4NFTYeZ68e
# Q5ZKMJVIIO4XO4wbeYKrekWZiclUFWYhyCaFNdeUSKPtiuEiCrGdUn/YMkeuifM4
# LMIDSVQQM8xjxqLPfMWuGtw2WNsJk2dPXKiW5IS/9pqHoogkXuTysc/0XvC2jk1p
# NuoHP8uzsHi786Y59B+tT0rYBhef+c+9GZkrHxW4qCh7FgDv/eO2L89PC7edSO8u
# xBKmvFpaT2rypHP1UXg0+CzrF3MrEev1c3CD/59Smv2OEYdO8EDR3LZP0KqWYE9i
# h5y2r3nRFrrPQ5I+W7Aw/nxXdu3ZIq98Zm7JQIK3iHswDQYJKoZIhvcNAQEBBQAE
# ggIAuwy8BnGcAK6VS+U5pqKU2DsFzs9/PJfGQ1MD5uQY921zwrGeRG2YDUVvcP/G
# kdgv1ycwnpgEoCgE7WhxxZru/cv20LwHhet8w4FyKjwMbSyY0T0L+y+VnODxRlGC
# qNiYMHf5q2LoINTFX+sPFdy1+fy1nS9e3SioE1VQ4H+XnxtDmJTWqBTLyaTBBL34
# C0/C2EeGEu5NCNeyNxKm+JFlOs07jQKtQY20y7Ww6XEb6Xzrlj27ifxWQ55SOIuL
# 5vbHT4HDR/vfPeO5R64xhz7LJhwuHt1iOnNtP0qbCDDJHKdAMXQPpSnmE5BRNN2u
# GmYiRbyB1QnZfGDkSf0PT5zxtg47bC883b12u2CS1oa0dbMSa/YAyodYPTR90BQf
# vqAgGbeJCI8VkF5ha6nMqKnLJph2ZY+QtAxnVK7jN9MWULEXhlB7trnMURAVewBm
# uFDTx6AOQ27GIk+Y0P2dzq/+lRFyf2PQmOu56Jb/rMQU9Q3xP/l+rlk2CxHQj2VN
# Ad5eh/KVpzNTc3z3cua2rSFpRlEQkx8dUr9cgT+0ArK6zecujaa+xOZ/GDRxZaRv
# bvHrTwA3LPKRXP3S9s03kV39Cb7EeAaXC2R2S5iCn2y8xI0+8620yyav5mjxviYm
# ZtUa7Rs6Nx71+FB95zm4dNIsz+WuhYX5OBADMXobeLug4Xg=
# SIG # End signature block
