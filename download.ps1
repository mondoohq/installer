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
      # ValidateSet is the only gate on this value, and it is sufficient: it
      # rejects at parameter binding, before the script body runs, and there is
      # no other way in -- unlike download.sh, which reads MONDOO_CHANNEL from
      # the environment and so has to check it at point of use.
      [ValidateSet('stable', 'preview')]
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
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDbidq5++NBshfo
# qK5ASewWaA4Zr2eAOk7AxAlkX5rlv6CCIeowggXMMIIDtKADAgECAhBUmNLR1FsZ
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
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggaiMIIEiqADAgECAhMzAAYQRPcA
# miwtGl/JAAAABhBEMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBFT0MgQ0EgMDQwHhcNMjYwOTEzMDcwODMwWhcNMjYwOTE2
# MDcwODMwWjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAiSu/
# BHSDMxK5bLdmbgvtRU/IJEwydyMGITfSv5haqeeWjnkIV2WCivXmqUyKp35Xeshm
# m2b0afANSoXggVVFOh+6kk2B7l8bT8Tqc9SU8w3SHzaO7kA1ipqlD1iCwXW25D6z
# PlZLeaM/8y1siACdhwkoKd+Rdzjc3Sxk/fvjMqOlHexUgcGu3Co7ruosu78yAv1P
# SuFZW/221IDRmVTbxFMsLKp/D1b8pC2/a9dLp6k1RiJEk++DMTqDMAuXg6Gh4A5e
# WerNYJg+og9n59bqXMpkXuX6CjXREjdJzuWZZNXcCI69bRPPTpTRmVc69QGQ8qFK
# GHE+RtZ9mozGt755zCROp6ZOvX71yrRJeThSF8PJs4Orpv0nJNsqgELXDKH8/eqB
# b2Am8w0gS7IttMxO7tMMapWjodRRFvTQ8yj+JnRdjEZWOHSAKa6F+WyP4RpmFCZZ
# XRlR8pxsNZg2svxsyCRyWPlAQX/hyelp5xLNU6Kk1cGyPYbFfhwTQxQNUavBAgMB
# AAGjggHWMIIB0jAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQUjt09NjitshC9Ll2mEE4FUf0+tbMwHwYDVR0jBBgw
# FoAUmvFUd3UMhxY3RqCs3nn59H/BeOkwZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwRU9DJTIwQ0ElMjAwNC5jcmwwdAYIKwYBBQUHAQEEaDBm
# MGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Nl
# cnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIw
# MDQuY3J0MFQGA1UdIARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wDQYJ
# KoZIhvcNAQEMBQADggIBAENpZT1z+41ltZo+4UL4S5SarTtTfSAdBO7+H1A8jW9O
# l2hpakN38VSepumzeol/TnZv4IgISQf3Fn+31c0ZIawCjbY8J06yX18tVKbGimhz
# FJSLhidSmvTa55u8O3mVqSpo4PQ8WhTwovKCdX6LTPMxm3dhZvFNpEKFppno74nf
# zTytttVGm4HfRm4H/GW3Q8eALff/7oZCksOvNYVZhazGkvFG/c21rHpKZ1HZc82A
# 5W4o2MpXu43hc1tojsSrXyp6m7vjKuphBHcylT1K9SjF9tDKqIi7uRe6g2Hs9br8
# yyqOoqnvJJTbz9VAKDTEY8aZogkGwDMVhwrQzdbb7RY6pnpiXe1EtMyI3SPvuMuv
# hYOM/5IEnZGzI3ME406IPGNdZMrvHHdEIEyISjluXdwvAt5PxmcDVGb0p8rMEoFJ
# u1+ztpyZcFKq9djLgG4sY3CKRnxWFOeTfn9kjd9yexkFrpWfCGnIMEpR/lmbFIbe
# lsylbHyS9yRtvz5Xp1tcgHRdTT4RVOLpyj+znOokt2F+RXuz4fKV/c3IBcXLh2nm
# mNzfXHBzO4UXSt2dlKlYjwPHHJ631GQQgwnk930CjnkeHmLp9eGyR9Irnou6pdf+
# WBmFUOaUOiFSE8lpfjKa0CkP6vfwZPmhGhUKwbyGm14Ag7sh4s9RvaZwWExWUXA8
# MIIGojCCBIqgAwIBAgITMwAGEET3AJosLRpfyQAAAAYQRDANBgkqhkiG9w0BAQwF
# ADBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgRU9DIENBIDA0MB4X
# DTI2MDkxMzA3MDgzMFoXDTI2MDkxNjA3MDgzMFowYzELMAkGA1UEBhMCVVMxFzAV
# BgNVBAgTDk5vcnRoIENhcm9saW5hMQ0wCwYDVQQHEwRDYXJ5MRUwEwYDVQQKEwxN
# b25kb28sIEluYy4xFTATBgNVBAMTDE1vbmRvbywgSW5jLjCCAaIwDQYJKoZIhvcN
# AQEBBQADggGPADCCAYoCggGBAIkrvwR0gzMSuWy3Zm4L7UVPyCRMMncjBiE30r+Y
# Wqnnlo55CFdlgor15qlMiqd+V3rIZptm9GnwDUqF4IFVRTofupJNge5fG0/E6nPU
# lPMN0h82ju5ANYqapQ9YgsF1tuQ+sz5WS3mjP/MtbIgAnYcJKCnfkXc43N0sZP37
# 4zKjpR3sVIHBrtwqO67qLLu/MgL9T0rhWVv9ttSA0ZlU28RTLCyqfw9W/KQtv2vX
# S6epNUYiRJPvgzE6gzALl4OhoeAOXlnqzWCYPqIPZ+fW6lzKZF7l+go10RI3Sc7l
# mWTV3AiOvW0Tz06U0ZlXOvUBkPKhShhxPkbWfZqMxre+ecwkTqemTr1+9cq0SXk4
# UhfDybODq6b9JyTbKoBC1wyh/P3qgW9gJvMNIEuyLbTMTu7TDGqVo6HUURb00PMo
# /iZ0XYxGVjh0gCmuhflsj+EaZhQmWV0ZUfKcbDWYNrL8bMgkclj5QEF/4cnpaecS
# zVOipNXBsj2GxX4cE0MUDVGrwQIDAQABo4IB1jCCAdIwDAYDVR0TAQH/BAIwADAO
# BgNVHQ8BAf8EBAMCB4AwPQYDVR0lBDYwNAYKKwYBBAGCN2EBAAYIKwYBBQUHAwMG
# HCsGAQQBgjdhgqndkVaCp5bkUoGRmP1vg9zbqyowHQYDVR0OBBYEFI7dPTY4rbIQ
# vS5dphBOBVH9PrWzMB8GA1UdIwQYMBaAFJrxVHd1DIcWN0agrN55+fR/wXjpMGcG
# A1UdHwRgMF4wXKBaoFiGVmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIw
# MDQuY3JsMHQGCCsGAQUFBwEBBGgwZjBkBggrBgEFBQcwAoZYaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlm
# aWVkJTIwQ1MlMjBFT0MlMjBDQSUyMDA0LmNydDBUBgNVHSAETTBLMEkGBFUdIAAw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMA0GCSqGSIb3DQEBDAUAA4ICAQBDaWU9c/uNZbWa
# PuFC+EuUmq07U30gHQTu/h9QPI1vTpdoaWpDd/FUnqbps3qJf052b+CICEkH9xZ/
# t9XNGSGsAo22PCdOsl9fLVSmxopocxSUi4YnUpr02uebvDt5lakqaOD0PFoU8KLy
# gnV+i0zzMZt3YWbxTaRChaaZ6O+J3808rbbVRpuB30ZuB/xlt0PHgC33/+6GQpLD
# rzWFWYWsxpLxRv3Ntax6SmdR2XPNgOVuKNjKV7uN4XNbaI7Eq18qepu74yrqYQR3
# MpU9SvUoxfbQyqiIu7kXuoNh7PW6/MsqjqKp7ySU28/VQCg0xGPGmaIJBsAzFYcK
# 0M3W2+0WOqZ6Yl3tRLTMiN0j77jLr4WDjP+SBJ2RsyNzBONOiDxjXWTK7xx3RCBM
# iEo5bl3cLwLeT8ZnA1Rm9KfKzBKBSbtfs7acmXBSqvXYy4BuLGNwikZ8VhTnk35/
# ZI3fcnsZBa6VnwhpyDBKUf5ZmxSG3pbMpWx8kvckbb8+V6dbXIB0XU0+EVTi6co/
# s5zqJLdhfkV7s+Hylf3NyAXFy4dp5pjc31xwczuFF0rdnZSpWI8Dxxyet9RkEIMJ
# 5Pd9Ao55Hh5i6fXhskfSK56LuqXX/lgZhVDmlDohUhPJaX4ymtApD+r38GT5oRoV
# CsG8hpteAIO7IeLPUb2mcFhMVlFwPDCCBygwggUQoAMCAQICEzMAAAAXJ0UJC4uH
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
# DT2uhJ04ji+tHD6n58vhavFIrmcxghqxMIIarQIBATBxMFoxCzAJBgNVBAYTAlVT
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jv
# c29mdCBJRCBWZXJpZmllZCBDUyBFT0MgQ0EgMDQCEzMABhBE9wCaLC0aX8kAAAAG
# EEQwDQYJYIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQg5O8yA2ovkwM9zfOBrlNH
# 4vVd63RFIkxy7qYf+6ZQUyUwDQYJKoZIhvcNAQEBBQAEggGAJfpFiYJm6T5akMdP
# ArAfLcEEcVP+rlTesM27ZiX+h5J0Di8HK/aekWtdADcJSjaXeqyrbtv5CGtesVbM
# 3hu+SbuLzIfKfIKVauFlH9Ev5Z3o8uoB8H+XW39bpJ3C/J5eHy7YU2qMV6l1pSFy
# IvEVF1khPIlUBuAetRf6iW7FXd7AC0pT0hZv7+BvWUMN0LFCIoqjgTkX+5Ib7j7R
# 66Yce2gCiMCFp17RBlSrf6NEj23Pyw2bF6JLQIw7JZB3WSrDn7CY+1ShO21fQQvm
# MCE+IlWf7pz/KUGgSrs69x5j4cmCZ8nvOkSOlUTwVqs4TtbNnkZCLThNI4hxCALo
# FtMyeyz2BwtR4gBdwe0xK10tv7E7Nuz3ig46VDJFzGNMnlO6eELls/FCdLqEWTkR
# fR8nZ8XXDuDurALlTQwS/OXzGGWOpo43sOvfWwijZhoo5jMTq+LQNpzrqgUxbvir
# dgEb7jqZl79nfEBQ1MwmZyLqB7upqZSW5NGJnLsl/1Dix7t/oYIYMTCCGC0GCisG
# AQQBgjcDAwExghgdMIIYGQYJKoZIhvcNAQcCoIIYCjCCGAYCAQMxDzANBglghkgB
# ZQMEAgIFADCCAXIGCyqGSIb3DQEJEAEEoIIBYQSCAV0wggFZAgEBBgorBgEEAYRZ
# CgMBMEEwDQYJYIZIAWUDBAICBQAEMDfBsEzGId/OU7A5QsPhYRa0Hmcj13Wqh1vC
# FBhE8yUbaTGvjqodJpJWZqyAggvsyQIGaqQQPwtnGBMyMDI2MDkxNDEyNTkyNS40
# MjRaMASAAgH0oIHhpIHeMIHbMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
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
# GHumaABdWzCCB5cwggV/oAMCAQICEzMAAABYZc3rP6HX/NIAAAAAAFgwDQYJKoZI
# hvcNAQEMBQAwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1w
# aW5nIENBIDIwMjAwHhcNMjUxMDIzMjA0NjU1WhcNMjYxMDIyMjA0NjU1WjCB2zEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWlj
# cm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1Mg
# RVNOOjdBMDAtMDVFMC1EOTQ3MTUwMwYDVQQDEyxNaWNyb3NvZnQgUHVibGljIFJT
# QSBUaW1lIFN0YW1waW5nIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAJ14NKR2kOz1QJZZ/h2WayRXC6Cm3pIVtci/kDQVIBRVLI2SCmqq
# jeKCCbCTN6bNKyTUju53QjUbmQ19loLq9wJO+3l65aAV6mZjumVV3gzUQi5XVuAN
# PzX48ye115HRIY6/NYIVxKUe8wvsG2jTfrD0scywGQXomwxT+18LOcF9GbSLDdWt
# vl6uW71qd5ETMrcLJE47p0YHi2S/7Qadt+yVXUTxQEPY2ESqQqlAaP79cYwS0Qld
# z2pSo5xn29zDeFO41cqonxR0oXJ1uQhEUaAZlGurMoA8xUq/Ht4Pd0zzSxVIr1BN
# Bpi321+XHg9RrdRXGesfyS1QE85OfgVh2zMcCSFZFT06kkjI0OikynXJ6t6R9HOA
# BSaf4Jb3KatFPX82SIyRhr3aYrIZUZe+0ULVIUo8R7wp9ywv8akEMDh0kA7BoejV
# 9g9EX7EshLUwAcgGnvtsNRwckw03JpUzSxLkC3go9YDQXSFo9FjmMg7Y40P/Ik1m
# Onstb2/ah5YyI+R4CJ3U+T/TGJNlYNnu4SlGTQTWwP4bIAbLqGfiF/PVr4xDfWmx
# fdUuDiVbop5irCzvzC255e4pLg9HTeqANGHsMg0J3LNdrDPRzrbu9kAP02ZXn71v
# K/cbTFwGKEJXBo7JPFuFHO3H6lamyD43aHPGcQcy3F3Fcj+KeXMi8L5DAgMBAAGj
# ggHLMIIBxzAdBgNVHQ4EFgQUco1NxXq+FcVyfoYz3ESZ8Z0SCbAwHwYDVR0jBBgw
# FoAUa2koOjUvSGNAz3vYr0npPtk92yEwbAYDVR0fBGUwYzBhoF+gXYZbaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwUHVibGlj
# JTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0ElMjAyMDIwLmNybDB5BggrBgEFBQcB
# AQRtMGswaQYIKwYBBQUHMAKGXWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY2VydHMvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNBJTIwVGltZXN0YW1waW5n
# JTIwQ0ElMjAyMDIwLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMA4GA1UdDwEB/wQEAwIHgDBmBgNVHSAEXzBdMFEGDCsGAQQBgjdMg30B
# ATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L0RvY3MvUmVwb3NpdG9yeS5odG0wCAYGZ4EMAQQCMA0GCSqGSIb3DQEBDAUAA4IC
# AQB768SIlRdYh3F78ayUwg/HjrWz1Gyvcfi8+9ImHoYfhtFKDjHDH9OEA+rUD03m
# eR4RhE5HJ9K2gyeTaX20QbihB99a8W2Sve6NdikQzSdzbuHj2lCKR/03Fs/Dy1Tg
# hAssEsWxIBBttJMsnRnOOnOfdbV86X5CQ3JI6GK8qWnq3XkC0UB/S2qE2GX3QMzK
# Pg8tDtQ8xSZBeWJ7JgDPJbfa9TbV3RY3WxTAm1eXWruuJldtrNfOgPFJovpdt/fl
# HtHGyUCMpFoSJYYVocUIKJLKh8+5KdhhWQAHskk5iDkDlslzgPCQPEyEicp9yQzo
# Erb+fNz91dEEgC0+iVwwltuhVdtPFRiTM5L9Ettojk2Sf6Gpk6ZPEcw/KFk/KX23
# tav5P28T4l2EW86bPemuWDpKO59FXaOtQziYS/5oZNNWN+PIKur4Rv1U3HRh4daw
# pMDjNOQd+QGWavQLT6X0cyYp6x88xkcfq+nw93HGDDzDF/zcHdoq866Yde9n0HEn
# 9XzML8CIZnx+BliSfpn9RwOrl6ADlQcnJILl75Y/ID4u09hEukVPPkLLH6kzUySo
# 7AYXlilr9luBElXp9i+5Qs+4u/RYQPtJKdMlyZ2MHc1ktKL0yDVCyDZs1cjHElJu
# VrlX/GGd93ALndjqa+jdfkbi2Q2rw744noZSOXR/hhMuejGCB1MwggdPAgEBMHgw
# YTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEy
# MDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIw
# MjACEzMAAABYZc3rP6HX/NIAAAAAAFgwDQYJYIZIAWUDBAICBQCgggSsMBEGCyqG
# SIb3DQEJEAIPMQIFADAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZI
# hvcNAQkFMQ8XDTI2MDkxNDEyNTkyNVowPwYJKoZIhvcNAQkEMTIEMGplYzPm0ys2
# good2ltaQFyddmpOsmYHUbjK4WSeqsBiOxR3ASxfuDYetQUaJH6ZQDCBuQYLKoZI
# hvcNAQkQAi8xgakwgaYwgaMwgaAEIMUiVLuyB9D7ACjVxZtbP5Y3r1UF2znyFutq
# f3X1ouhxMHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVz
# dGFtcGluZyBDQSAyMDIwAhMzAAAAWGXN6z+h1/zSAAAAAABYMIIDXgYLKoZIhvcN
# AQkQAhIxggNNMIIDSaGCA0UwggNBMIICKQIBATCCAQmhgeGkgd4wgdsxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29m
# dCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo3
# QTAwLTA1RTAtRDk0NzE1MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGlt
# ZSBTdGFtcGluZyBBdXRob3JpdHmiIwoBATAHBgUrDgMCGgMVAJ1keRvbp6twXY7r
# a8J1lR9RK8RcoGcwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRp
# bWVzdGFtcGluZyBDQSAyMDIwMA0GCSqGSIb3DQEBCwUAAgUA7lHagTAiGA8yMDI2
# MDkxNDAyMjkyMVoYDzIwMjYwOTE1MDIyOTIxWjB0MDoGCisGAQQBhFkKBAExLDAq
# MAoCBQDuUdqBAgEAMAcCAQACAgCnMAcCAQACAhOXMAoCBQDuUywBAgEAMDYGCisG
# AQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMB
# hqAwDQYJKoZIhvcNAQELBQADggEBADTrEU6NzMUklfH7semZAKiIyFqPSF0uGFqz
# zGPehVMBubjM2MPq6uCgofDJIr9A4UaurPLa8qu3q9viY11xeoOwFdXzKLGCycBi
# Wkg73gdaFKEZJSQ6N4+86rpusTBgxnKalwqHLAA4f+hilcbxUkbe4LQ/sKsxTS/D
# oe6cD6BpZldKKRrsj2b6quAf1x0potzZ8p0NIVmZLhw1n1zouf0u3ZTmTw8b2mya
# 7+TYsXuZ9q+d8+NnrY0sART9ZlJinZdWj+hJURx6pBNigY1Uhhbbkd/R/Hqo+Mbu
# ccUvckJ+f5vsw9sLa2vRheYhE+HwP2ErAe6vX98Fq1bfK834D6IwDQYJKoZIhvcN
# AQEBBQAEggIAk6BV5kP/twyHs2UjhZusJcUT+Wgaw6XuZO3h5tw9wfNhPXbDUETe
# ZWrIBiKE7jIqgCsfgiN5Fr6RXcqzZNya2NdNzumRnnd5Fyi9EgTjpuGzxEz02OCz
# 4eoVib2Hu4+3kmCi3AQYXPDf1lkqTm92XekONSyYhA5PEzsdhqL/HvR9NGGYSgGq
# qfhmcD2la3WnueVt4Nu2f1IWfmIXQ65CK4OZRd5ApMgjSvkkAthQXlymei7Tm7W+
# UwtQRNHA+sqYO+eWqrLMchapmtwnE/1L3Ax+jD1oZDkWw07Lnb09eiDRfskz8GaW
# M6L7w2h/v55x9Om5/3voU1ZxmIHfc27bk+jpYBiJT8tlT0Tuh8p3qMHoe1MdP+Lq
# Gj8d2At7AR/mMYMgH3gc0FzZZoQnPK5Yo2Y7csDFOBNDMIzgeY7KqcMMvA36BiUr
# XmIE3ljuLL9sPhTs1954tzUBtvemQjTleBe9c6l2cASM/URxCnb+OAky8qoXO6gh
# xq0GHVtPSF3qFM5r+oVuNanJQ3q4GeeuOaDZEO5Kb2qSAd/No38GPePVX2B/7gDV
# rC/cJnIgt2WdjbptM0DR5BtKneFI0Y93PRXar0ZRSCUbRAWVRehCbGqOXA7y502f
# mptBKXTQEza44v5FNW2KdVNcKiXte5xyssfNbhPOn9TMgvYz9ABzSOI=
# SIG # End signature block
