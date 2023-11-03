# Copyright (c) Mondoo, Inc.
# SPDX-License-Identifier: BUSL-1.1

#Requires -Version 5

<#
    .SYNOPSIS
    # Automatic Mondoo downloader from share and execute

    .PARAMETER Product
    Set 'cnspec' (default) to download from a share and execute it
    .PARAMETER RegistrationToken
    Is required to register the Mondoo Product, if ConfigFile is not existent
    .PARAMETER Proxy
    If provided, the proxy will be used for cnspec backend communication
    .PARAMETER Path
    If provided, the cnspec binary will be downloaded to the specified path
    .PARAMETER DownloadPath
    Is required to download the cnspec binary from the specified path
    .PARAMETER ConfigFile
    If provided, the cnspec binary will be downloaded to the specified path. Default: C:\ProgramData\Mondoo\mondoo.yml
    .PARAMETER LogDir
    The script output is logged to a file. Default: C:\Windows\Temp\
    .EXAMPLE
    scan.ps1 -Product cnspec
    scan.ps1 -RegistrationToken 'InsertTokenHere'
    scan.ps1 -Proxy 'http://proxy:8080'
    scan.ps1 -Path 'C:\Users\Administrator\mondoo'
    scan.ps1 -DownloadPath '\\1.1.1.1\share'
    scan.ps1 -ConfigFile 'C:\ProgramData\Mondoo\mondoo.yml'
    scan.ps1 -LogDir 'C:\Windows\Temp'
#>

Param(
      [string]   $Product = 'cnspec',
      [string]   $RegistrationToken = '',
      [string]   $Proxy = '',
      [string]   $ExecutionPath = '',
      [string]   $DownloadPath = '',
      [string]   $ConfigFile = "C:\ProgramData\Mondoo\mondoo.yml",
      [string]   $LogDir = ""
  )

# Set Log location
If ([string]::IsNullOrEmpty($LogDir)) {
  $logdir = [System.Environment]::GetEnvironmentVariable('TEMP','Machine')
} Else {
  # Check if Path exists
  $logdir = $LogDir.trim('\')
  If (!(Test-Path $logdir)) {New-Item -Path $logdir -ItemType Directory}
}

$username   = $env:USERNAME
$hostname   = hostname
$datetime   = Get-Date -f 'yyyyMMddHHmmss'
$filename   = "MondooExecutionDebug-${username}-${hostname}-${datetime}.txt"
$Transcript = Join-Path -Path $logdir -ChildPath $filename

# Log all output to a file
Start-Transcript -Path $Transcript

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

purple "$Product Binary Download Script"
purple "
                        .-.
                        : :
,-.,-.,-. .--. ,-.,-. .-`' : .--.  .--.
: ,. ,. :`' .; :: ,. :`' .; :`' .; :`' .; :
:_;:_;:_;``.__.`':_;:_;``.__.`'``.__.`'``.__.
"

info "If you are experiencing any issues, please do not hesitate to reach out:

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
  info ("  RegistrationToken: {0}" -f $RegistrationToken)
  info ("  Proxy:             {0}" -f $Proxy)
  info ("  ExecutionPath:     {0}" -f $ExecutionPath)
  info ("  DownloadPath:      {0}" -f $DownloadPath)
  info ("  ConfigFile:        {0}" -f $ConfigFile)
  info ("  LogDir:            {0}" -f $LogDir)
  info ""

# Set proxy environment variables
If (![string]::IsNullOrEmpty($Proxy)) {
  [Environment]::SetEnvironmentVariable("HTTP_PROXY", $Proxy)
  [Environment]::SetEnvironmentVariable("HTTPS_PROXY", $Proxy)
}

# Set download location
If ([string]::IsNullOrEmpty($ExecutionPath)) {
  $ExecutionPath = Get-Location
} Else {
  # Check if Path exists
  $ExecutionPath = $ExecutionPath.trim('\')
  If (!(Test-Path $ExecutionPath)) {New-Item -Path $ExecutionPath -ItemType Directory}
}

# Make cnspec available on the local system
If (![string]::IsNullOrEmpty($DownloadPath)) {
  # Copy cnspec from central share
  Copy-Item -Path "$DownloadPath\$Product.exe" -Destination $ExecutionPath
  $program = "$ExecutionPath\$Product.exe"
  # Check if cnspec downloaded successfully
  If (Test-Path -Path "$($program )") {
    & $program providers install os
    success " * $Product was downloaded successfully!"
  } Else {
    fail "Cnspec is not available at $program"
  }
} Else {
  fail "DownloadPath is required"
}

# Check if cnspec is registered
If (-not (Test-Path -Path "$($ConfigFile)")) {
  If ([string]::IsNullOrEmpty($RegistrationToken)) {
    fail "RegistrationToken is required"
  }
  info " * Register $Product Client"
  $login_params = @("login", "-t", "$RegistrationToken", "--config", "$ConfigFile")

  # Cache the error action preference
  $backupErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"

  # Capture all output from cnspec
  $output = (& $program $login_params 2>&1)

  # Restore the error action preference
  $ErrorActionPreference = $backupErrorActionPreference

  if ($output -match "ERROR") {
    throw $output
  } elseif($output) {
    info "$output"
  } else {
    info "No output"
  }
  If (Test-Path -Path "$($ConfigFile)") {
    success " * $Product was registered successfully!"
  } Else {
    fail "Cnspec login failed"
  }
}

try {
  info " * Execute $Product Client"
  & $program @("scan", "--config", "$($configFile)")
}
catch {
  fail "Cnspec scan failed"
}
finally {
  info "Clean up the house"
  Remove-Item $program
  Stop-Transcript
}
