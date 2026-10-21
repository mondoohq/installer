# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

#Requires -Version 5
#Requires -RunAsAdministrator
<#
    .SYNOPSIS
    This PowerShell script installs the latest Mondoo agent on windows. Usage:
    Set-ExecutionPolicy RemoteSigned -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://install.mondoo.com/ps1')); Install-Mondoo;

    .PARAMETER RegistrationToken
    The registration token for your mondoo installation. See our docs if you do not
    have one: https://mondoo.com/docs/cnspec/cnspec-adv-install/registration/
    .PARAMETER DownloadType
    Set 'msi' (default) to download the package or 'zip' for the agent binary instead
    .PARAMETER Version
    If provided, tries to download the specific version instead of the latest
    .EXAMPLE
    Import-Module ./install.ps1; Install-Mondoo -RegistrationToken 'INSERTKEYHERE'
    Import-Module ./install.ps1; Install-Mondoo -Version 6.14.0
    Import-Module ./install.ps1; Install-Mondoo -Proxy 'http://1.1.1.1:3128'
    Import-Module ./install.ps1; Install-Mondoo -Service enable
    Import-Module ./install.ps1; Install-Mondoo -UpdateTask enable -Time 12:00 -Interval 3
    Import-Module ./install.ps1; Install-Mondoo -Product cnspec
    Import-Module ./install.ps1; Install-Mondoo -Path 'C:\Program Files\Mondoo\'
#>
function Install-Mondoo {
  [CmdletBinding()]
  Param(
      [string]   $Product = 'mondoo',
      [string]   $DownloadType = 'msi',
      [string]   $Path = 'C:\Program Files\Mondoo\',
      [string]   $Version = '',
      [string]   $RegistrationToken = '',
      [string]   $Proxy = '',
      [string]   $Service = '',
      [string]   $UpdateTask = '',
      [string]   $Time = '',
      [string]   $Interval = '',
      [string]   $taskname = "MondooUpdater",
      [string]   $taskpath = "Mondoo"
  )
  Process {

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
    return "MondooInstallScript/1.0 (+https://mondoo.com/) PowerShell/$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor) (Windows NT $([System.Environment]::OSVersion.Version.Major).$([System.Environment]::OSVersion.Version.Minor);$PSEdition)"
  }

  function download($url,$to) {
    $wc = New-Object Net.Webclient
    If(![string]::IsNullOrEmpty($Proxy)) {
      $wc.proxy = New-Object System.Net.WebProxy($Proxy)
    }
    $wc.Headers.Add('User-Agent', (Get-UserAgent))
    $wc.downloadFile($url,$to)
  }

  function determine_latest {
    Param
    (
        [Parameter(Mandatory)]
        [string[]]$product,
        [Parameter(Mandatory)]
        [string[]]$filetype,
        [Parameter(Mandatory)]
        [string[]]$arch
    )
    If([string]::IsNullOrEmpty($filetype)) {
      $filetype = [regex]::escape('msi')
    }
    $url_version = "https://install.mondoo.com/package/${product}/windows/${arch}/${filetype}/latest/version"
    $wc = New-Object Net.Webclient
    If(![string]::IsNullOrEmpty($Proxy)) {
      $wc.proxy = New-Object System.Net.WebProxy($Proxy)
    }
    $wc.Headers.Add('User-Agent', (Get-UserAgent))
    $wc.DownloadString($url_version)
  }

  function getenv($name,$global) {
    $target = 'User'; if($global) {$target = 'Machine'}
    [System.Environment]::GetEnvironmentVariable($name,$target)
  }

  function setenv($name,$value,$global) {
    $target = 'User'; if($global) {$target = 'Machine'}
    [System.Environment]::SetEnvironmentVariable($name,$value,$target)
  }

  function enable_service() {
    info " * Set cnspec to run as a service automatically at startup and start the service"
    If((Get-Service -Name Mondoo).Status -eq 'Running') {
      info " * Restarting $Product Service as it is already running"
      Restart-Service -Name Mondoo -Force
    }
    IF((Get-Host).Version.Major -le 5) {
      Set-Service -Name Mondoo -Status Running -StartupType Automatic
      sc.exe config Mondoo start=delayed-auto
    } Else {
      Set-Service -Name Mondoo -Status Running -StartupType AutomaticDelayedStart
    }

    If(((Get-Service -Name Mondoo).Status -eq 'Running') -and ((Get-Service -Name Mondoo).StartType -contains 'Automatic') ) {
      success "* $Product Service is running and start type is automatic delayed start"
    } Else {
      fail "Mondoo service configuration failed"
    }
  }

  function NewScheduledTaskFolder($taskpath)
  {
      $ErrorActionPreference = "stop"
      $scheduleObject = New-Object -ComObject schedule.service
      $scheduleObject.connect()
      $rootFolder = $scheduleObject.GetFolder("\")
      Try { $null = $scheduleObject.GetFolder($taskpath) }
      Catch { $null = $rootFolder.CreateFolder($taskpath) }
      Finally { $ErrorActionPreference = "continue" }
  }

  function CreateAndRegisterMondooUpdaterTask($taskname, $taskpath)
  {
    info " * Create and register the Mondoo update task"
    NewScheduledTaskFolder $taskpath

    $taskArgument = '-NoProfile -WindowStyle Hidden -ExecutionPolicy RemoteSigned -Command &{ [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $wc = New-Object Net.Webclient; '

    If (![string]::IsNullOrEmpty($Proxy)) {
      # Add proxy config to scheduling task
      $taskArgument = $taskArgument += '$wc.proxy = New-Object System.Net.WebProxy(\"' + $Proxy + '\"); '
    }

    $taskArgument = $taskArgument += 'iex ($wc.DownloadString(\"https://install.mondoo.com/ps1\")); Install-Mondoo '

    # Set product name in scheduling task
    $taskArgument = $taskArgument += '-Product ' + $Product + ' '

    # Set Path in scheduling task
    $taskArgument = $taskArgument += '-Path \"' + $Path + '\" '

    # Service enabled
    If ($Service.ToLower() -eq 'enable' -and $Product.ToLower() -eq 'mondoo') {
      $taskArgument = $taskArgument += '-Service enable '
    }

    # Proxy enabled
    If (![string]::IsNullOrEmpty($Proxy)) {
      $taskArgument = $taskArgument += '-Proxy ' + $Proxy + ' '
    }

    # Recreate scheduling task
    If ($UpdateTask.ToLower() -eq 'enable') {
      $taskArgument = $taskArgument += '-UpdateTask enable -Time ' + $Time + ' -Interval ' + $Interval +' '
    }

    $taskArgument = $taskArgument += ';}'

    $action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $taskArgument
    $trigger =  @(
      $(New-ScheduledTaskTrigger -Daily -DaysInterval $Interval -At $Time)
    )
    $principal = New-ScheduledTaskPrincipal -GroupId "NT AUTHORITY\SYSTEM" -RunLevel Highest
    # Laptops are often off, asleep or unplugged at $Time. -StartWhenAvailable
    # runs a missed start once the machine is back, and by default Task
    # Scheduler neither starts a task on battery nor lets it keep running when
    # the machine is unplugged.
    $settings = New-ScheduledTaskSettingsSet -Compatibility Win8 -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -Action $action -Settings $settings -Trigger $trigger -TaskName $taskname -Description "$Product Updater Task" -TaskPath $taskpath -Principal $principal

    If (Get-ScheduledTask -TaskName $taskname -EA 0)
    {
        success "* $Product Updater Task installed"
    } Else {
      fail "Installation of $Product Updater Task failed"
    }
  }

  purple "Mondoo Windows Installer Script"
  purple "
                          .-.
                          : :
  ,-.,-.,-. .--. ,-.,-. .-`' : .--.  .--.
  : ,. ,. :`' .; :: ,. :`' .; :`' .; :`' .; :
  :_;:_;:_;``.__.`':_;:_;``.__.`'``.__.`'``.__.
  "

  info "Welcome to the $Product Install Script. It downloads the $Product binary for
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
  To upgrade PowerShell visit https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell
  "
  }

  # we only support x86_64 at this point, stop if we got arm
  If ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64' -and -not ($env:PROCESSOR_ARCHITECTURE -eq "x86" -and [Environment]::Is64BitOperatingSystem)) {
    fail "
  Your processor architecture $env:PROCESSOR_ARCHITECTURE is not supported yet. Please come join us in
  our Mondoo Community GitHub Discussions https://github.com/orgs/mondoohq/discussions or email us at hello@mondoo.com
  "
  }

  info "Arguments:"
  info ("  Product:           {0}" -f $Product)
  info ("  RegistrationToken: {0}" -f $RegistrationToken)
  info ("  DownloadType:      {0}" -f $DownloadType)
  info ("  Path:              {0}" -f $Path)
  info ("  Version:           {0}" -f $Version)
  info ("  Proxy:             {0}" -f $Proxy)
  info ("  Service:           {0}" -f $Service)
  info ("  UpdateTask:        {0}" -f $UpdateTask)
  info ("  Time:              {0}" -f $Time)
  info ("  Interval:          {0}" -f $Interval)
  info ""

  # determine download url
  $filetype = $DownloadType
  # mql and cnspec only ship as zip
  If ($product -ne 'mondoo') {
    $filetype = 'zip'
  }
  # get the installed mondoo version
  # Read the Uninstall keys through the .NET registry API, not the HKLM: drive.
  # The drive treats '/' in a key name as a path separator, so an entry like
  # "/n software SFTP Server 2022" cannot be resolved and, with
  # $erroractionpreference = 'stop', aborts the install. Opening each registry
  # view explicitly also finds the 64-bit entry from a 32-bit PowerShell host.
  $installed_version = $null
  foreach ($view in 'Registry32', 'Registry64') {
    $hklm = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', $view)
    $uninstall = $hklm.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')
    if ($null -eq $uninstall) { continue }
    foreach ($keyName in $uninstall.GetSubKeyNames()) {
      $app = $uninstall.OpenSubKey($keyName)
      # $null when the entry was removed after GetSubKeyNames listed it
      if ($app -and $app.GetValue('Publisher') -eq 'Mondoo, Inc.') {
        $installed_version = [pscustomobject]@{ version = $app.GetValue('DisplayVersion') }
      }
    }
  }

  $arch = 'amd64'
  $releaseurl = ''
  $version = $Version

  If ([string]::IsNullOrEmpty($Version)) {
    # latest release
    $version = determine_latest -product $Product -filetype $filetype -arch $arch
    $releaseurl = "https://install.mondoo.com/package/${Product}/windows/${arch}/${filetype}/latest/download"
  } Else {
    # specific version
    $releaseurl = "https://install.mondoo.com/package/${Product}/windows/${arch}/${filetype}/${version}/download"
  }

  # Check if Path exists
  $Path = $Path.trim('\')
  If (!(Test-Path $Path)) {New-Item -Path $Path -ItemType Directory}

  If ($version -ne  $installed_version.version) {
    # download windows binary zip/msi
    $downloadlocation = "$Path\$Product.$filetype"
    info " * Downloading $Product from $releaseurl to $downloadlocation"
    download $releaseurl $downloadlocation
  } Else {
    info " * Do not download $Product as latest version is already installed."
  }

  If ($filetype -eq 'zip') {
    If ($version -ne  $installed_version.version) {
      info ' * Extracting zip...'
      # remove older version if it is still there
      Remove-Item "$Path\$Product.exe" -Force -ErrorAction Ignore
      Add-Type -Assembly "System.IO.Compression.FileSystem"
      [IO.Compression.ZipFile]::ExtractToDirectory($downloadlocation,$Path)
      Remove-Item $downloadlocation -Force

      success " * $Product was downloaded successfully! You can find it in $Path\$Product.exe"
    }

    If ($UpdateTask.ToLower() -eq 'enable') {
      # Creating a scheduling task to automatically update the Mondoo package
      $taskname = $Product + "Updater"
      $taskpath = $Product
      If(Get-ScheduledTask -TaskName $taskname -EA 0)
      {
          Unregister-ScheduledTask -TaskName $taskname -Confirm:$false
      }
      CreateAndRegisterMondooUpdaterTask $taskname $taskpath
    }
  } ElseIf ($filetype -eq 'msi') {
    If ($version -ne  $installed_version.version) {
      info ' * Installing msi package...'
      $file = Get-Item $downloadlocation
      $packageName = $Product
      $timeStamp = Get-Date -Format yyyyMMddTHHmmss
      $logFile = '{0}\{1}-{2}.MsiInstall.log' -f $env:TEMP, $packageName,$timeStamp
      $argsList = @(
          "/i"
          ('"{0}"' -f $file.fullname)
          "/qn"
          "/norestart"
          "/L*v"
          $logFile
      )

      info (' * Run installer {0} and log into {1}' -f $downloadlocation, $logFile)
      $process = Start-Process "msiexec.exe" -Wait -NoNewWindow -PassThru -ArgumentList $argsList
      # https://docs.microsoft.com/en-us/windows/win32/msi/error-codes
    }

    If (![string]::IsNullOrEmpty($RegistrationToken)) {
      # Prepare cnspec logout command
      $logout_params = @("logout", "--config", "C:\ProgramData\Mondoo\mondoo.yml", "--force")

      # Prepare cnspec login command
      $login_params = @("login", "-t", "$RegistrationToken", "--config", "C:\ProgramData\Mondoo\mondoo.yml")
      If (![string]::IsNullOrEmpty($Proxy)) {
          $login_params = $login_params + @("--api-proxy", "$Proxy")
      }

      $program = "$Path\cnspec.exe"

      # Cache the error action preference
      $backupErrorActionPreference = $ErrorActionPreference
      $ErrorActionPreference = "Continue"

      # Logout if already cnspec client registered in
      If ((Test-Path -Path "C:\ProgramData\Mondoo\mondoo.yml")) {
        info " * $Product Client is already registered. Logging out and back in again to update the registration"
        $output = (& $program $logout_params 2>&1)
        info "$output"
        Remove-Item "C:\ProgramData\Mondoo\mondoo.yml" -Force
      }

      info " * Register $Product Client"

      # Login to register cnspec client
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
    }

    If ($version -ne  $installed_version.version) {
      If (@(0,3010) -contains $process.ExitCode) {
        success " * $Product was installed successfully!"
      } Else {
        fail (" * $Product installation failed with exit code: {0}" -f $process.ExitCode)
      }
    } Else {
      success " * $Product is already installed in the latest version and registered."
    }


    # Check if Service parameter is set and Parameter Product is set to mondoo
    If (($Service.ToLower() -eq 'enable' -and $Product.ToLower() -eq 'mondoo') -or ((Get-Service -Name Mondoo).Status -eq 'Running')) {
      # start Mondoo service
      enable_service
    }

    If ($UpdateTask.ToLower() -eq 'enable') {
      # Creating a scheduling task to automatically update the Mondoo package
      $taskname = $Product + "Updater"
      $taskpath = $Product
      If (Get-ScheduledTask -TaskName $taskname -EA 0)
      {
          Unregister-ScheduledTask -TaskName $taskname -Confirm:$false
      }
      CreateAndRegisterMondooUpdaterTask $taskname $taskpath
    }

    If ($version -ne  $installed_version.version) {
      Remove-Item $downloadlocation -Force
    }

  } Else {
    fail "${filetype} is not supported for download"
  }

  # Display final message
  info "
  Thank you for installing $Product!"

  info "
    If you have any questions, please come join us in our Mondoo Community on GitHub Discussions:

      * https://github.com/orgs/mondoohq/discussions

    Configure cnspec to run as a service and get continuous security reports using PowerShell:

      Set-Service -Name mondoo -Status Running -StartupType Automatic

    Scan your system now:

      cnspec scan
    "
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
  # reset erroractionpreference
  $erroractionpreference = $previous_erroractionpreference
  }
}

# SIG # Begin signature block
# MII9RQYJKoZIhvcNAQcCoII9NjCCPTICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAYzheli2p/VGna
# CaQ0BHsOso1lojDtJfrea8ltrXPxRKCCIeowggXMMIIDtKADAgECAhBUmNLR1FsZ
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
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggaiMIIEiqADAgECAhMzAAiwNMyQ
# CUbc3Q+wAAAACLA0MA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBBT0MgQ0EgMDMwHhcNMjYxMDE2MDMyODAyWhcNMjYxMDE5
# MDMyODAyWjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAhj8Y
# StVOhoXiTrNfpBbNswLnY5gt2Fg9kqiytlrr+pF17S7cPuofmAJjBQzhHfskS0u5
# JqoMrZWbD6RkOszmhUCSwAT9Eg9GET12/zIS2MTmvBZflGw+Lsk7j3FUUQrWRcXb
# 62UBZIbyw/5o/HU8yV3kfrH/ld1DKqgaVpFXz9TBAxrnnDj+9s7ge210LYtH2TJq
# Issm0oL3rtEFK9yt/i0KNuN4FRI41agMIRc1pbNC9/QJ2TVgBsBjLR9hx0vfhqEs
# jIu4sg7v6snyiJYPePioRhcmY3hmDlRw49UG0e4FKnSWh8S/Gow0j82Rvc0t7VNE
# HO6pazTLhzhvE1vn5FXNSK+RV/cBsNEIGCzSPqNNmxN49guo5fPaTgA5hHX0dAz5
# kjZlNWLRC99I46n7NlgVDt2dK+Pj14oq0xqbm7vYNeboKbe2VENJMxbCgj3YWJw8
# O4ACQg94Vh4oUZ8cuIgrmpByGjSWraeNORPx5Yy3xd+jIOzbLhRpmn/MFKwPAgMB
# AAGjggHWMIIB0jAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQU+loMYVMJu5aR9iumrlGUBUoTUAUwHwYDVR0jBBgw
# FoAUpEMMf3ZapYXnPo0oDwwXokVpcMYwZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwQU9DJTIwQ0ElMjAwMy5jcmwwdAYIKwYBBQUHAQEEaDBm
# MGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Nl
# cnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEFPQyUyMENBJTIw
# MDMuY3J0MFQGA1UdIARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wDQYJ
# KoZIhvcNAQEMBQADggIBAInf3+wuYUHb8hxM2kLQwpKQ1YCbzMXdqFM9nJLoy4rh
# ZfQVwxEKBaKRcvpntSBAObRkPLlV/d/2B55IMpgJpvyR7RzrJOxrTdeitJpj7/yx
# EtbTOSrJ5AD9TRaESUqRPzZ5ceGCY4rKNJC/TO+HXsFZsF9MJ1jDRiLJi1enP716
# KZshbh6DWAgLO35m166gR2H6ph+2BF49nbmWzBD6NVOVuKBogYXGSeCvbnWY3XMJ
# dMbWJjr2TI6NRA80dtGdWbFb41wjUI3wrDo+KJjtG2fgwQQ78r9V9y6NAXO7Cqqf
# dqdj6SMCIIT/5Z0+vShFb23VKj4X5xyGpfLaGlJzwDZIucWqZA1Z/kIgNjrO/4N/
# Uont9nJRqYrTkxI6xdHEvbzV7acd60VkngVvK3VLE+zrQ+LwEiyfjar4y4HIQKqx
# 1hmr5snt0C8sjmP5QZSWvHDFBlbEMyMXYcoDXW+YB6xSh8Gm1I1w5wkhSSxQ2AZn
# UV3PWuJ/5IY3bbhdKtMBb+QUI7neHyWZZUVFRdg875opUveEpf+R+TmdNdaoa7SY
# 6ymoamgztClZ/8hUkZxotB92btIp2j2h2MNLgb9IuFUzn9D7i0rWWLEaeKyEPpNy
# mPX6oXKZetAc31N3wXBnALuJzs/C+SHnqLjLvcxqze3MVr+JYH1oPauFvBvXcmWl
# MIIGojCCBIqgAwIBAgITMwAIsDTMkAlG3N0PsAAAAAiwNDANBgkqhkiG9w0BAQwF
# ADBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgQU9DIENBIDAzMB4X
# DTI2MTAxNjAzMjgwMloXDTI2MTAxOTAzMjgwMlowYzELMAkGA1UEBhMCVVMxFzAV
# BgNVBAgTDk5vcnRoIENhcm9saW5hMQ0wCwYDVQQHEwRDYXJ5MRUwEwYDVQQKEwxN
# b25kb28sIEluYy4xFTATBgNVBAMTDE1vbmRvbywgSW5jLjCCAaIwDQYJKoZIhvcN
# AQEBBQADggGPADCCAYoCggGBAIY/GErVToaF4k6zX6QWzbMC52OYLdhYPZKosrZa
# 6/qRde0u3D7qH5gCYwUM4R37JEtLuSaqDK2Vmw+kZDrM5oVAksAE/RIPRhE9dv8y
# EtjE5rwWX5RsPi7JO49xVFEK1kXF2+tlAWSG8sP+aPx1PMld5H6x/5XdQyqoGlaR
# V8/UwQMa55w4/vbO4HttdC2LR9kyaiLLJtKC967RBSvcrf4tCjbjeBUSONWoDCEX
# NaWzQvf0Cdk1YAbAYy0fYcdL34ahLIyLuLIO7+rJ8oiWD3j4qEYXJmN4Zg5UcOPV
# BtHuBSp0lofEvxqMNI/Nkb3NLe1TRBzuqWs0y4c4bxNb5+RVzUivkVf3AbDRCBgs
# 0j6jTZsTePYLqOXz2k4AOYR19HQM+ZI2ZTVi0QvfSOOp+zZYFQ7dnSvj49eKKtMa
# m5u72DXm6Cm3tlRDSTMWwoI92FicPDuAAkIPeFYeKFGfHLiIK5qQcho0lq2njTkT
# 8eWMt8XfoyDs2y4UaZp/zBSsDwIDAQABo4IB1jCCAdIwDAYDVR0TAQH/BAIwADAO
# BgNVHQ8BAf8EBAMCB4AwPQYDVR0lBDYwNAYKKwYBBAGCN2EBAAYIKwYBBQUHAwMG
# HCsGAQQBgjdhgqndkVaCp5bkUoGRmP1vg9zbqyowHQYDVR0OBBYEFPpaDGFTCbuW
# kfYrpq5RlAVKE1AFMB8GA1UdIwQYMBaAFKRDDH92WqWF5z6NKA8MF6JFaXDGMGcG
# A1UdHwRgMF4wXKBaoFiGVmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEFPQyUyMENBJTIw
# MDMuY3JsMHQGCCsGAQUFBwEBBGgwZjBkBggrBgEFBQcwAoZYaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlm
# aWVkJTIwQ1MlMjBBT0MlMjBDQSUyMDAzLmNydDBUBgNVHSAETTBLMEkGBFUdIAAw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMA0GCSqGSIb3DQEBDAUAA4ICAQCJ39/sLmFB2/Ic
# TNpC0MKSkNWAm8zF3ahTPZyS6MuK4WX0FcMRCgWikXL6Z7UgQDm0ZDy5Vf3f9gee
# SDKYCab8ke0c6yTsa03XorSaY+/8sRLW0zkqyeQA/U0WhElKkT82eXHhgmOKyjSQ
# v0zvh17BWbBfTCdYw0YiyYtXpz+9eimbIW4eg1gICzt+ZteuoEdh+qYftgRePZ25
# lswQ+jVTlbigaIGFxkngr251mN1zCXTG1iY69kyOjUQPNHbRnVmxW+NcI1CN8Kw6
# PiiY7Rtn4MEEO/K/VfcujQFzuwqqn3anY+kjAiCE/+WdPr0oRW9t1So+F+cchqXy
# 2hpSc8A2SLnFqmQNWf5CIDY6zv+Df1KJ7fZyUamK05MSOsXRxL281e2nHetFZJ4F
# byt1SxPs60Pi8BIsn42q+MuByECqsdYZq+bJ7dAvLI5j+UGUlrxwxQZWxDMjF2HK
# A11vmAesUofBptSNcOcJIUksUNgGZ1Fdz1rif+SGN224XSrTAW/kFCO53h8lmWVF
# RUXYPO+aKVL3hKX/kfk5nTXWqGu0mOspqGpoM7QpWf/IVJGcaLQfdm7SKdo9odjD
# S4G/SLhVM5/Q+4tK1lixGnishD6Tcpj1+qFymXrQHN9Td8FwZwC7ic7Pwvkh56i4
# y73Mas3tzFa/iWB9aD2rhbwb13JlpTCCBygwggUQoAMCAQICEzMAAAAYDeuRVamK
# AJgAAAAAABgwDQYJKoZIhvcNAQEMBQAwYzELMAkGA1UEBhMCVVMxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjE0MDIGA1UEAxMrTWljcm9zb2Z0IElEIFZl
# cmlmaWVkIENvZGUgU2lnbmluZyBQQ0EgMjAyMTAeFw0yNjAzMjYxODExMzJaFw0z
# MTAzMjYxODExMzJaMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJpZmllZCBDUyBB
# T0MgQ0EgMDMwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDIgNpgNFai
# if2VWeWP5I6PnFXxJ/lB37fJR55GCvR7GLZBMkBijbiKVwgpBI3xM5nf484znH/q
# ncJ+OCq6y3jgnQW+R8Zd7U+7LjlrmcskalzSQ0ghMxEpnBW8/HHs2V8ZJzQk6HP+
# SDsbvsL7LdlH/eO2l4mknhDBwr0Z/Q966TvEth5b8kCxj1vqiV4YNthLGRqZR9u2
# fK/yBMWu83p6O4uo2Edg++gEew5IL7vnnnKFqmSh/R9vPJy3WF1YcZewAUx8sXZN
# Unx3ZhVg59l2LpitPiwzE6FMqIsqaEvVe3MzuFd2a/uWDZH6VbDyUiRK78mIg1DQ
# YA9zDEyyBFcNI+nxVSzglvL6u7PRuNqgcV3sf6ELxw89ysQM/Z4R1hRFWXRpyOWK
# KAKtfBHTk0UnNiPcxmLMMYs8jeUjOidfVPjTIry/UVwnwxdlkK85cZfBEMYZ/DBN
# OwdomP459Y1n8izKkbhsa+p4lw+cQVxATBFx9ggR79HhryT7HDmpPLvkJvBZ4wW4
# CW32UT2SMyDe28nIOU3m+hfHlVeKcLBQcym5VoRDjIcCVI7uqgGW2PNME0cfei8z
# CwCy6HCsssJWFS7eg/YbFhnATJcyWfMrkNuAbMfMN8Npg8crS6jVVowyD0GG5zdg
# i+uQVcSK/638mA1xEYK3pnIoQgO09uuDBwIDAQABo4IB3DCCAdgwDgYDVR0PAQH/
# BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBSkQwx/dlqlhec+jSgP
# DBeiRWlwxjBUBgNVHSAETTBLMEkGBFUdIAAwQTA/BggrBgEFBQcCARYzaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBkG
# CSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMBIGA1UdEwEB/wQIMAYBAf8CAQAwHwYD
# VR0jBBgwFoAU2UEpsA8PY2zvadf1zSmepEhqMOYwcAYDVR0fBGkwZzBloGOgYYZf
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIw
# SUQlMjBWZXJpZmllZCUyMENvZGUlMjBTaWduaW5nJTIwUENBJTIwMjAyMS5jcmww
# fQYIKwYBBQUHAQEEcTBvMG0GCCsGAQUFBzAChmFodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBD
# b2RlJTIwU2lnbmluZyUyMFBDQSUyMDIwMjEuY3J0MA0GCSqGSIb3DQEBDAUAA4IC
# AQBxxyBW+X6mhdRiSwD9PMMWcGUAnx5/QUwnNvZdFGEX+4DRDIr9WCh4C87wHtw+
# lg1D3uzK10DstPX0LFLBFAC3vWMYX4ImXwoLhoR0xlN8mUdorJ3bgnpCJWuI1531
# Z1rCwPuUrSkBxfOIGDk3p2ECb3Ho/xHi5PRSR/OUrWuQHwXiaXMTuXu3IRLezwVk
# ZpFmNwYRD57R9Nx2F/yM7tzOY0Hh0hGCaYEK38/6FrS0SXadXWyDUCfn5XOGACRj
# UCnHx+JQUG0f4SHD+iblpAI0gl+ZHnVmdXXxHTZeTa0CYCIhFxKP2922s0g6zLme
# iV13LWUmtt/UF7TrWXpMi2/0UNniaDoH7rnPGRV5xVX8uXy4sZii4aswzqPM7Y7+
# mzcranqZ8EjZk5gjLhQ3A2sZaprlOu8CaRmyfcIiVH7zVfgAvm81MWXFziAf7my7
# QOvnyEFPGddq8MSfPtfRyw/Uq3uH6KpoaJNIfPYH6fceZSi53Rat1A9grExq3ROj
# hhSpTcchuBItAMNVPxoKNbUm+iR/X3XkL+9WQginjyHe+hXLclY8vAGXFD1p40Pq
# MIpAYsmEJBFKW9df4//1N5oQDr/FY9IBJl/oSS979i5rtT7NZz9KvYraCPRBGs0Q
# Cy+sWvgQa0coM70QJVLeVwmSxUO/0od0w9Qry7bSLrxGoDCCB54wggWGoAMCAQIC
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
# c29mdCBJRCBWZXJpZmllZCBDUyBBT0MgQ0EgMDMCEzMACLA0zJAJRtzdD7AAAAAI
# sDQwDQYJYIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQgxLSvfUg5dGOALlhwQpXI
# goSeNm7R/icYPn7xLbjFzHgwDQYJKoZIhvcNAQEBBQAEggGAgDdjFq4ZJLqoznSU
# LnqCtAuKuIw+ptMSlsC8HEeHiXUh79z3iZAEEo1tSseI4THaXbtQO8gm7R0z9IKB
# +SXNLOCd6qqX7owGdjtxmBDH99XJfezrHhESgtr0RLOQ/3EXrBU9UpOr5mOjknqF
# 6jItgW2wFHjDgBjKRpBu/S8qJFr3bGVof5YkJXmx+b86VbJw+N1pCMaML5ChKBgf
# u1HLT5wq5V5zESiHhdYIrj8tI/5iUu4HhOjJ2j33YH+DFr85RdEeZLGC5UG5iZhD
# 7JH0DQrvnGOZFqAgIYnxlPuaxp/havAE48jEQlmmSdjxJ02h16/+5CHDBCDXZzso
# rAAThjoZiKq8NIrVoUp4A6nMYCNgEyBTxr9ThZEWwBZf2DTMxr6M6O8zde8IkXTf
# e/H/TaWGBf6cyJAqkWfHx10JUnltDiUHKtHyHCcq/0sG4uVBW2fEQTmf7CDqpuYi
# 2lsYosaiLy6kPthxl87/cy09XwLoZEdM8vSswgJG9OkF4FOioYIYMTCCGC0GCisG
# AQQBgjcDAwExghgdMIIYGQYJKoZIhvcNAQcCoIIYCjCCGAYCAQMxDzANBglghkgB
# ZQMEAgIFADCCAXIGCyqGSIb3DQEJEAEEoIIBYQSCAV0wggFZAgEBBgorBgEEAYRZ
# CgMBMEEwDQYJYIZIAWUDBAICBQAEMLgV080u5iQXak96LmYGwr6oiw3A5ARPBpnn
# Ov6xQaHurXqy2CXGgj0MPUF6bqmkgwIGasj0KHRfGBMyMDI2MTAxODAwMzkyMC44
# OTVaMASAAgH0oIHhpIHeMIHbMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
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
# hvcNAQkFMQ8XDTI2MTAxODAwMzkyMFowPwYJKoZIhvcNAQkEMTIEMNHcB3PYgsL0
# PnWd1//XJERCVTh/pGwNOHmaUYxrndebmiL3GzngS5yMuW0F3rXKbjCBuQYLKoZI
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
# bWVzdGFtcGluZyBDQSAyMDIwMA0GCSqGSIb3DQEBCwUAAgUA7n3+mDAiGA8yMDI2
# MTAxNzE0MDMwNFoYDzIwMjYxMDE4MTQwMzA0WjB0MDoGCisGAQQBhFkKBAExLDAq
# MAoCBQDuff6YAgEAMAcCAQACAhZOMAcCAQACAhJhMAoCBQDuf1AYAgEAMDYGCisG
# AQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMB
# hqAwDQYJKoZIhvcNAQELBQADggEBAFbWksZpvCDN9OG31MC/F0zgFRyaRzYA/Fvf
# 6k32H4yvlxHXs3eKPDbNUAgkVf3aZ3JggUVS7/7+nN0Wu2n1tNpGciM5vL3vFxyd
# EbgDFtfuUfcWSkMSpVhPJlBZtkdKJHmgLkTw0UvbPIvqivsT87e3fgITq0n9hLS/
# /OB7uiVus/Xd3f021ojqsSelt7pHNQHP0YLGxQC6Oko7PO2PVcu6yfFeKl88AC8M
# Rfi09OS0BElmc+N1dfFSReSAWK2Br63udjiF+FRoJuXFAgI9cSx8EfOFxKWtPutt
# sk4qDgduZ/OMEXKGeIpQAPY+axsY2114DLGbrMU7sE+7XwVW/vkwDQYJKoZIhvcN
# AQEBBQAEggIABcxZbrrl5z0ggVebBgdhe7W36barwlAtkz9L0qXCYv/Z2xC8uRhg
# t9cYVUwJGC3hz3SQMkgMMp+3IKQSkxblouhFXnWgohjHRtRMK2swe58WL5ZlS3Wk
# CAITndg146B1UNV7+wHkQbsYf6IeAhaymI+nJhS2UDVnkfBVksh0d6KBWr8n4qal
# w5OAZc4k+GNT3pD4QDIZZ9OK3krQjSRRlS7pAROMI6NnukD5XEURNPZnQKaEZ8Zc
# RDH0NdR1Hp9z1ld8wblPbyLVqlUuGXCtuoddIbR8lnHEhaEGhBTVai4r+Ers/dri
# GrKvzmvmBEA3WpWbE7GQ/7fEylPmnVGXJWSGe2aE7yS0UmeTwFd76OKkY5Ll6QtM
# E8+YW9+KG+sLJkhs81bnvefmtuv0QpAt1IaEdgo9FVTP6HNCT0ZZdRWyf/dluqUU
# KYavr9HUAv0VAAtdKG9DpDG3P72srn7NQPDZRpE6EAc1ITKsgO7vgFvey9RErTGr
# ARKFk1t27Mmqy/TdVrTQWS1GRziWs49dfNkq1CL5Qpn1HFncv/VHfktSmgaKTRxQ
# IkkLO9SLlLWfrYJlER1DIvl4LilKZlc7zqN4fQiMsL7xyhme8ryKaeEvR6WpP3wW
# o8lwApdbPlAW8AcJiHDTBpAZy0X8w7VT4NKsEZsJmV+ygGPBYXAr69A=
# SIG # End signature block
