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
# MII9SAYJKoZIhvcNAQcCoII9OTCCPTUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
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
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggaiMIIEiqADAgECAhMzAAayq65S
# NPkDTYyqAAAABrKrMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBFT0MgQ0EgMDQwHhcNMjYwOTIyMDU1NTM2WhcNMjYwOTI1
# MDU1NTM2WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAr2YC
# UHAxoHbqBllRK4WOEHygT4M+DSAM4t64np968ILwOGwlZ0n8Lv724y6AtlNOantP
# Su1Izk9qn9TTZYYdL3oRXlMkGckA1JgD6BJLMhRYmEr5kqGageXiCOABEl0R8DPx
# GK4r6kMPFw18nQKHCJCKwI1nGKBK062g1a8cu4z/vKOPllJHZA4cIhQyZm6xzPc0
# n7TR9+3Y7if2MF5bwMW0VhD2W4NQL0WP1WVi5mpfbdloIAsVjmLoeor+f5xxfids
# CAo6ZRpDlhAAeJzIpdJC66upcuoIeL+zR4YStPl8nJITajLVU8upwu+2jg+WJV3b
# r8dfxe6rjYcPxDZrrhdK9g3qxfDN9hDURisx5uj90pn7pUyow7q3WyR5PmI/dMv1
# dgjrsa7bPtE7kx6JUmoNYvQajKFhke435EIh3oEcfqF0QNGPUYceaZN2SzUsL8JC
# S5wttBZxsf5omF1AAKcG8PFD3e9wtdzAha2+37/3cfajb98vVffQp2mxDrmBAgMB
# AAGjggHWMIIB0jAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQUSeYazyZCjFMlGgg8n6rda+ajRAUwHwYDVR0jBBgw
# FoAUmvFUd3UMhxY3RqCs3nn59H/BeOkwZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwRU9DJTIwQ0ElMjAwNC5jcmwwdAYIKwYBBQUHAQEEaDBm
# MGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Nl
# cnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIw
# MDQuY3J0MFQGA1UdIARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wDQYJ
# KoZIhvcNAQEMBQADggIBAHEYqWrJ75v2eJNCAciayU1gdnIlM11hasjKKdPOmoCY
# NOvViDDPxkuqFS2Og2HjxQ4T0r6XUgDHCaYWWvCuyhMu16wE7H0GTlLq9Ksk15o0
# NlJy6+Er0w//JJRkBKVN0d7r10Zcbb5mMbEw6V3y6DKs+9tfLuT8eFuQg4UJtsbU
# lB3HzuA1vO5h5F/cIghiuv0KMvgLMR/uKBJksbAhAMdLdh/+VBugrbyj1doKA4vZ
# naosTC/lZbBIJ6h4PUqe/EsoMMJdTFIIKxGMlcAXM2P+0QiWk5cHXc/SJk/B822+
# knKVBoyNeyfnINDqM/K0wrGDaQwx23xEaCvy3TdCgY98ZihMP3a3hOPfrA0Obwiv
# RCoGIq0tOllD9vFa95C49CSZPhb3VaBRNe+KcvamNQq91b/945CUgV9ainiYUOC+
# xwo0sYFXYxqmmeH0fpzAmWZ9nGPqckKStQS1HNHfYOyY73Gxk+HvXzGYyHZcabow
# +r4XQkNRMb63ddOzsWcebfogfO7uFu7mpXXa+CPZZpzrnCvhnnt8rL7a60FTKxPe
# P6hhq17+Fea/fr1gNm9IeYmkIEimmN6C840KZwy4UMc5g6NNcp9GORxwyVKOXYC1
# eKKkdwHP5tdhlBIck/69EdpaJgR9gK64LmopPGKyej5vdGdWPKbDZHaJjUV8mMSS
# MIIGojCCBIqgAwIBAgITMwAGsquuUjT5A02MqgAAAAayqzANBgkqhkiG9w0BAQwF
# ADBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgRU9DIENBIDA0MB4X
# DTI2MDkyMjA1NTUzNloXDTI2MDkyNTA1NTUzNlowYzELMAkGA1UEBhMCVVMxFzAV
# BgNVBAgTDk5vcnRoIENhcm9saW5hMQ0wCwYDVQQHEwRDYXJ5MRUwEwYDVQQKEwxN
# b25kb28sIEluYy4xFTATBgNVBAMTDE1vbmRvbywgSW5jLjCCAaIwDQYJKoZIhvcN
# AQEBBQADggGPADCCAYoCggGBAK9mAlBwMaB26gZZUSuFjhB8oE+DPg0gDOLeuJ6f
# evCC8DhsJWdJ/C7+9uMugLZTTmp7T0rtSM5Pap/U02WGHS96EV5TJBnJANSYA+gS
# SzIUWJhK+ZKhmoHl4gjgARJdEfAz8RiuK+pDDxcNfJ0ChwiQisCNZxigStOtoNWv
# HLuM/7yjj5ZSR2QOHCIUMmZuscz3NJ+00fft2O4n9jBeW8DFtFYQ9luDUC9Fj9Vl
# YuZqX23ZaCALFY5i6HqK/n+ccX4nbAgKOmUaQ5YQAHicyKXSQuurqXLqCHi/s0eG
# ErT5fJySE2oy1VPLqcLvto4PliVd26/HX8Xuq42HD8Q2a64XSvYN6sXwzfYQ1EYr
# Mebo/dKZ+6VMqMO6t1skeT5iP3TL9XYI67Gu2z7RO5MeiVJqDWL0GoyhYZHuN+RC
# Id6BHH6hdEDRj1GHHmmTdks1LC/CQkucLbQWcbH+aJhdQACnBvDxQ93vcLXcwIWt
# vt+/93H2o2/fL1X30KdpsQ65gQIDAQABo4IB1jCCAdIwDAYDVR0TAQH/BAIwADAO
# BgNVHQ8BAf8EBAMCB4AwPQYDVR0lBDYwNAYKKwYBBAGCN2EBAAYIKwYBBQUHAwMG
# HCsGAQQBgjdhgqndkVaCp5bkUoGRmP1vg9zbqyowHQYDVR0OBBYEFEnmGs8mQoxT
# JRoIPJ+q3Wvmo0QFMB8GA1UdIwQYMBaAFJrxVHd1DIcWN0agrN55+fR/wXjpMGcG
# A1UdHwRgMF4wXKBaoFiGVmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIw
# MDQuY3JsMHQGCCsGAQUFBwEBBGgwZjBkBggrBgEFBQcwAoZYaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlm
# aWVkJTIwQ1MlMjBFT0MlMjBDQSUyMDA0LmNydDBUBgNVHSAETTBLMEkGBFUdIAAw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMA0GCSqGSIb3DQEBDAUAA4ICAQBxGKlqye+b9niT
# QgHImslNYHZyJTNdYWrIyinTzpqAmDTr1Ygwz8ZLqhUtjoNh48UOE9K+l1IAxwmm
# FlrwrsoTLtesBOx9Bk5S6vSrJNeaNDZScuvhK9MP/ySUZASlTdHe69dGXG2+ZjGx
# MOld8ugyrPvbXy7k/HhbkIOFCbbG1JQdx87gNbzuYeRf3CIIYrr9CjL4CzEf7igS
# ZLGwIQDHS3Yf/lQboK28o9XaCgOL2Z2qLEwv5WWwSCeoeD1KnvxLKDDCXUxSCCsR
# jJXAFzNj/tEIlpOXB13P0iZPwfNtvpJylQaMjXsn5yDQ6jPytMKxg2kMMdt8RGgr
# 8t03QoGPfGYoTD92t4Tj36wNDm8Ir0QqBiKtLTpZQ/bxWveQuPQkmT4W91WgUTXv
# inL2pjUKvdW//eOQlIFfWop4mFDgvscKNLGBV2Mappnh9H6cwJlmfZxj6nJCkrUE
# tRzR32DsmO9xsZPh718xmMh2XGm6MPq+F0JDUTG+t3XTs7FnHm36IHzu7hbu5qV1
# 2vgj2Wac65wr4Z57fKy+2utBUysT3j+oYate/hXmv369YDZvSHmJpCBIppjegvON
# CmcMuFDHOYOjTXKfRjkccMlSjl2AtXiipHcBz+bXYZQSHJP+vRHaWiYEfYCuuC5q
# KTxisno+b3RnVjymw2R2iY1FfJjEkjCCBygwggUQoAMCAQICEzMAAAAXJ0UJC4uH
# r8YAAAAAABcwDQYJKoZIhvcNAQEMBQAwYzELMAkGA1UEBhMCVVMxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjE0MDIGA1UEAxMrTWljcm9zb2Z0IElEIFZl
# cmlmaWVkIENvZGUgU2lnbmluZyBQQ0EgMjAyMTAeFw0yNjAzMjYxODExMzFaFw0z
# MTAzMjYxODExMzFaMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJpZmllZCBDUyBF
# T0MgQ0EgMDQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCCx2T+Aw9m
# KgGVzJ+Tq0PMn49G3itIsYpbx7ClLSRHFe1RELdPcZ1sIqWOhsSfy6yyqEapClGH
# 9Je9FXA1cQgZvvpQbkg+QInVLr/0EPrVBCwrM96lbRI2PxNeCwXG9LsyW2hG6KQg
# intDmNCBo4zpDIr377plVdSliZm6UB7rHwmvBnR02QT6tnrqWq2ihzB6lRJVTEzu
# h0OafzIMeMnYM0+x+ve5EOLHdfiq+HXiMf9Jb7YLHtYgyHIiJA7bTWLqFSLGaTh7
# ZlbxbsLXA91OOroEpv7OjzFuu3tkpC9FflA4Dp2Euq4+qPmxUqfGp+TX0gLRJp9N
# JOzzILjcTD3rkFFFbxUv1xyg6avivFDLtoKBhM2Td138umE1pNOacanuSYtPHIeQ
# HmB6haFi64avLBLwTTAm/Rbit860cFXR72wq+5Qh4hSmezHqKXERWPpVBe+APrJ4
# Iqc+aPeMmIkoCWZQO22HnLNFUFSXjiwyIbgvlH/LIAJEqTafTzxDZgKhlLU7zr6g
# wsq3WNpcYQI6NuxWnwh3VVDDyF7onQqKs5Ll7bleVN0Y8VvqgE45ppyBbvwqN/Ru
# n5fMCCRz3aYMY0kZhKO92eP7t4zHqZ5bQMAgZ0tE2Pz/jb0wiykUF/PcoOqqk3vV
# LiRDYst6vd3GEMNzMpUUvQcvBG46+COIbwIDAQABo4IB3DCCAdgwDgYDVR0PAQH/
# BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBSa8VR3dQyHFjdGoKze
# efn0f8F46TBUBgNVHSAETTBLMEkGBFUdIAAwQTA/BggrBgEFBQcCARYzaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBkG
# CSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMBIGA1UdEwEB/wQIMAYBAf8CAQAwHwYD
# VR0jBBgwFoAU2UEpsA8PY2zvadf1zSmepEhqMOYwcAYDVR0fBGkwZzBloGOgYYZf
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIw
# SUQlMjBWZXJpZmllZCUyMENvZGUlMjBTaWduaW5nJTIwUENBJTIwMjAyMS5jcmww
# fQYIKwYBBQUHAQEEcTBvMG0GCCsGAQUFBzAChmFodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBD
# b2RlJTIwU2lnbmluZyUyMFBDQSUyMDIwMjEuY3J0MA0GCSqGSIb3DQEBDAUAA4IC
# AQCQdVoZ/U0m38l2iKaZFlsxavptpoOLyaR1a9ZK2TSF1kOnFJhMDse6KkCgsveo
# iEjXTVc6Xt86IKHn76Nk5qZB0BXv2iMRQ2giAJmYvZcmstoZqfB2M3Kd5wnJhUJO
# tF/b6HsqSelY6nhrF06zor1lDmDQixBZcLB9zR1+RKQso1jekNxYuUk+HaN3k1S5
# 7qk0O//YbkwU0mELCW04N5vICMZx5T5c7Nq/7uLvbVhCdD7f2bZpA4U7vOkB1ooB
# 4AaER3pjoJ0Mad5LFyi6Na9p9Zu/hrLeOjU5FItS5YxsqvlfXxAThJ176CmkYstK
# RmytSHZ7JhKRfV6e9Zftk/ODb/CK4pGVAVqsOf4337bQGrOHHCQ3IvN9gmnUuDh8
# JdvbheoWPHxIN1GB5sUiY584tXN7xdD8LCSsRqJvQ8e7a3gZWTgViugRs1QWq+N0
# G9Nje6JHlN1CjJehge+H5PGktJja+juGEr0P+ukSkcL6qaZxFQTh3SDI71lvW++3
# bl/Ezd6SO8N9Udw+reoyvRHCyTiSsplZQSBTVJdPmo3qCpGuyHFtPo5CBn3/FPTi
# qJd3M9BHoqKd0G9Kmg6fGcAvFwnLNXA2kov727wRljL3ypfqL7iAT/Ynpxul6RwH
# RlcOf9dDGg1RRvr92NP/CWVXIb68geR2rvU/NsfmtjF1wDCCB54wggWGoAMCAQIC
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
# DT2uhJ04ji+tHD6n58vhavFIrmcxghq0MIIasAIBATBxMFoxCzAJBgNVBAYTAlVT
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jv
# c29mdCBJRCBWZXJpZmllZCBDUyBFT0MgQ0EgMDQCEzMABrKrrlI0+QNNjKoAAAAG
# sqswDQYJYIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQg3uv+kuWZO4htqgF5e7v8
# W7eKdWD8Qf7ohItYrA4I66MwDQYJKoZIhvcNAQEBBQAEggGAjQ4fF4y4+RwkDYFn
# s0LUPiE+6xuYphtzPsjI9zeitzGPzIFV+ZWmqs48+AmUSA9uCLzFvvD/aE7p8wpF
# ETGDSkuk11I7XnLJrtAe5R2oAslzxWx3vPUeQbaT7K7EkOyu+/6VPOATscIDMpKo
# mrdk1AXxIZafgVqsEEGm6k5e0YaCAA0xhXSdLGCh6YbeDgzT5UyJJCaKndM8gY/B
# vPY7eYhms/Noe7mUBesutUXC+iNoFEgVlmVxqZgqcHj8fAfricO4dOTy5G6raEYw
# emE3N2nuTQ8g1P8D8zjn93792yz6HL0wY4UnWAa38Xli12Rn0cHjEfYCS9HB+4jy
# isHZ537eSL0qT+ugr+Y0NGAwLsZs5g8enmv73w9jSr2alvRzOtweRbouMWGth4fP
# diwrvQmHi2ZA6W+lEUrUAih5hxHtuLHY+dEqP5HSlQq4+TA8KScdf38vf1Bc6VKC
# 0JdnHnsJPBWwb1XIe7uhAZZJ491lqsbsdkg4fFgFsWHAzyQ0oYIYNDCCGDAGCisG
# AQQBgjcDAwExghggMIIYHAYJKoZIhvcNAQcCoIIYDTCCGAkCAQMxDzANBglghkgB
# ZQMEAgIFADCCAXIGCyqGSIb3DQEJEAEEoIIBYQSCAV0wggFZAgEBBgorBgEEAYRZ
# CgMBMEEwDQYJYIZIAWUDBAICBQAEMPqZWhhdnD1FfL7oO4xJZBzZsC7Yre6caPcW
# JIEjJ7wsjcyYTd2MnFyFh7i1/GKHFgIGaqkzkWC4GBMyMDI2MDkyMzA5MjUyNC4y
# NjFaMASAAgH0oIHhpIHeMIHbMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScw
# JQYDVQQLEx5uU2hpZWxkIFRTUyBFU046QTUwMC0wNUUwLUQ5NDcxNTAzBgNVBAMT
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
# GHumaABdWzCCB5cwggV/oAMCAQICEzMAAABWfo+dWAiO6WAAAAAAAFYwDQYJKoZI
# hvcNAQEMBQAwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1w
# aW5nIENBIDIwMjAwHhcNMjUxMDIzMjA0NjUxWhcNMjYxMDIyMjA0NjUxWjCB2zEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWlj
# cm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1Mg
# RVNOOkE1MDAtMDVFMC1EOTQ3MTUwMwYDVQQDEyxNaWNyb3NvZnQgUHVibGljIFJT
# QSBUaW1lIFN0YW1waW5nIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBALSln5v7pdNu/3fEZW/DJ/4NEFL7y6mNlbMt7SPFNrRUrKU2aJmT
# g9wR0/C5Efka4TCYG9VYwChTcrGivXC0l4nzxkiAazwoLPT+MtuJayRJq1ekOc+A
# ZqjISD62YRL2Z1qQkuBzu42Enov58Zgu/9RK/peS4Nz5ksW/HdiFXAEcUsNQeJsQ
# elyNJ5HpfcGtXWG9sHxqaH62hZsWTsU/XjYbeCx9EQUlbnm2umTaY0v9ILX5u6oi
# Isj+qej0c002zJ1arB51f3f61tMx8fkPkDWecFKipk2SQfYVPOd/tqV+aw3yt9rj
# WPf1gTgJs26oKRHUJG4jGr1DMlA0oZsnCL4B3UJ0ttO7E4/DPpCS97TnWoT7j6jM
# LGggoHX8MEMdDvUynuxUr2wBGLNQJ5XQpfyhxmQjlb1Dao8i9dCS3tP/hg/f8p6l
# xlhaVzo2rp72f3CkToYzeDOXuscdG9poqnD4ouP4otmYXimpZSRE+wipaRUobN8M
# oOhf36I0MULz521g+DcsepYY1o8JqC3MesNRUgrWrywpct9wS0UpU1OKilMWmvHe
# 2DexKqZ/VztEmNLpjryhV61h+68ZfvYmonIrXZ005LAJ0Y73pHSk95YO5UTH5n2V
# PL1zYjdFGCc0/RI6o0ZtLjf4dKF8T4TXz2KnhW8j1xhsc2mFM+s8d6k3AgMBAAGj
# ggHLMIIBxzAdBgNVHQ4EFgQUvrYz8rurWf4eRrMi78s9R/hTSFowHwYDVR0jBBgw
# FoAUa2koOjUvSGNAz3vYr0npPtk92yEwbAYDVR0fBGUwYzBhoF+gXYZbaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwUHVibGlj
# JTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0ElMjAyMDIwLmNybDB5BggrBgEFBQcB
# AQRtMGswaQYIKwYBBQUHMAKGXWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY2VydHMvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNBJTIwVGltZXN0YW1waW5n
# JTIwQ0ElMjAyMDIwLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMA4GA1UdDwEB/wQEAwIHgDBmBgNVHSAEXzBdMFEGDCsGAQQBgjdMg30B
# ATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L0RvY3MvUmVwb3NpdG9yeS5odG0wCAYGZ4EMAQQCMA0GCSqGSIb3DQEBDAUAA4IC
# AQAOA6gFxLDtuo/y2uxYJ/0In4rfMbmXpKmee/mHvrB/4UU2xBIxmK2YLKsEf5VF
# HyghaW2RfJrGmT0CTkeGGFBFPF8oy65/GNYwkpqMYfZe7VokqHPyRQcN+eiQJsxh
# sXgQNhFksUbk69QLmXup2GjfP8LRZIh3LPIDGncVwbOg8VYcruWJ4Sz0JH7pipt5
# RX7cBO6Ynle39ZbJJpYLAugHkhgsxj2VIAr3B+U7/0Hvc+2yCJkg90rs4TiMGj/n
# ikE2H+u04n8iSpFkEnRn0wOinLuNZPCweqDyvjC5NY28cSucD6i0i+tsYytOEgVx
# xCUhJ7BbdM8VpMT/5YHo9Q8alJ5q2BHZMb8ykhyAKhVkmbpf+YSPrycbxT4bDUAR
# JOHErpQ5CUKXHVYv4Jn/5hxTmIQwY7GtebOC/trAYpd11f0/EYkeukPMWL0y0VsX
# dnVbKzqAsJ7FOFiHogtCYpwr9VixxIe0Ms6/UUq+JCiS1naTWC4YI5KI05hJAIxT
# u++Ld8Qe3p27yBdBjrFdfcZwlM6vRBisrdIDLmqYSpTYyfmk6Y1jGQxqPhjirJ6f
# dx5n7ZpdEsqdxffjN8vsuliRlGaCGSattu4w44xJ3baVK4fQXT3VSH1SQ/wLvNUc
# 4dOVBwIr6K0NzrPDxCxyIIjnfU1s23YJhs3CC7f3XVUBETGCB1YwggdSAgEBMHgw
# YTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEy
# MDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIw
# MjACEzMAAABWfo+dWAiO6WAAAAAAAFYwDQYJYIZIAWUDBAICBQCgggSvMBEGCyqG
# SIb3DQEJEAIPMQIFADAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZI
# hvcNAQkFMQ8XDTI2MDkyMzA5MjUyNFowPwYJKoZIhvcNAQkEMTIEMBqclRqptorn
# oQQnkOBVDgaax8S9kjTMfYsduRFCJm2UIxycRnJxVH2h5QKUGzWshzCBuQYLKoZI
# hvcNAQkQAi8xgakwgaYwgaMwgaAEILYMMyVNpOPwlXeJODleel7gJIfrTXjdn5f2
# jk0GAwyoMHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVz
# dGFtcGluZyBDQSAyMDIwAhMzAAAAVn6PnVgIjulgAAAAAABWMIIDYQYLKoZIhvcN
# AQkQAhIxggNQMIIDTKGCA0gwggNEMIICLAIBATCCAQmhgeGkgd4wgdsxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29m
# dCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpB
# NTAwLTA1RTAtRDk0NzE1MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGlt
# ZSBTdGFtcGluZyBBdXRob3JpdHmiIwoBATAHBgUrDgMCGgMVAP9z9ykVKpBZgF5e
# CDJEnZlu9gQRoGcwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRp
# bWVzdGFtcGluZyBDQSAyMDIwMA0GCSqGSIb3DQEBCwUAAgUA7l2VRDAiGA8yMDI2
# MDkyMzAwMDEwOFoYDzIwMjYwOTI0MDAwMTA4WjB3MD0GCisGAQQBhFkKBAExLzAt
# MAoCBQDuXZVEAgEAMAoCAQACAiIVAgH/MAcCAQACAhM0MAoCBQDuXubEAgEAMDYG
# CisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEA
# AgMBhqAwDQYJKoZIhvcNAQELBQADggEBAEULwUT4Y5h8UWWfnJZRlez9BE+BDARx
# lv00g484UYtAMtP4nu9BvBJ2M5XIwu6KruI9agqdjOUAufAZtTeeE2/egCT8wcYR
# ZIyh4CTc92ETd/L5ZbbiVdTXOfiTIpxaSJ6uYOQlozhHwmS38DOoHw/V5CiIoBwc
# tUbUiUX7UcEcBbi5VRd+86rr1vBUB6orxWSVfpiuzeOTlHbsuYz8mVnbpoQPK5zd
# Fv/95Q7U5zvKF9lTIRKE4N+PJEbcf3p31JiDi+DiUjtMz1RIqi5jSEQJCZcoSJJj
# jtda4rDL+UFVKviqILESaF6MKACECg8msdb+a1VmSnZT7UseJuEFCMowDQYJKoZI
# hvcNAQEBBQAEggIAsVlBaySgpsj436tNO/rcqV4NcSaG2ebrwnSP/nHOpuB5+PE9
# 3fCDrP67CmptMJtt7EsCi+ZHsIh27E/GepW5A1UmRBM17YcAO3WSAsRHdM5aQyh4
# OKfE0XkERPk/DSyoUtfiOcV2BcTay6uwF4YJfYpFSdeBBb1pvKHo4FQyWPPxD1k6
# 4sr+CSt0gc7DWB7yr9V5I8JfiNvlGRVfgoHf1Uli7h0tyeuFhJmlt/+IGsmFS0Z5
# yxSkLoNR0olTxBm4XqZpj5DNKPU7vD1tNzfTaRgSuoFH5trnSLOUEHIT4eOteyau
# EsH/ALLTioGkIMCKr1qPoK2GFpWuNUtl4ARMHzf6rvcWVzcpp930BR5iLu8SPJe2
# 04T14hrLjAwan3+T1+YcEeaTUL09ufg/a0JKTNW1sUb3WoK2YWhEnYQFvX766Sxr
# z0ZTwrQ226du+Au2i/nVdtr+VtCk0M8JzBpT8YEYHum71I1geowCGWt73I2BHQQ4
# k7R17rR678sLjAE429uiaSbvhFjSKi51FGBxTOiXVmOgHW9dZ685jfYXw11sGZAo
# YJdQ1xqnEVOYwF4rd5uKea499QzS7CLyCbJtswip5b+l4KskEsSIcdX7v3RgcMt9
# Z42YxYM/tzLG+0tXzXh7QqEzoP2ykSsQUzymF5nU6+h3TqKGF3/llZwTo8M=
# SIG # End signature block
