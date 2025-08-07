# Copyright (c) Mondoo, Inc.
# SPDX-License-Identifier: BUSL-1.1

#Requires -Version 5

<#
    .SYNOPSIS
    # Automatic Mondoo downloader to be used with
    # [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex (new-object net.webclient).downloadstring('https://mondoo.com/download.ps1')

    .PARAMETER Product
    Set 'cnspec' (default) to download and extract the 'zip', possible values: 'cnquery', 'cnspec', 'mondoo'
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

# we only support x86_64 at this point, stop if we got arm
If ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
  fail "
Your processor architecture $env:PROCESSOR_ARCHITECTURE is not supported yet. Contact hello@mondoo.com or join the Mondoo Community GitHub Discussions https://github.com/orgs/mondoohq/discussions
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
$arch = 'amd64'
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

info ' * Extracting zip...'
# remove older version if it is still there
Remove-Item "$path\$Product.exe" -Force -ErrorAction Ignore
Add-Type -Assembly "System.IO.Compression.FileSystem"
[IO.Compression.ZipFile]::ExtractToDirectory($downloadlocation,$path)
Remove-Item $downloadlocation -Force

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
# MII6jgYJKoZIhvcNAQcCoII6fzCCOnsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBd0Ah8CI36FZ+s
# zJ4oWykpPgB8XwsTyeA1yiOgUwwuXqCCIqQwggXMMIIDtKADAgECAhBUmNLR1FsZ
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
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggbmMIIEzqADAgECAhMzAAS7CvyR
# aI6ucgG3AAAABLsKMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBBT0MgQ0EgMDIwHhcNMjUwODA2MTMwNTAzWhcNMjUwODA5
# MTMwNTAzWjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAiA/V
# Tf0F0usY2zRpYuZUeGBIv9BgvqtcYNgvEppiOcDrHMVjMjAlkdt4dDlycKxgJurr
# r2tYIn1RZw9LHK5WbNqby2VoWBpsb18WPO87OvFqGoEuMNbj6NB0sdCczGptUP+X
# gpajklzNYzm7cSUrLPk3se2peGKAQnRJYwI1QGUvb9mm0kj38cV5oyiwGkeMVGJ/
# 6uBK5J/WtliBw1kq6Gxk9T9LOZoYqasbUnSF3kZ/3qxkUTWfexkwZg6gPd/iOoPm
# parZPbX1hak/Wa2vY44RVfj6Jv4DMCPgEsu/mQcJt+PO4b5IbmbUY2kJ1BkMU+7P
# Q6vUEV7Ut3PblQB8YlO9COJvVDEyvY6d6KlxhZPpb2JdssdKTFgvDBP8TdmxMUlO
# es1caKsz0LNRjJAQPPIDRtFW5KwxMt6tWnt6jjZSOEXDepx3I+FgxMgJEddhggye
# zsYm4x69DV2R+imB6P5lg5Av5j1Cu8FmlhlO7AcxDULBPk++GEpIpkyuvsTtAgMB
# AAGjggIaMIICFjAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQUvFwoMCkqM/YvzDh2rVqEDIJaAt4wHwYDVR0jBBgw
# FoAUJEWZoXeQKnzDyoOwbmQWhCr4LGcwZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwQU9DJTIwQ0ElMjAwMi5jcmwwgaUGCCsGAQUFBwEBBIGY
# MIGVMGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L2NlcnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEFPQyUyMENB
# JTIwMDIuY3J0MC0GCCsGAQUFBzABhiFodHRwOi8vb25lb2NzcC5taWNyb3NvZnQu
# Y29tL29jc3AwZgYDVR0gBF8wXTBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcC
# ARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRv
# cnkuaHRtMAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAK0CnburAIFNmvyMl
# OnNGK7PtvmyV3uZI3nJVcZCvnZfv8bKYyvXpJGsSgIyhI3k8zrU7DTsxthiWzFBr
# 4fzxmBh07zuyk2xOzt3VGfVVYIUqcUXolCocTKZ3K38wLehhOX52unjk00wUZufZ
# Wy4bWCUv1wYuaX1WTs4EEWs70RBMOyMIi6Jd4NjDIfOkY83+P9e+7tUB9UdRdhvH
# dTYz4g/fbnESvpoHmuk6Dv+IEJtbSvc5+Y+UD4UQxLYElSsFwSGABfotBlLe9N+E
# /+PsBDDUCbDptC2a4XDIXMm/Md3Fq7M5LPtLxSlgNFZxw0OQPo5dDyJOqWrJroJN
# UvMJ9Kdx+up2ymsUtezPZAlSZ8TVzlJJ6nKMMUqDRCGeBZGDA7e3kuX+gSBeh1RJ
# fOhi3PSIpdrmpbjelXEmIqMpwKp8OPOzYspvtBn/Y0+qH+19td0EPpuCe/3YVuCR
# FE7hrnQ78JWPQTmtjoB6HpT0P9hYtjIDFHEL7h6UJ6dfWA1/mXAQSFIEOUhy/DIs
# shmZXvNTVyDEG35fsGoN7z8Q1vcsKxA1TcPKe+MXYSTp/SIlaNl9OuBfjkhK93cm
# h0vWYyBmCZ39lKvbgbp9pVT/Mc1SGSxRdRvGwnxDx+uUUH/PWRmZY1HFPu1L1tj8
# xDhqXAsusBv4KnNDK8zxA2xEmDYwggbmMIIEzqADAgECAhMzAAS7CvyRaI6ucgG3
# AAAABLsKMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJp
# ZmllZCBDUyBBT0MgQ0EgMDIwHhcNMjUwODA2MTMwNTAzWhcNMjUwODA5MTMwNTAz
# WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmExDTALBgNV
# BAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMMTW9uZG9v
# LCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAiA/VTf0F0usY
# 2zRpYuZUeGBIv9BgvqtcYNgvEppiOcDrHMVjMjAlkdt4dDlycKxgJurrr2tYIn1R
# Zw9LHK5WbNqby2VoWBpsb18WPO87OvFqGoEuMNbj6NB0sdCczGptUP+XgpajklzN
# Yzm7cSUrLPk3se2peGKAQnRJYwI1QGUvb9mm0kj38cV5oyiwGkeMVGJ/6uBK5J/W
# tliBw1kq6Gxk9T9LOZoYqasbUnSF3kZ/3qxkUTWfexkwZg6gPd/iOoPmparZPbX1
# hak/Wa2vY44RVfj6Jv4DMCPgEsu/mQcJt+PO4b5IbmbUY2kJ1BkMU+7PQ6vUEV7U
# t3PblQB8YlO9COJvVDEyvY6d6KlxhZPpb2JdssdKTFgvDBP8TdmxMUlOes1caKsz
# 0LNRjJAQPPIDRtFW5KwxMt6tWnt6jjZSOEXDepx3I+FgxMgJEddhggyezsYm4x69
# DV2R+imB6P5lg5Av5j1Cu8FmlhlO7AcxDULBPk++GEpIpkyuvsTtAgMBAAGjggIa
# MIICFjAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUENjA0Bgor
# BgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY/W+D3Nur
# KjAdBgNVHQ4EFgQUvFwoMCkqM/YvzDh2rVqEDIJaAt4wHwYDVR0jBBgwFoAUJEWZ
# oXeQKnzDyoOwbmQWhCr4LGcwZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBWZXJpZmll
# ZCUyMENTJTIwQU9DJTIwQ0ElMjAwMi5jcmwwgaUGCCsGAQUFBwEBBIGYMIGVMGQG
# CCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRz
# L01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEFPQyUyMENBJTIwMDIu
# Y3J0MC0GCCsGAQUFBzABhiFodHRwOi8vb25lb2NzcC5taWNyb3NvZnQuY29tL29j
# c3AwZgYDVR0gBF8wXTBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0
# cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRt
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAK0CnburAIFNmvyMlOnNGK7Pt
# vmyV3uZI3nJVcZCvnZfv8bKYyvXpJGsSgIyhI3k8zrU7DTsxthiWzFBr4fzxmBh0
# 7zuyk2xOzt3VGfVVYIUqcUXolCocTKZ3K38wLehhOX52unjk00wUZufZWy4bWCUv
# 1wYuaX1WTs4EEWs70RBMOyMIi6Jd4NjDIfOkY83+P9e+7tUB9UdRdhvHdTYz4g/f
# bnESvpoHmuk6Dv+IEJtbSvc5+Y+UD4UQxLYElSsFwSGABfotBlLe9N+E/+PsBDDU
# CbDptC2a4XDIXMm/Md3Fq7M5LPtLxSlgNFZxw0OQPo5dDyJOqWrJroJNUvMJ9Kdx
# +up2ymsUtezPZAlSZ8TVzlJJ6nKMMUqDRCGeBZGDA7e3kuX+gSBeh1RJfOhi3PSI
# pdrmpbjelXEmIqMpwKp8OPOzYspvtBn/Y0+qH+19td0EPpuCe/3YVuCRFE7hrnQ7
# 8JWPQTmtjoB6HpT0P9hYtjIDFHEL7h6UJ6dfWA1/mXAQSFIEOUhy/DIsshmZXvNT
# VyDEG35fsGoN7z8Q1vcsKxA1TcPKe+MXYSTp/SIlaNl9OuBfjkhK93cmh0vWYyBm
# CZ39lKvbgbp9pVT/Mc1SGSxRdRvGwnxDx+uUUH/PWRmZY1HFPu1L1tj8xDhqXAsu
# sBv4KnNDK8zxA2xEmDYwggdaMIIFQqADAgECAhMzAAAABJZQS9Lb7suIAAAAAAAE
# MA0GCSqGSIb3DQEBDAUAMGMxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xNDAyBgNVBAMTK01pY3Jvc29mdCBJRCBWZXJpZmllZCBD
# b2RlIFNpZ25pbmcgUENBIDIwMjEwHhcNMjEwNDEzMTczMTUyWhcNMjYwNDEzMTcz
# MTUyWjBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgQU9DIENBIDAy
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA4c6g6DOiY6bAOwCPbBlQ
# F2tjo3ckUZuab5ZorMnRp4rOmwZDiTbIpzFkZ/k8k4ivBJV1w5/b/oykI+eXAqaa
# xMdyAO0ModnEW7InfQ+rTkykEzHxRbCNg6KDsTnYc/YdL7IIiJli8k51upaHLL7C
# Ym9YNc0SFYvlaFj2O0HjO9y/NRmcWNjamZOlRjxW2cWgUsUdazSHgRCek87V2bM/
# 17b+o8WXUW91IpggRasmiZ65WEFHXKbyhm2LbhBK6ZWmQoFeE+GWrKWCGK/q/4Ri
# TaMNhHXWvWv+//I58UtOxVi3DaK1fQ6YLyIIGHzD4CmtcrGivxupq/crrHunGNB7
# //Qmul2ZP9HcOmY/aptgUnwT+20g/A37iDfuuVw6yS2Lo0/kp/jb+J8vE4FMqIiw
# xGByL482PMVBC3qd/NbFQa8Mmj6ensU+HEqv9ar+AbcKwumbZqJJKmQrGaSNdWfk
# 2NodgcWOmq7jyhbxwZOjnLj0/bwnsUNcNAe09v+qiozyQQes8A3UXPcRQb8G+c0y
# aO2ICifWTK7ySuyUJ88k1mtN22CNftbjitiAeafoZ9Vmhn5Rfb+S/K5arVvTcLuk
# t5PdTDQxl557EIE6A+6XFBpdsjOzkLzdEh7ELk8PVPMjQfPCgKtJ84c17fd2C9+p
# xF1lEQUFXY/YtCL+Nms9cWUCAwEAAaOCAg4wggIKMA4GA1UdDwEB/wQEAwIBhjAQ
# BgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUJEWZoXeQKnzDyoOwbmQWhCr4LGcw
# VAYDVR0gBE0wSzBJBgRVHSAAMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTAZBgkrBgEEAYI3
# FAIEDB4KAFMAdQBiAEMAQTASBgNVHRMBAf8ECDAGAQH/AgEAMB8GA1UdIwQYMBaA
# FNlBKbAPD2Ns72nX9c0pnqRIajDmMHAGA1UdHwRpMGcwZaBjoGGGX2h0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMElEJTIwVmVy
# aWZpZWQlMjBDb2RlJTIwU2lnbmluZyUyMFBDQSUyMDIwMjEuY3JsMIGuBggrBgEF
# BQcBAQSBoTCBnjBtBggrBgEFBQcwAoZhaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlmaWVkJTIwQ29kZSUy
# MFNpZ25pbmclMjBQQ0ElMjAyMDIxLmNydDAtBggrBgEFBQcwAYYhaHR0cDovL29u
# ZW9jc3AubWljcm9zb2Z0LmNvbS9vY3NwMA0GCSqGSIb3DQEBDAUAA4ICAQBnLThd
# lbMNIokdKtzSa8io+pEO95Cc3VOyY/hQsIIcdMyk2hJOzLt/M1WXfQyElDk/QtyL
# zX63TdOb5J+nO8t0pzzwi7ZYvMiNqKvAQO50sMOJn3T3hCPppxNNhoGFVxz2UyiQ
# 4b2vOrcsLK9TOEFXWbUMJObR9PM0wZsABIhu4k6VVLxEDe0GSeQX/ZE7PHfTg44L
# uft4IKqYmnv1Cuosp3glFYsVegLnMWZUZ8UtO9F8QCiAouJYhL5OlCksgDb9ve/H
# QhLFnelfg6dQubIFsqB9IlConYKJZ/HaMZvYtA7y9EORK4cxlvTetCXAHayiSXH0
# ueE/T92wVG0csv5VdUyj6yVrm22vlKYAkXINKvDOB8+s4h+TgShlUa2ACu2FWn7J
# zlTSbpk0IE8REuYmkuyE/BTkk93WDMx7PwLnn4J+5fkvbjjQ08OewfpMhh8SuPdQ
# KqmZ40I4W2UyJKMMTbet16JFimSqDChgnCB6lwlpe0gfbo97U7prpbfBKp6B2k2f
# 7Y+TjWrQYN+OdcPOyQAdxGGPBwJSaJG3ohdklCxgAJ5anCxeYl7SjQ5Eua6atjIe
# VhN0KfPLFPpYz5CQU+JC2H79x4d/O6YOFR9aYe54/CGup7dRUIfLSv1/j0DPc6El
# f3YyWxloWj8yeY3kHrZFaAlRMwhAXyPQ3rEX9zCCB54wggWGoAMCAQICEzMAAAAH
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
# ji+tHD6n58vhavFIrmcxghdAMIIXPAIBATBxMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBBT0MgQ0EgMDICEzMABLsK/JFojq5yAbcAAAAEuwowDQYJ
# YIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQgumDxTDQDcjA39S75b7ztq5Jj0NbE
# T4nfEGaesfNhQwYwDQYJKoZIhvcNAQEBBQAEggGAGfzI4DUXf7E8elfjnRU2f54B
# FyfWucNud6teczNlEOXMe59844TN7UBpPBVg/0znapaLDkdG0VtZI8Sz7cBZKMVx
# Kvkiu2yiXTncW6LQuMzKJgURbgZNA7JLpYKNnXh/SmuADLBSV6ETvJN5l0pI1akO
# vjBkgfM+DTbYa6Z5uyCmaADO61gi3NOKGjaVk3iRyKBq+NMXgDMdFGrdOTyiQqGu
# INmKLd3ICSylqqaOe0OqedRSNyx3EtQoplOZXN0UpCOGbThiBGXGt+aJRdDvioGd
# tnd7b9SgbzehLlxTvXVb4WUeNEAcQyPcENGH5CVVXFkdHzIKnA43te0sgztR1ljK
# KZSG9gIXEzbG8YeZLppvfn77ili6UOmUGzKNeNa2jtFRJcqPyJFYZrRLv77IiuMp
# QQXD9TsYaI6GIhctoW2KwdZ1iTGopmgGPQ5J4P8N/3AcXzK/Ij4/n/eToWgTzE2n
# kqITbAXCqiMyl3La3G6yFmIE7j1tFjEpKmZvyVv+oYIUwDCCFLwGCisGAQQBgjcD
# AwExghSsMIIUqAYJKoZIhvcNAQcCoIIUmTCCFJUCAQMxDzANBglghkgBZQMEAgIF
# ADCCAXEGCyqGSIb3DQEJEAEEoIIBYASCAVwwggFYAgEBBgorBgEEAYRZCgMBMEEw
# DQYJYIZIAWUDBAICBQAEMIVduGVaofCL2pTRAWCVq1rFWFfldbJ/bPapucBU4avB
# 3CM2FZQT+SOimGSHqENa1wIGaIs+l9ztGBMyMDI1MDgwNzA5NDc0Ni42ODlaMASA
# AgH0oIHgpIHdMIHaMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
# MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYwJAYDVQQL
# Ex1UaGFsZXMgVFNTIEVTTjpCQjczLTk2RkQtNzdFRjE1MDMGA1UEAxMsTWljcm9z
# b2Z0IFB1YmxpYyBSU0EgVGltZSBTdGFtcGluZyBBdXRob3JpdHmggg8gMIIHgjCC
# BWqgAwIBAgITMwAAAAXlzw//Zi7JhwAAAAAABTANBgkqhkiG9w0BAQwFADB3MQsw
# CQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMUgwRgYD
# VQQDEz9NaWNyb3NvZnQgSWRlbnRpdHkgVmVyaWZpY2F0aW9uIFJvb3QgQ2VydGlm
# aWNhdGUgQXV0aG9yaXR5IDIwMjAwHhcNMjAxMTE5MjAzMjMxWhcNMzUxMTE5MjA0
# MjMxWjBhMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1lc3RhbXBpbmcg
# Q0EgMjAyMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAJ5851Jj/eDF
# nwV9Y7UGIqMcHtfnlzPREwW9ZUZHd5HBXXBvf7KrQ5cMSqFSHGqg2/qJhYqOQxwu
# EQXG8kB41wsDJP5d0zmLYKAY8Zxv3lYkuLDsfMuIEqvGYOPURAH+Ybl4SJEESnt0
# MbPEoKdNihwM5xGv0rGofJ1qOYSTNcc55EbBT7uq3wx3mXhtVmtcCEr5ZKTkKKE1
# CxZvNPWdGWJUPC6e4uRfWHIhZcgCsJ+sozf5EeH5KrlFnxpjKKTavwfFP6XaGZGW
# UG8TZaiTogRoAlqcevbiqioUz1Yt4FRK53P6ovnUfANjIgM9JDdJ4e0qiDRm5sOT
# iEQtBLGd9Vhd1MadxoGcHrRCsS5rO9yhv2fjJHrmlQ0EIXmp4DhDBieKUGR+eZ4C
# NE3ctW4uvSDQVeSp9h1SaPV8UWEfyTxgGjOsRpeexIveR1MPTVf7gt8hY64XNPO6
# iyUGsEgt8c2PxF87E+CO7A28TpjNq5eLiiunhKbq0XbjkNoU5JhtYUrlmAbpxRjb
# 9tSreDdtACpm3rkpxp7AQndnI0Shu/fk1/rE3oWsDqMX3jjv40e8KN5YsJBnczyW
# B4JyeeFMW3JBfdeAKhzohFe8U5w9WuvcP1E8cIxLoKSDzCCBOu0hWdjzKNu8Y5Sw
# B1lt5dQhABYyzR3dxEO/T1K/BVF3rV69AgMBAAGjggIbMIICFzAOBgNVHQ8BAf8E
# BAMCAYYwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFGtpKDo1L0hjQM972K9J
# 6T7ZPdshMFQGA1UdIARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wEwYD
# VR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTIftJqhSobyhmYBAcnz1AQT2ioojCB
# hAYDVR0fBH0wezB5oHegdYZzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
# cy9jcmwvTWljcm9zb2Z0JTIwSWRlbnRpdHklMjBWZXJpZmljYXRpb24lMjBSb290
# JTIwQ2VydGlmaWNhdGUlMjBBdXRob3JpdHklMjAyMDIwLmNybDCBlAYIKwYBBQUH
# AQEEgYcwgYQwgYEGCCsGAQUFBzAChnVodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20v
# cGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElkZW50aXR5JTIwVmVyaWZpY2F0aW9u
# JTIwUm9vdCUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5JTIwMjAyMC5jcnQwDQYJ
# KoZIhvcNAQEMBQADggIBAF+Idsd+bbVaFXXnTHho+k7h2ESZJRWluLE0Oa/pO+4g
# e/XEizXvhs0Y7+KVYyb4nHlugBesnFqBGEdC2IWmtKMyS1OWIviwpnK3aL5Jedwz
# beBF7POyg6IGG/XhhJ3UqWeWTO+Czb1c2NP5zyEh89F72u9UIw+IfvM9lzDmc2O2
# END7MPnrcjWdQnrLn1Ntday7JSyrDvBdmgbNnCKNZPmhzoa8PccOiQljjTW6GePe
# 5sGFuRHzdFt8y+bN2neF7Zu8hTO1I64XNGqst8S+w+RUdie8fXC1jKu3m9KGIqF4
# aldrYBamyh3g4nJPj/LR2CBaLyD+2BuGZCVmoNR/dSpRCxlot0i79dKOChmoONqb
# MI8m04uLaEHAv4qwKHQ1vBzbV/nG89LDKbRSSvijmwJwxRxLLpMQ/u4xXxFfR4f/
# gksSkbJp7oqLwliDm/h+w0aJ/U5ccnYhYb7vPKNMN+SZDWycU5ODIRfyoGl59BsX
# R/HpRGtiJquOYGmvA/pk5vC1lcnbeMrcWD/26ozePQ/TWfNXKBOmkFpvPE8CH+Ee
# GGWzqTCjdAsno2jzTeNSxlx3glDGJgcdz5D/AAxw9Sdgq/+rY7jjgs7X6fqPTXPm
# aCAJKVHAP19oEjJIBwD1LyHbaEgBxFCogYSOiUIr0Xqcr1nJfiWG2GwYe6ZoAF1b
# MIIHljCCBX6gAwIBAgITMwAAAEXfe+fnDAkWngAAAAAARTANBgkqhkiG9w0BAQwF
# ADBhMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MTIwMAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1lc3RhbXBpbmcgQ0Eg
# MjAyMDAeFw0yNDExMjYxODQ4NDdaFw0yNTExMTkxODQ4NDdaMIHaMQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQg
# QW1lcmljYSBPcGVyYXRpb25zMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpCQjcz
# LTk2RkQtNzdFRjE1MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZSBT
# dGFtcGluZyBBdXRob3JpdHkwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
# AQDAjtP0N0JgNSdh+Pi9r4yT210+bHbdwvCUccgDxkQi5MSCsVXwXmAgAcPO+B2s
# uloB81i3nL5W2nHlEdsVUmdGCfBYTcWsMoY7Wv6QVdxdELHNqNvuu/uf6kFLCHDA
# qZB6JMDxRk26OiwtDVbSiM4QvvExziXmbMu6ADoIvrXzAvuBplbBo4arpFE4Lti/
# WvXz7LU7aZKgQzMzeVWvc+8iPdROa1ui9F5k5zs2U+4Y9MDCNe2qlLXoZTsN/gKs
# G8L1rmf0zXmioK1aNkRmWyB8zMDbwq9IqqpL9TJEFTBssQLSQ/p3+s7PLLS7EKA/
# bn2e3NQXpz43teYLlfTg8Wjs5KcpywnTTiP1biCSLoy1EcGU9bWEHcRSU/Mx/Hu8
# 9WT7/R6uHcMp7lRSJnnhoLqFyWTepzvg6hFxeRGKqF4Tt8MsyaQbMbOIx+KLyjUr
# R9wNSEvUS19/YYvobQ3eqz/ay0mu2bijKhRElrCVM3nInznPNwXVdJozs/n3mOEX
# PyAHhAFO+zrvBBrmeswlEc1ZOW+phsiahhhfvKHOYBQsU7d6yyeu8iuIamLWm/g2
# +g9Ky+ChDvQONVSsNuJ/yDA6Uh5+ly6dsZjMIo1kLes57FTokZ5TQ2VksD1Q9oXe
# nF6eMQWqxlZWvckp/r+xuy0AgWzIzZk4yK+Ujyl9pZLhbwIDAQABo4IByzCCAccw
# HQYDVR0OBBYEFCXQ2+r1JdBEyafwHcavPYdjK5XyMB8GA1UdIwQYMBaAFGtpKDo1
# L0hjQM972K9J6T7ZPdshMGwGA1UdHwRlMGMwYaBfoF2GW2h0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMFB1YmxpYyUyMFJTQSUy
# MFRpbWVzdGFtcGluZyUyMENBJTIwMjAyMC5jcmwweQYIKwYBBQUHAQEEbTBrMGkG
# CCsGAQUFBzAChl1odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRz
# L01pY3Jvc29mdCUyMFB1YmxpYyUyMFJTQSUyMFRpbWVzdGFtcGluZyUyMENBJTIw
# MjAyMC5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwZgYDVR0gBF8wXTBRBgwrBgEEAYI3TIN9AQEwQTA/Bggr
# BgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1Jl
# cG9zaXRvcnkuaHRtMAgGBmeBDAEEAjANBgkqhkiG9w0BAQwFAAOCAgEAbL2151p4
# JPix4UcYsqBC15GI/LS3A22guo5TzSBZrOiLQvkMdAaFeJUMxUlv3O7UhTcnm6c3
# HBp32EDr/iN67+QeBkXPcQSzNzNPjzSfPDHr3Na1U+4If/9vuHWo1nSntgqlqZQO
# 7VmMFa5KaA+Er8aBUtcs7VNDqe2uNvPxswl/fkexQVa8JGts+lfiGE16lRsvSNTe
# XVgQIeiV4OG2uepXm/6vP+VdDGEbJVKM+H41ODzRfCTw5//uxpie8x1bbzGh6VQs
# hicWpPE+f7W8olfVCeUfMEFS1YpUM9T98wRFxTZQXTnZyGKfRMJBrI/xwAF3WNhg
# gtAxq2JgnNIsAB02I8zH9yWmgPTDXd6CkwP0HdvHSrKu7PYxArfUpHhnCgoYt8LC
# 65rLMHZoQNyndD5JUaCeBifxJpOOd5RkuiGH9aT0Dgs6RmEMFiMVDUGi1tNz0phR
# XTklc1qF4xLBGIVC4J5mdO2rCE35SlM76VkbMGPE9hNc5tBitjq+wHiPOaDNXb5S
# QTonadzMk/ot2KMavY8o+lDdtUbx2mqc5pjxqEq1Ci6hN8k8cbbkGutfbCE9yHzF
# kFhJafQ1iP/JkqN79yuoli9SgQAuGiZBu4FTn4W/hT9HzHMxQYmCh4ciHyf06g03
# YkS0w57KkjqhOsZVG0pi0fJmZvhrmBQzxNcxggPkMIID4AIBATB4MGExCzAJBgNV
# BAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMT
# KU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVzdGFtcGluZyBDQSAyMDIwAhMzAAAA
# Rd975+cMCRaeAAAAAABFMA0GCWCGSAFlAwQCAgUAoIIBPTAaBgkqhkiG9w0BCQMx
# DQYLKoZIhvcNAQkQAQQwPwYJKoZIhvcNAQkEMTIEMGfCuwH1R27CMQSPuIPwIQGn
# Hbvg10+W5z47c07O+j0eZ4dku45oJ8cEs9MdqsbiojCB3QYLKoZIhvcNAQkQAi8x
# gc0wgcowgccwgaAEILgEVTrIyIo/ceMv5rhPHM70iM9F0uvKQRUOfiHf0m5xMHww
# ZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVzdGFtcGluZyBD
# QSAyMDIwAhMzAAAARd975+cMCRaeAAAAAABFMCIEIBC8ccawWoHR1VClZA8uDRpE
# HgtZvRe2Z2eiOtF1ijTyMA0GCSqGSIb3DQEBDAUABIICAGylF5daPsNQ3Gf2CBNu
# Z4F28ihwLdoySUThbN//TEJI/HzZCzGHwFt+HeNI62GLefGiG/Ozd/01sYeahaai
# JEsmrnGpircP3oJbnBAQwclphT5oi8G9gZWqgTYM2HEN/Igamkl2WlYj699/smoq
# 3kY2GyN1rqysqUHK+8WOxCUDt0ERzYdvYJKSUCA1HbA5Hn8w+A8Ay6/fwt6NtYwh
# BqmBczSN3F/cHmqAGC2Ay5Q8fdpz8WiGe6S+NHeoCa47l1q1mkqka3YUAxLHg7BM
# n66AJLpOP8iXfM+honsHr+fpXmqdR91+EM0V3WrGYzr+JqzAe7dx4L2M99MEcyoi
# GfIfQUwgiweNn3HQTjUApg/X6lLrDi3V1THAXKLsmbJnACKMoB2b2CIv0SoqzwoP
# Rgxj3+l0UZyjAAxvipPzxt6W8WxaFdbcIH+s1/oU/8I3oGi0om7aJeTyuNVbQ8G8
# RiTIZiyoYqibt8FU2y5Y1/1OCtMawfLboRoAcN+tLw/6h0xJMdNPiE0o1ibONlJI
# IEfGq2TpHOFfap4X5z73KaA0/mUQD0eOZiBuN/FoyzQc5d4lWAbthdfQ8aRg1AQs
# WAk2KfUhiLqEgARPpUVfVjvB0Ilk2nsrbrkNW7AHR3QaDHp9xe1f7maEi1aBpTbB
# LfLUD/WqdmCPa46PSHL/60u/
# SIG # End signature block
