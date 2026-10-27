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
      [string]   $Version = '',
      # '' is in the set because it is the default, and the default has to be
      # a member. PowerShell skips validation on an unbound default only when
      # this file is run as a script; callers that pipe it through
      # Invoke-Expression -- which is how the Azure run command installs cnspec
      # -- turn the param block into variable assignments, and the attribute is
      # then applied to the default. An out-of-set default throws
      # ValidationMetadataException there, before the body runs, so nothing
      # downloads and nothing says why. '' and an omitted -Channel mean the
      # same thing to the body below, so admitting it costs nothing.
      #
      # With that, ValidateSet is the only gate this value needs: it rejects at
      # binding, and there is no other way in -- unlike download.sh, which
      # reads MONDOO_CHANNEL from the environment and so has to check it at
      # point of use.
      [ValidateSet('', 'stable', 'preview')]
      [string]   $Channel = ''
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

# The channel selects which release line 'latest' resolves to. It is only
# meaningful for a moving version: a pinned -Version names one build, and that
# build is the same object whichever channel points at it.
#
# Appended only when asked for, so the default URLs -- and the cache entries
# keyed on them -- are unchanged.
$channelquery = ''
If (-not [string]::IsNullOrEmpty($Channel) -and [string]::IsNullOrEmpty($Version)) {
    $channelquery = "?channel=$Channel"
  } ElseIf (-not [string]::IsNullOrEmpty($Channel)) {
    info " * Ignoring -Channel $Channel : -Version $Version already names a build."
  }

# Both URLs are built from one base rather than deriving the checksum URL from
# the download URL. It used to be `$releaseurl -replace "download$", "sha256"`,
# which is anchored at the end of the string: a query parameter after the verb
# stops it matching, and the checksum URL would silently stay pointed at the
# binary.
If ([string]::IsNullOrEmpty($Version)) {
    # latest release on the selected channel
    $pkgbaseurl = "https://install.mondoo.com/package/${product}/windows/${arch}/${filetype}/latest"
  } Else {
    # specific version
    $pkgbaseurl = "https://install.mondoo.com/package/${product}/windows/${arch}/${filetype}/${Version}"
  }
$releaseurl = "${pkgbaseurl}/download${channelquery}"

# download windows binary zip
$downloadlocation = "$path\$Product.$filetype"
info " * Downloading $Product from $releaseurl to $downloadlocation"
download $releaseurl $downloadlocation

# build checksum URL
$checksumurl = "${pkgbaseurl}/sha256${channelquery}"
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
# MII9RQYJKoZIhvcNAQcCoII9NjCCPTICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDoBzOBrEWy/ctc
# L+fQn5OrHgkIwvj43cLW6yiNKXqk+qCCIeowggXMMIIDtKADAgECAhBUmNLR1FsZ
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
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggaiMIIEiqADAgECAhMzAAlPwZ0U
# NZg+KL02AAAACU/BMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBFT0MgQ0EgMDMwHhcNMjYxMDI2MDMwNjE5WhcNMjYxMDI5
# MDMwNjE5WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAne8/
# yOpktSa2wEN5w6k/6fxRxth0JcHLKE3xMH1MaoDK+4ixyTR4wpCGP0Hh/aNVohWX
# l52HZfQezLUKfqUSQzyNMK/gItZP+kjulvqvSrcWd9Q8i1+fH6hSDx1fz1okpzEY
# PpaD0Z1beHntTBNtumvCHuirNhSZx8duxOFxTAgihB5/eLoxhrdey6ZVMvnJXl6V
# vpv++MvnY290Vgp7v2gK9yJMpy8MJkTkMXIVy1lPjqLh4yjVG2BV1Ra3bp4jPXX9
# oWfqVSVHFvZuuL8CmRMuKBGtCbf9/cOGgI9yvrtx594qbN9tecuYo7+jesL74fFo
# c1xQKwcPgczD+eh/f2QaWy+3C0dCmOsgbaE0u0rjI+xD6bqJ7h+VXSairkYzecJl
# nNDNlRC/ojFv66vo1YAMTxhGqUJobrwHNMDWruSsupGpqk5AFA48HVcjbLGfmuYA
# FqXi1gW+/6Jy+fZgiJzsSeqvQbh4qgwlXOpoqOlmbZkb7H2HuT/4w2Z3sqCnAgMB
# AAGjggHWMIIB0jAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQUqGrZxbmjWZBjvJ8p+76Z5pff5bswHwYDVR0jBBgw
# FoAUa16lNMMFxWJKIVqOq3NgYtSsY4UwZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwRU9DJTIwQ0ElMjAwMy5jcmwwdAYIKwYBBQUHAQEEaDBm
# MGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Nl
# cnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIw
# MDMuY3J0MFQGA1UdIARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wDQYJ
# KoZIhvcNAQEMBQADggIBAIocnMejmRBcBlAoSZoJGF9ogDC332u3DR3wYfS0aUWm
# U+rKAyku2kFODmIIpkoTLhz1+nzLMu8p5e2bR7MlrAJ/GwIJ9cTQmGIuW+4HLU09
# EQeVhSwS3IYQBaHD+dcX8Sdc10mB4pH6eJzwqLkwL2nKWtL1Qx61IhNNlj3cUyD7
# Eln6Lg30gSGNHJsT8LYPya64IlnaVi3gm9sdrnSVdlileug+CZ912a2k4BiDRcVC
# NXZ2VNZWf5FXwLIw/qc0AEAb4TirkQjwB0OUUYzJmpexERZ2k3GPIxQ1NswgVTvW
# wg+PfSJP0MrIemb5D7QLPXlwSoxYfTgoFqQXoavectcrjq7cydtpKzUnzBkOJoyt
# DUghWyDH/9J0ig5xH0PLGwrQ/AKkj5nk/Z8/23X4N1DIkf1iCy9D9dIYDfyWJ4R0
# /GG/dzE3+z8b+We0khV9TchzoPo43t2UMfrTCb7Va+bXZA5wlcubHSXj5XOjborp
# CUCYz5MwoewvwdbGHoLAj60ycCQd2EVyzbrL9BboGq1f4Guxf1HJ09lTj50SwnNA
# Hn9EsSreehrgkYO9/4kQPl8Q6BMwzwAXZm7pwSBywTjdeua+snsrX0cUrznZzmcP
# kSIN8XHaKRL2/Avww6O6o/W9Vly/tkdtEqmnJ5J4ONRRjJ5Zk6VVCTlPB1FmgH7O
# MIIGojCCBIqgAwIBAgITMwAJT8GdFDWYPii9NgAAAAlPwTANBgkqhkiG9w0BAQwF
# ADBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgRU9DIENBIDAzMB4X
# DTI2MTAyNjAzMDYxOVoXDTI2MTAyOTAzMDYxOVowYzELMAkGA1UEBhMCVVMxFzAV
# BgNVBAgTDk5vcnRoIENhcm9saW5hMQ0wCwYDVQQHEwRDYXJ5MRUwEwYDVQQKEwxN
# b25kb28sIEluYy4xFTATBgNVBAMTDE1vbmRvbywgSW5jLjCCAaIwDQYJKoZIhvcN
# AQEBBQADggGPADCCAYoCggGBAJ3vP8jqZLUmtsBDecOpP+n8UcbYdCXByyhN8TB9
# TGqAyvuIsck0eMKQhj9B4f2jVaIVl5edh2X0Hsy1Cn6lEkM8jTCv4CLWT/pI7pb6
# r0q3FnfUPItfnx+oUg8dX89aJKcxGD6Wg9GdW3h57UwTbbprwh7oqzYUmcfHbsTh
# cUwIIoQef3i6MYa3XsumVTL5yV5elb6b/vjL52NvdFYKe79oCvciTKcvDCZE5DFy
# FctZT46i4eMo1RtgVdUWt26eIz11/aFn6lUlRxb2bri/ApkTLigRrQm3/f3DhoCP
# cr67cefeKmzfbXnLmKO/o3rC++HxaHNcUCsHD4HMw/nof39kGlsvtwtHQpjrIG2h
# NLtK4yPsQ+m6ie4flV0moq5GM3nCZZzQzZUQv6Ixb+ur6NWADE8YRqlCaG68BzTA
# 1q7krLqRqapOQBQOPB1XI2yxn5rmABal4tYFvv+icvn2YIic7Enqr0G4eKoMJVzq
# aKjpZm2ZG+x9h7k/+MNmd7KgpwIDAQABo4IB1jCCAdIwDAYDVR0TAQH/BAIwADAO
# BgNVHQ8BAf8EBAMCB4AwPQYDVR0lBDYwNAYKKwYBBAGCN2EBAAYIKwYBBQUHAwMG
# HCsGAQQBgjdhgqndkVaCp5bkUoGRmP1vg9zbqyowHQYDVR0OBBYEFKhq2cW5o1mQ
# Y7yfKfu+meaX3+W7MB8GA1UdIwQYMBaAFGtepTTDBcViSiFajqtzYGLUrGOFMGcG
# A1UdHwRgMF4wXKBaoFiGVmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIw
# MDMuY3JsMHQGCCsGAQUFBwEBBGgwZjBkBggrBgEFBQcwAoZYaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlm
# aWVkJTIwQ1MlMjBFT0MlMjBDQSUyMDAzLmNydDBUBgNVHSAETTBLMEkGBFUdIAAw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMA0GCSqGSIb3DQEBDAUAA4ICAQCKHJzHo5kQXAZQ
# KEmaCRhfaIAwt99rtw0d8GH0tGlFplPqygMpLtpBTg5iCKZKEy4c9fp8yzLvKeXt
# m0ezJawCfxsCCfXE0JhiLlvuBy1NPREHlYUsEtyGEAWhw/nXF/EnXNdJgeKR+nic
# 8Ki5MC9pylrS9UMetSITTZY93FMg+xJZ+i4N9IEhjRybE/C2D8muuCJZ2lYt4Jvb
# Ha50lXZYpXroPgmfddmtpOAYg0XFQjV2dlTWVn+RV8CyMP6nNABAG+E4q5EI8AdD
# lFGMyZqXsREWdpNxjyMUNTbMIFU71sIPj30iT9DKyHpm+Q+0Cz15cEqMWH04KBak
# F6Gr3nLXK46u3MnbaSs1J8wZDiaMrQ1IIVsgx//SdIoOcR9DyxsK0PwCpI+Z5P2f
# P9t1+DdQyJH9YgsvQ/XSGA38lieEdPxhv3cxN/s/G/lntJIVfU3Ic6D6ON7dlDH6
# 0wm+1Wvm12QOcJXLmx0l4+Vzo26K6QlAmM+TMKHsL8HWxh6CwI+tMnAkHdhFcs26
# y/QW6BqtX+BrsX9RydPZU4+dEsJzQB5/RLEq3noa4JGDvf+JED5fEOgTMM8AF2Zu
# 6cEgcsE43XrmvrJ7K19HFK852c5nD5EiDfFx2ikS9vwL8MOjuqP1vVZcv7ZHbRKp
# pyeSeDjUUYyeWZOlVQk5TwdRZoB+zjCCBygwggUQoAMCAQICEzMAAAAVBT5uGY6T
# KdkAAAAAABUwDQYJKoZIhvcNAQEMBQAwYzELMAkGA1UEBhMCVVMxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjE0MDIGA1UEAxMrTWljcm9zb2Z0IElEIFZl
# cmlmaWVkIENvZGUgU2lnbmluZyBQQ0EgMjAyMTAeFw0yNjAzMjYxODExMjhaFw0z
# MTAzMjYxODExMjhaMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJpZmllZCBDUyBF
# T0MgQ0EgMDMwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDg9Ms9Aqov
# DnMePvMOe+KybhCd8+lokzYORlS3kBVXseecbyGwBcsenlm5bLtMGPjiIFLzBQF+
# ghlVV/U29q5GcdeEEBCHTTGhL2koIrLc4UrliMRcbv9mOMtR/l7/xAmv0Fx4BJHn
# 1dHt37fvrBqXmKjKfGf5DpyO/+hnV7TEreMtS19iO+bjZ/9Hnpg3PCk0e7YSbRTF
# kx97FZwRWpC4s3NepRfRXQh/WMAj7JmsYeVZohi4TF5yW2JMrJZqwHcyzJZYtD2H
# lno5ZEJkdiZcEaxHOobmwO06Z1J9c23ps9PGIhGaq1sKLEAz9Doc5rLkYWGteDrs
# cKhAp2kIc/oYlH9Ij6BkOqqgWINEkEtC8ZNG1Mak+h3o65aj0iQKmdxW7IZaHO5c
# uyoMi+KtYfXeIIg3sVIbS2EL8kUtsDGdEqNqAq/isqTi1jXqLe6iKp1ni1SPdvPW
# 9G03CTsYF68b/yuIQRwbdoBCXemMNJCS0dorCRY4b2WAAy4ng7SANcEgrBgZf535
# +QfLU5hGzrKjIpbMabauWb5FKWUKkMsPcXFkXRWO4noKPm4KWlFypqOpbJ/KONVR
# eIlxHQRegAOBzIhRB7gr9IDQ1sc2MgOgQ+xVGW4oq4HD0mfAiwiyLskZrkaQ7Joa
# nYjBNcR9RS26YxAVbcBtLitFTzCIEg5ZdQIDAQABo4IB3DCCAdgwDgYDVR0PAQH/
# BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRrXqU0wwXFYkohWo6r
# c2Bi1KxjhTBUBgNVHSAETTBLMEkGBFUdIAAwQTA/BggrBgEFBQcCARYzaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBkG
# CSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMBIGA1UdEwEB/wQIMAYBAf8CAQAwHwYD
# VR0jBBgwFoAU2UEpsA8PY2zvadf1zSmepEhqMOYwcAYDVR0fBGkwZzBloGOgYYZf
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIw
# SUQlMjBWZXJpZmllZCUyMENvZGUlMjBTaWduaW5nJTIwUENBJTIwMjAyMS5jcmww
# fQYIKwYBBQUHAQEEcTBvMG0GCCsGAQUFBzAChmFodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBD
# b2RlJTIwU2lnbmluZyUyMFBDQSUyMDIwMjEuY3J0MA0GCSqGSIb3DQEBDAUAA4IC
# AQBdbiI8zwXLX8glJEh/8Q22UMCUhWBO46Z9FPhwOR3mdlqRVLkYOon/MczUwrjD
# hx3X99SPH5PSflkGoTvnO9ZWHM5YFVYpO7NYuB+mfVSGAGZwiGOASWk0i2B7vn9n
# ElJJmoiXxugfH5YdBsrUgTt0AFNXkzmqTgk+S1Hxb1u/0HCqEHVZPk2A/6eJXYbt
# pRM5Fcz00jisUl9BRZgSebODV85bBzOveqyC3f0PnHCxRJNhMb8xP/sB/VI7pf2r
# heSV7zqUSv8vn/fIMblXeaVIlpqoq8SP9BJMjE/CoVXJxnkZQRM1Fa7kN9yztvRe
# OhxSgPgpZx/Xl/jkwyEFVJTBfBp3sTgfIc/pmqv2ehtakL2AEj78EmOPQohxJT3w
# yX+P78GA25tLpAvzj3RMMHd8z18ZuuVi+60MAzGpOASH1L8Nlr3fZRZnQO+pyye2
# DCvYmHaIfdUgYJqn7noxxGVv89+RaETh1tgCDvwNpFCSG7vl5A4ako+2fx409r9T
# WjXC7Oif1IQ5ZJzB4Rf8GvBiHYjvMmHpledp1FGRLdSRFVpC3/OKpZY6avIqZp7+
# 8pP/WQP903DdgrvAT6W4xPOBxXPa4tGksN3SuqJaiFYHSNyeBufn8iseujW4IbBS
# bHD4BPqbF3qZ+7nG9d/d/G2/Lx4kH9cCmBfmsZdSkHmukDCCB54wggWGoAMCAQIC
# EzMAAAAHh6M0o3uljhwAAAAAAAcwDQYJKoZIhvcNAQEMBQAwdzELMAkGA1UEBhMC
# VVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjFIMEYGA1UEAxM/TWlj
# cm9zb2Z0IElkZW50aXR5IFZlcmlmaWNhdGlvbiBSb290IENlcnRpZmljYXRlIEF1
# dGhvcml0eSAyMDIwMB4XDTIxMDQwMTIwMDUyMFoXDTM2MDQwMTIwMTUyMFowYzEL
# MAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjE0MDIG
# A1UEAxMrTWljcm9zb2Z0IElEIFZlcmlmaWVkIENvZGUgU2lnbmluZyBQQ0EgMjAy
# MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALLwwK8ZiCji3VR6TEls
# aQhVCbRS/3pK+MHrJSj3Zxd3KU3rlfL3qrZilYKJNqztA9OQacr1AwoNcHbKBLbs
# QAhBnIB34zxf52bDpIO3NJlfIaTE/xrweLoQ71lzCHkD7A4As1Bs076Iu+mA6cQz
# sYYH/Cbl1icwQ6C65rU4V9NQhNUwgrx9rGQ//h890Q8JdjLLw0nV+ayQ2Fbkd242
# o9kH82RZsH3HEyqjAB5a8+Ae2nPIPc8sZU6ZE7iRrRZywRmrKDp5+TcmJX9MRff2
# 41UaOBs4NmHOyke8oU1TYrkxh+YeHgfWo5tTgkoSMoayqoDpHOLJs+qG8Tvh8Sni
# fW2Jj3+ii11TS8/FGngEaNAWrbyfNrC69oKpRQXY9bGH6jn9NEJv9weFxhTwyvx9
# OJLXmRGbAUXN1U9nf4lXezky6Uh/cgjkVd6CGUAf0K+Jw+GE/5VpIVbcNr9rNE50
# Sbmy/4RTCEGvOq3GhjITbCa4crCzTTHgYYjHs1NbOc6brH+eKpWLtr+bGecy9Crw
# Qyx7S/BfYJ+ozst7+yZtG2wR461uckFu0t+gCwLdN0A6cFtSRtR8bvxVFyWwTtgM
# MFRuBa3vmUOTnfKLsLefRaQcVTgRnzeLzdpt32cdYKp+dhr2ogc+qM6K4CBI5/j4
# VFyC4QFeUP2YAidLtvpXRRo3AgMBAAGjggI1MIICMTAOBgNVHQ8BAf8EBAMCAYYw
# EAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFNlBKbAPD2Ns72nX9c0pnqRIajDm
# MFQGA1UdIARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wGQYJKwYBBAGC
# NxQCBAweCgBTAHUAYgBDAEEwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTI
# ftJqhSobyhmYBAcnz1AQT2ioojCBhAYDVR0fBH0wezB5oHegdYZzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSWRlbnRpdHkl
# MjBWZXJpZmljYXRpb24lMjBSb290JTIwQ2VydGlmaWNhdGUlMjBBdXRob3JpdHkl
# MjAyMDIwLmNybDCBwwYIKwYBBQUHAQEEgbYwgbMwgYEGCCsGAQUFBzAChnVodHRw
# Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElk
# ZW50aXR5JTIwVmVyaWZpY2F0aW9uJTIwUm9vdCUyMENlcnRpZmljYXRlJTIwQXV0
# aG9yaXR5JTIwMjAyMC5jcnQwLQYIKwYBBQUHMAGGIWh0dHA6Ly9vbmVvY3NwLm1p
# Y3Jvc29mdC5jb20vb2NzcDANBgkqhkiG9w0BAQwFAAOCAgEAfyUqnv7Uq+rdZgrb
# VyNMul5skONbhls5fccPlmIbzi+OwVdPQ4H55v7VOInnmezQEeW4LqK0wja+fBzn
# ANbXLB0KrdMCbHQpbLvG6UA/Xv2pfpVIE1CRFfNF4XKO8XYEa3oW8oVH+KZHgIQR
# IwAbyFKQ9iyj4aOWeAzwk+f9E5StNp5T8FG7/VEURIVWArbAzPt9ThVN3w1fAZkF
# 7+YU9kbq1bCR2YD+MtunSQ1Rft6XG7b4e0ejRA7mB2IoX5hNh3UEauY0byxNRG+f
# T2MCEhQl9g2i2fs6VOG19CNep7SquKaBjhWmirYyANb0RJSLWjinMLXNOAga10n8
# i9jqeprzSMU5ODmrMCJE12xS/NWShg/tuLjAsKP6SzYZ+1Ry358ZTFcx0FS/mx2v
# SoU8s8HRvy+rnXqyUJ9HBqS0DErVLjQwK8VtsBdekBmdTbQVoCgPCqr+PDPB3xaj
# Ynzevs7eidBsM71PINK2BoE2UfMwxCCX3mccFgx6UsQeRSdVVVNSyALQe6PT1241
# 8xon2iDGE81OGCreLzDcMAZnrUAx4XQLUz6ZTl65yPUiOh3k7Yww94lDf+8oG2oZ
# mDh5O1Qe38E+M3vhKwmzIeoB1dVLlz4i3IpaDcR+iuGjH2TdaC1ZOmBXiCRKJLj4
# DT2uhJ04ji+tHD6n58vhavFIrmcxghqxMIIarQIBATBxMFoxCzAJBgNVBAYTAlVT
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jv
# c29mdCBJRCBWZXJpZmllZCBDUyBFT0MgQ0EgMDMCEzMACU/BnRQ1mD4ovTYAAAAJ
# T8EwDQYJYIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQg3uv+kuWZO4htqgF5e7v8
# W7eKdWD8Qf7ohItYrA4I66MwDQYJKoZIhvcNAQEBBQAEggGAR5GqOT5V+RVfnvsX
# KzJzr5atZtx7BNvtd6eJ9nFdKbxJSlrabj+Nhgj+QqKmXQIdl/RXspZQ1x+b+98I
# yJIhjPijtlJ318VP+1E0Eqf98uezSUS6hQK0M+oJ0C7MPiaJlZW1AmRwghMyQFkv
# B5Rio2bxcyPrsg5oOOQVbndl0JObQ/wi6waatTcmrlZikDLAmop9MImaDLg66jUD
# iQdJiddooFspPxp+5UgMMzoZJtbFr5Zx/OmDx6e5+DswmgEe+njvL1/XEv9PYeuU
# dV5Rn1dDGOhaMNUuQ5wBF7OKn50FYT1zI45leTGfR3V77kRsm1OiYYMuPKZ83jEl
# n4Ux9z4mXyA83T+GpmWX1MNPTxpHtlGy/0Xj5wjjKDQ57Gri4poIvmMYG09HplLD
# 3ZE5MrG67rmnErJDRR03cVt9yBwn4j/W7K1ncVw05bmFrtYqavmumN0140Sl0loI
# FrOgxe+vQdiBwGDC3b9MyeY9tdUm/YuyagFcjZuv9REZpxHboYIYMTCCGC0GCisG
# AQQBgjcDAwExghgdMIIYGQYJKoZIhvcNAQcCoIIYCjCCGAYCAQMxDzANBglghkgB
# ZQMEAgIFADCCAXIGCyqGSIb3DQEJEAEEoIIBYQSCAV0wggFZAgEBBgorBgEEAYRZ
# CgMBMEEwDQYJYIZIAWUDBAICBQAEMPC3ZVi1/A5A/pkU0BP1+pITqWQxeY2hr7Pl
# CLnldwmKTni701VLhAnAKyP+Uh/yEgIGattNkyQGGBMyMDI2MTAyNzE4MTUxNC43
# NjVaMASAAgH0oIHhpIHeMIHbMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScw
# JQYDVQQLEx5uU2hpZWxkIFRTUyBFU046N0EwMC0wNUUwLUQ5NDcxNTAzBgNVBAMT
# LE1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWUgU3RhbXBpbmcgQXV0aG9yaXR5oIIP
# ITCCB4IwggVqoAMCAQICEzMAAAAF5c8P/2YuyYcAAAAAAAUwDQYJKoZIhvcNAQEM
# BQAwdzELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjFIMEYGA1UEAxM/TWljcm9zb2Z0IElkZW50aXR5IFZlcmlmaWNhdGlvbiBSb290
# IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDIwMB4XDTIwMTExOTIwMzIzMVoXDTM1
# MTExOTIwNDIzMVowYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0
# YW1waW5nIENBIDIwMjAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCe
# fOdSY/3gxZ8FfWO1BiKjHB7X55cz0RMFvWVGR3eRwV1wb3+yq0OXDEqhUhxqoNv6
# iYWKjkMcLhEFxvJAeNcLAyT+XdM5i2CgGPGcb95WJLiw7HzLiBKrxmDj1EQB/mG5
# eEiRBEp7dDGzxKCnTYocDOcRr9KxqHydajmEkzXHOeRGwU+7qt8Md5l4bVZrXAhK
# +WSk5CihNQsWbzT1nRliVDwunuLkX1hyIWXIArCfrKM3+RHh+Sq5RZ8aYyik2r8H
# xT+l2hmRllBvE2Wok6IEaAJanHr24qoqFM9WLeBUSudz+qL51HwDYyIDPSQ3SeHt
# Kog0ZubDk4hELQSxnfVYXdTGncaBnB60QrEuazvcob9n4yR65pUNBCF5qeA4QwYn
# ilBkfnmeAjRN3LVuLr0g0FXkqfYdUmj1fFFhH8k8YBozrEaXnsSL3kdTD01X+4Lf
# IWOuFzTzuoslBrBILfHNj8RfOxPgjuwNvE6YzauXi4orp4Sm6tF245DaFOSYbWFK
# 5ZgG6cUY2/bUq3g3bQAqZt65KcaewEJ3ZyNEobv35Nf6xN6FrA6jF9447+NHvCje
# WLCQZ3M8lgeCcnnhTFtyQX3XgCoc6IRXvFOcPVrr3D9RPHCMS6Ckg8wggTrtIVnY
# 8yjbvGOUsAdZbeXUIQAWMs0d3cRDv09SvwVRd61evQIDAQABo4ICGzCCAhcwDgYD
# VR0PAQH/BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRraSg6NS9I
# Y0DPe9ivSek+2T3bITBUBgNVHSAETTBLMEkGBFUdIAAwQTA/BggrBgEFBQcCARYz
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnku
# aHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIA
# QwBBMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUyH7SaoUqG8oZmAQHJ89Q
# EE9oqKIwgYQGA1UdHwR9MHsweaB3oHWGc2h0dHA6Ly93d3cubWljcm9zb2Z0LmNv
# bS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMElkZW50aXR5JTIwVmVyaWZpY2F0aW9u
# JTIwUm9vdCUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5JTIwMjAyMC5jcmwwgZQG
# CCsGAQUFBwEBBIGHMIGEMIGBBggrBgEFBQcwAoZ1aHR0cDovL3d3dy5taWNyb3Nv
# ZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJZGVudGl0eSUyMFZlcmlm
# aWNhdGlvbiUyMFJvb3QlMjBDZXJ0aWZpY2F0ZSUyMEF1dGhvcml0eSUyMDIwMjAu
# Y3J0MA0GCSqGSIb3DQEBDAUAA4ICAQBfiHbHfm21WhV150x4aPpO4dhEmSUVpbix
# NDmv6TvuIHv1xIs174bNGO/ilWMm+Jx5boAXrJxagRhHQtiFprSjMktTliL4sKZy
# t2i+SXncM23gRezzsoOiBhv14YSd1Klnlkzvgs29XNjT+c8hIfPRe9rvVCMPiH7z
# PZcw5nNjthDQ+zD563I1nUJ6y59TbXWsuyUsqw7wXZoGzZwijWT5oc6GvD3HDokJ
# Y401uhnj3ubBhbkR83RbfMvmzdp3he2bvIUztSOuFzRqrLfEvsPkVHYnvH1wtYyr
# t5vShiKheGpXa2AWpsod4OJyT4/y0dggWi8g/tgbhmQlZqDUf3UqUQsZaLdIu/XS
# jgoZqDjamzCPJtOLi2hBwL+KsCh0Nbwc21f5xvPSwym0Ukr4o5sCcMUcSy6TEP7u
# MV8RX0eH/4JLEpGyae6Ki8JYg5v4fsNGif1OXHJ2IWG+7zyjTDfkmQ1snFOTgyEX
# 8qBpefQbF0fx6URrYiarjmBprwP6ZObwtZXJ23jK3Fg/9uqM3j0P01nzVygTppBa
# bzxPAh/hHhhls6kwo3QLJ6No803jUsZcd4JQxiYHHc+Q/wAMcPUnYKv/q2O444LO
# 1+n6j01z5mggCSlRwD9faBIySAcA9S8h22hIAcRQqIGEjolCK9F6nK9ZyX4lhths
# GHumaABdWzCCB5cwggV/oAMCAQICEzMAAABdxjl4T0B9M/0AAAAAAF0wDQYJKoZI
# hvcNAQEMBQAwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1w
# aW5nIENBIDIwMjAwHhcNMjYwOTE3MTg1NzIxWhcNMjcwOTE0MTg1NzIxWjCB2zEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWlj
# cm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1Mg
# RVNOOjdBMDAtMDVFMC1EOTQ3MTUwMwYDVQQDEyxNaWNyb3NvZnQgUHVibGljIFJT
# QSBUaW1lIFN0YW1waW5nIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAJ33qNzxFA+JrOqDscZ6+dPsV7GCAvPbhBo9jDI14cLJpN9SETe7
# u3YkVsVK9T31amVEEsKSdDZQeDaeSJqUNsIqOzGwBLuxk/X8NlZRiQXWpxvO4DSi
# ka/dYqVOkfh0tr7JhkgJF9bioPywLlLbWfRzJOCGT7do8j/1LFMTQfDBLA2/tY1T
# g0pLAxmcrTdiJhfOVG2fOLABs5CMGqR41YyyDnCNO537p6f/KbGA/peBuk01fkCP
# SsgSqRxoPeOcReQY7vI6O2rjz5x7zEo9ocxn52SsPBZT6pgHqblwpWUb6b7ahzy8
# 3um4DC0SMvUf0hsm/0++9t4vQmrxeVcTNdURAbwXDULV9UL2d81qjD6ZPbuLCoJ2
# nFVaweldvs9YJeT4mhG0OpP+7IovdJu27sqdZ4T8bVWrqd7qdub7NJADmjiTzp8x
# uLmQrAdDR/PhBDQFggz+j88S51ZmyicHcnQkVtEPKi/ksiHSVzKysfOXODEza9IZ
# p45mrUVj/JTIo+nnSGFjy8SFseXSTmJ+GlRJheRnhQKGUSscz0MNY31EJxAO8SdP
# qJaR2z30G8YvJNgTi0pUMx0ebwGtquF/l+yj4F1fz0SDmCZ1LikqppNEstixJHwa
# 32fb9+aqb+UGBR/A1hr0oRoJWbAbiTCF1SyMk9bIhCfPX2JgLDDN/YzNAgMBAAGj
# ggHLMIIBxzAdBgNVHQ4EFgQUQ9sKXZlO8H4eVu395ahoyH9a57kwHwYDVR0jBBgw
# FoAUa2koOjUvSGNAz3vYr0npPtk92yEwbAYDVR0fBGUwYzBhoF+gXYZbaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwUHVibGlj
# JTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0ElMjAyMDIwLmNybDB5BggrBgEFBQcB
# AQRtMGswaQYIKwYBBQUHMAKGXWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY2VydHMvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNBJTIwVGltZXN0YW1waW5n
# JTIwQ0ElMjAyMDIwLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMA4GA1UdDwEB/wQEAwIHgDBmBgNVHSAEXzBdMFEGDCsGAQQBgjdMg30B
# ATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L0RvY3MvUmVwb3NpdG9yeS5odG0wCAYGZ4EMAQQCMA0GCSqGSIb3DQEBDAUAA4IC
# AQBCyETwKcMu124k4eFobUOoCnyXigtf6RyVDV/gjL73YFfBXoO6OKWgOJv6QrNP
# rzcQfy0kC60s42YCa4aUWgE04toodo2lHJ9dimsX2vgY1RzMrHyGIxmPRoSJWmUd
# ZvrD2pLYnqaX/KyM/5V/Plse6M4GhRGJ1NO+kerQmxd1cTufwcm1K1xzCDKHDbUG
# e3kLR3MBNsIKLaBs5s9LlNoCYi+51r5eH2rQlHLTlgQmDh/dK073VDjdPlbQAaWr
# P5oV7q0MqQVVmyEz4q3XB4hKgHtinFBzAnmswbFL4R3yLENCsR3iDwA6WCZFUTTM
# QQooIQ6IrbBy0F++P+HCJPMSj6OgkOXmNQFCLlmOg4l0OBZo1ToPoCBDIng8jkIr
# pJjE3THOmCt5GB/128sZElCs7Ohq/B5JAWYlN7Mi5HtwmnXrynaP4RV0j2bi1lr1
# eYY6N2nfMeD4N6FqLh/bz/sJq6w81Smv6Zx0WEZAonPpSSgjHPuCBXPMPYOUgpKF
# Pp+JwsYMAjuvKj8mnLNThsZVat+MH8MHQiCzEe3LTOb6Anz+q+xuu1+D1H11uQyc
# KOmR3ndc66EY+IyGsWeS/SDZ7kvXFWpXcK/jWCJuZ5ObEACcwae7ulG78hm7Vl2D
# zbcdib7/ETWE08z6mhWidmM5mmDrbOQGw78kR9rzYcmTSjGCB1MwggdPAgEBMHgw
# YTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEy
# MDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIw
# MjACEzMAAABdxjl4T0B9M/0AAAAAAF0wDQYJYIZIAWUDBAICBQCgggSsMBEGCyqG
# SIb3DQEJEAIPMQIFADAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZI
# hvcNAQkFMQ8XDTI2MTAyNzE4MTUxNFowPwYJKoZIhvcNAQkEMTIEMPQpy2GYyfM+
# Da5dzSXsaDqbHj6rY5suuRufT8x1+Nd52MFJ7ceZjZugMn3+1OiCzTCBuQYLKoZI
# hvcNAQkQAi8xgakwgaYwgaMwgaAEIC01ZEtv6fPuQmKhZadGormGhQBDXm/cy+sX
# vdzEAkpdMHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVz
# dGFtcGluZyBDQSAyMDIwAhMzAAAAXcY5eE9AfTP9AAAAAABdMIIDXgYLKoZIhvcN
# AQkQAhIxggNNMIIDSaGCA0UwggNBMIICKQIBATCCAQmhgeGkgd4wgdsxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29m
# dCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo3
# QTAwLTA1RTAtRDk0NzE1MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGlt
# ZSBTdGFtcGluZyBBdXRob3JpdHmiIwoBATAHBgUrDgMCGgMVAL2nurW1sYDPB2jA
# bA8RxJrMlpD1oGcwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRp
# bWVzdGFtcGluZyBDQSAyMDIwMA0GCSqGSIb3DQEBCwUAAgUA7osSDjAiGA8yMDI2
# MTAyNzEyMDUzNFoYDzIwMjYxMDI4MTIwNTM0WjB0MDoGCisGAQQBhFkKBAExLDAq
# MAoCBQDuixIOAgEAMAcCAQACAgt1MAcCAQACAhK5MAoCBQDujGOOAgEAMDYGCisG
# AQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMB
# hqAwDQYJKoZIhvcNAQELBQADggEBAFhDWWQv+3QLEW37wA8PwAJEuuE9i0mYNaFd
# UsL5eP6EFdEKeKdGSyrBk+MDIzDw/RIjtoWP9fAGd724z+joLCJnaAYoeszc1YW1
# qMCegb7lW/VJq4NHLC2ta2k5X5yrl3NsXkeqlgpLJ0ynAduzzhRTSC6ZOVukvedt
# 0AJjoj5mKaVLy8S7QkuA07FGa3XDacboQIwk4TBsszvN3aaMurNuuMI9Tjckg6ox
# o/B2k5SUjkV2ECcFiwbAqgy9g26YbDNSd4Xda059v8blHKj0yNoO3f6yKBz5KZYu
# TbZX48zPhF9MOq0VtyjeG/WZcL4ymAVCxl7dbw8DvwjSX1A+b6kwDQYJKoZIhvcN
# AQEBBQAEggIAj/4b/VXi3Q+SaZ2njXs+7Ci9sNYynAgGwCBN+/8N8DiiakkugU92
# mzED/RvVeoZOCbLNQip3JDwyMo1J9WwerTi/1rZUUdr2XN8PrF3mJapPs7T7dxTj
# FtEXN7aBwe0NquRSVugl0Rb4Pv2Wf7su8MOiHxKgi1iWIkCQ8txMOcXLZ1dNfPef
# a9pslCy801rz6Ig3C1SzRHwNnhAYj1Y2kgKlBkE0vmxWh0lgziY6opalQD6WscXu
# BYrJzDNR7ckBhI1s3hPzhoDymUTmQTu/lAAHaR9OUDfrhFpLGhUxySiPFBlA9Mfx
# 11ba2mIcTFyq/+QRktbRHYpCZbwulvXYDeyXuygQ5qhdFZI55Ij+NetDQJyztpr+
# kTamCf/5qsTTE9iUQgUkTHvY3lI1YUIIdSBR+JjSiF9ivFd5+9+fQ+vRPsSwJuaY
# KyKb8x0M2eRNCfQvJwEpPkZauRsiXpcf+oNLk0+IC9fbVKFKyPGLSyufDLQV2dKD
# OSygKLPAZ29HS2SsWR56Sw59WRoMw/1npOxyPqtzOMQFtt+MK6z6GADJfm9tX/5v
# 9aX7v212OiHs9qZvQosgXIbrjQYTwmr8HjjXPayS9vkRke6cKkLdrzjcmhHSmjCc
# Ql03zLabzDaka64ghjP3RhRBKCeE1aY+NrSufbg+hTa+vJJ5ntIowdo=
# SIG # End signature block
