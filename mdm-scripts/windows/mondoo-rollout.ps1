# Copyright (c) Mondoo, Inc.
# SPDX-License-Identifier: BUSL-1.1

Param(
    [string]   $RegistrationToken = 'tokenHere',
    [string]   $Service = 'enable',
    [string]   $UpdateTask = 'enable',
    [string]   $Time = '12:00',
    [string]   $Interval = '7'
)

If ($RegistrationToken -eq 'tokenHere') {
    Write-Output 'Registration token not set'
    Exit 1
}

$software = "mondoo";
$installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -eq $software }) -ne $null

If ($installed) {
    Write-Output "remove '$software'";
    Get-Package *mondoo* | uninstall-package;
}

if (Test-Path 'C:\ProgramData\Mondoo\mondoo.yml') {
    Remove-Item 'C:\ProgramData\Mondoo\mondoo.yml'
    Write-Output 'removed C:\ProgramData\Mondoo\mondoo.yml'
}

# For older Windows versions we may need to activate newer TLS config to prevent
# "Invoke-WebRequest : The request was aborted: Could not create SSL/TLS secure channel."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://install.mondoo.com/ps1'));

if (Get-Command Install-Mondoo -errorAction SilentlyContinue) {
    Install-Mondoo -RegistrationToken $RegistrationToken -Service $Service -UpdateTask $UpdateTask -Time $Time -Interval $Interval;
}
else {
    Write-Output 'Installation failed'
    Exit 1
}

$cmdOutput = cnspec status 2>&1

if ($cmdOutput -like "*client is registered*") {
    Write-Output 'Mondoo Installation successful'
    Exit 0
}
else {
    Write-Output 'Mondoo Installation failed'
    Exit 1
}