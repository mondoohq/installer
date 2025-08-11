# Copyright (c) Mondoo, Inc.
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
    $settings = New-ScheduledTaskSettingsSet -Compatibility Win8
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
  # cnquery and cnspec only ship as zip
  If ($product -ne 'mondoo') {
    $filetype = 'zip'
  }
  # get the installed mondoo version
  $Apps = @()
  $Apps += Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" # 32 Bit
  $Apps += Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" # 64 Bit
  $installed_version = $Apps | where-object Publisher -eq "Mondoo, Inc."
  if ($installed_version){
    $installed_version.version = $installed_version.DisplayVersion
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

      # Logout if already cnspec client registred in
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

    Scan your system now and view your results at https://console.mondoo.com:

      cnspec scan
    "
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
  # reset erroractionpreference
  $erroractionpreference = $previous_erroractionpreference
  }
}

# SIG # Begin signature block
# MII6jQYJKoZIhvcNAQcCoII6fjCCOnoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAG7+g3NIHfs1Xq
# 5kaUr0ikyOes4zMDYwOe9gJj8uoDtqCCIqQwggXMMIIDtKADAgECAhBUmNLR1FsZ
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
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggbmMIIEzqADAgECAhMzAATbCw7x
# pmHkhzTVAAAABNsLMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBBT0MgQ0EgMDEwHhcNMjUwODA3MTMwMTI0WhcNMjUwODEw
# MTMwMTI0WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAtImf
# mLIUmNFeXXlztn9O437qEH2JDbzA2UiPj09xhzltzVWH6OSmIJh3C7xisVITM3MK
# atAbB2NeU+vnIJ7GLI6ld2UaHUfqI30XSWQ5VUd8uOD1gSHksKTInTMiLykDWLg1
# NOL5MKiy4qtPB+a9yBN0SzylwKwi5hHeMhJ+N0RScoYpCnC13Zxa/H+BV2c/u867
# 6W9rGTX5mOtgZnlk6x+uVBTOZsPcFwCALjMafJeeizlStvXCrCS4UnAytNw7cs8k
# UOXShW7v3TtcFE1uqOngLqrkpa0lnFoihhdQtE36Z+aGWWRGnQDVDbB8BJzwb5FK
# FdoLnFf1k1hI7tNt7Yx3po+VTMtpu5L6VsNzX43wUmAi4BJbajrh3kOCwozqzqeI
# V1Hz0oGY6kgBdDNZ3GEjeOqVi51OFwYrnuZomK4DlCotXf7nLZ3Nt9k6Zq1t1it/
# sSN6uoN3/xi1t5O28329s3d9z8JQN6i1W0wCLe3HCDojMKxfRHY2DPN7D4sJAgMB
# AAGjggIaMIICFjAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQUK5ZoFZQgJSYZaEFaZQqhw+2JfoswHwYDVR0jBBgw
# FoAU6IPEM9fcnwycdpoKptTfh6ZeWO4wZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwQU9DJTIwQ0ElMjAwMS5jcmwwgaUGCCsGAQUFBwEBBIGY
# MIGVMGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L2NlcnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEFPQyUyMENB
# JTIwMDEuY3J0MC0GCCsGAQUFBzABhiFodHRwOi8vb25lb2NzcC5taWNyb3NvZnQu
# Y29tL29jc3AwZgYDVR0gBF8wXTBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcC
# ARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRv
# cnkuaHRtMAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEANt1ne/ExwVsGhIb4
# 8IkpkDDrf7maPRBuZvSSypL+DIVt7svR4rAGohHyFPZ9uJNsfPktrPKl9lSARqNC
# t7qwaNA9EaTZfrSU9D6GZ0D4m00PxSUfFePXzQ6wDNBifJ7SXkQnnBS+m4qlS+Uc
# 5WQWHHBLcBC9xJGAweCmyd45fAeQ4g6mHnYvynkJztA2e7x0WpXnKquyKYS01cQ+
# G/ktvzM8moGF76iNs1Rd8Rm0T5jm8yVImJRRiK3C1H2fYTFJ8HgABmc/2Tj8YsnI
# EOrF/nADUvZLocQ5olqpzHUnAw4tzUtwI2VOmppso9DoDpNLm8xpFlAsTxZE8rfk
# B6N1OBzJFMIngfYLWkFbIKUzgdbVLl8vdb99ih9Lq0Qe5g/dU9IoJm42iz7yWyrS
# BUWLM+7tgW7l/iSAqfxa/JyfeixlBB01hx4MFwwJ5tj5yYzdFTwgBkaiAqY3fYLK
# 5SZcw30CjHVOPjj2O8KVvuZcFwbnZFaecntcuGTBt7BTvxGmdDriHSAao8/znZve
# TnQxjagxhfdyYQFm63D3mpToaSvM/gSiKXqJPtFAMS0HtiDS02o7qdGW/lAm8qDy
# QaZZiXf24A5WNp59P+HB9/CdEk2svawMi0RV/pUldAZ353a8SnRacKUwOl4dcKgm
# tBWlZl3cij0Ng4PDmEFzlyHMbEUwggbmMIIEzqADAgECAhMzAATbCw7xpmHkhzTV
# AAAABNsLMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJp
# ZmllZCBDUyBBT0MgQ0EgMDEwHhcNMjUwODA3MTMwMTI0WhcNMjUwODEwMTMwMTI0
# WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmExDTALBgNV
# BAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMMTW9uZG9v
# LCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAtImfmLIUmNFe
# XXlztn9O437qEH2JDbzA2UiPj09xhzltzVWH6OSmIJh3C7xisVITM3MKatAbB2Ne
# U+vnIJ7GLI6ld2UaHUfqI30XSWQ5VUd8uOD1gSHksKTInTMiLykDWLg1NOL5MKiy
# 4qtPB+a9yBN0SzylwKwi5hHeMhJ+N0RScoYpCnC13Zxa/H+BV2c/u8676W9rGTX5
# mOtgZnlk6x+uVBTOZsPcFwCALjMafJeeizlStvXCrCS4UnAytNw7cs8kUOXShW7v
# 3TtcFE1uqOngLqrkpa0lnFoihhdQtE36Z+aGWWRGnQDVDbB8BJzwb5FKFdoLnFf1
# k1hI7tNt7Yx3po+VTMtpu5L6VsNzX43wUmAi4BJbajrh3kOCwozqzqeIV1Hz0oGY
# 6kgBdDNZ3GEjeOqVi51OFwYrnuZomK4DlCotXf7nLZ3Nt9k6Zq1t1it/sSN6uoN3
# /xi1t5O28329s3d9z8JQN6i1W0wCLe3HCDojMKxfRHY2DPN7D4sJAgMBAAGjggIa
# MIICFjAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUENjA0Bgor
# BgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY/W+D3Nur
# KjAdBgNVHQ4EFgQUK5ZoFZQgJSYZaEFaZQqhw+2JfoswHwYDVR0jBBgwFoAU6IPE
# M9fcnwycdpoKptTfh6ZeWO4wZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBWZXJpZmll
# ZCUyMENTJTIwQU9DJTIwQ0ElMjAwMS5jcmwwgaUGCCsGAQUFBwEBBIGYMIGVMGQG
# CCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRz
# L01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEFPQyUyMENBJTIwMDEu
# Y3J0MC0GCCsGAQUFBzABhiFodHRwOi8vb25lb2NzcC5taWNyb3NvZnQuY29tL29j
# c3AwZgYDVR0gBF8wXTBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0
# cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRt
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEANt1ne/ExwVsGhIb48IkpkDDr
# f7maPRBuZvSSypL+DIVt7svR4rAGohHyFPZ9uJNsfPktrPKl9lSARqNCt7qwaNA9
# EaTZfrSU9D6GZ0D4m00PxSUfFePXzQ6wDNBifJ7SXkQnnBS+m4qlS+Uc5WQWHHBL
# cBC9xJGAweCmyd45fAeQ4g6mHnYvynkJztA2e7x0WpXnKquyKYS01cQ+G/ktvzM8
# moGF76iNs1Rd8Rm0T5jm8yVImJRRiK3C1H2fYTFJ8HgABmc/2Tj8YsnIEOrF/nAD
# UvZLocQ5olqpzHUnAw4tzUtwI2VOmppso9DoDpNLm8xpFlAsTxZE8rfkB6N1OBzJ
# FMIngfYLWkFbIKUzgdbVLl8vdb99ih9Lq0Qe5g/dU9IoJm42iz7yWyrSBUWLM+7t
# gW7l/iSAqfxa/JyfeixlBB01hx4MFwwJ5tj5yYzdFTwgBkaiAqY3fYLK5SZcw30C
# jHVOPjj2O8KVvuZcFwbnZFaecntcuGTBt7BTvxGmdDriHSAao8/znZveTnQxjagx
# hfdyYQFm63D3mpToaSvM/gSiKXqJPtFAMS0HtiDS02o7qdGW/lAm8qDyQaZZiXf2
# 4A5WNp59P+HB9/CdEk2svawMi0RV/pUldAZ353a8SnRacKUwOl4dcKgmtBWlZl3c
# ij0Ng4PDmEFzlyHMbEUwggdaMIIFQqADAgECAhMzAAAABzeMW6HZW4zUAAAAAAAH
# MA0GCSqGSIb3DQEBDAUAMGMxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xNDAyBgNVBAMTK01pY3Jvc29mdCBJRCBWZXJpZmllZCBD
# b2RlIFNpZ25pbmcgUENBIDIwMjEwHhcNMjEwNDEzMTczMTU0WhcNMjYwNDEzMTcz
# MTU0WjBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgQU9DIENBIDAx
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAt/fAAygHxbo+jxA04hNI
# 8bz+EqbWvSu9dRgAawjCZau1Y54IQal5ArpJWi8cIj0WA+mpwix8iTRguq9JELZv
# TMo2Z1U6AtE1Tn3mvq3mywZ9SexVd+rPOTr+uda6GVgwLA80LhRf82AvrSwxmZpC
# H/laT08dn7+Gt0cXYVNKJORm1hSrAjjDQiZ1Jiq/SqiDoHN6PGmT5hXKs22E79Me
# FWYB4y0UlNqW0Z2LPNua8k0rbERdiNS+nTP/xsESZUnrbmyXZaHvcyEKYK85WBz3
# Sr6Et8Vlbdid/pjBpcHI+HytoaUAGE6rSWqmh7/aEZeDDUkz9uMKOGasIgYnenUk
# 5E0b2U//bQqDv3qdhj9UJYWADNYC/3i3ixcW1VELaU+wTqXTxLAFelCi/lRHSjaW
# ipDeE/TbBb0zTCiLnc9nmOjZPKlutMNho91wxo4itcJoIk2bPot9t+AV+UwNaDRI
# bcEaQaBycl9pcYwWmf0bJ4IFn/CmYMVG1ekCBxByyRNkFkHmuMXLX6PMXcveE46j
# Mr9syC3M8JHRddR4zVjd/FxBnS5HOro3pg6StuEPshrp7I/Kk1cTG8yOWl8aqf6O
# JeAVyG4lyJ9V+ZxClYmaU5yvtKYKk1FLBnEBfDWw+UAzQV0vcLp6AVx2Fc8n0vpo
# yudr3SwZmckJuz7R+S79BzMCAwEAAaOCAg4wggIKMA4GA1UdDwEB/wQEAwIBhjAQ
# BgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQU6IPEM9fcnwycdpoKptTfh6ZeWO4w
# VAYDVR0gBE0wSzBJBgRVHSAAMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTAZBgkrBgEEAYI3
# FAIEDB4KAFMAdQBiAEMAQTASBgNVHRMBAf8ECDAGAQH/AgEAMB8GA1UdIwQYMBaA
# FNlBKbAPD2Ns72nX9c0pnqRIajDmMHAGA1UdHwRpMGcwZaBjoGGGX2h0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMElEJTIwVmVy
# aWZpZWQlMjBDb2RlJTIwU2lnbmluZyUyMFBDQSUyMDIwMjEuY3JsMIGuBggrBgEF
# BQcBAQSBoTCBnjBtBggrBgEFBQcwAoZhaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlmaWVkJTIwQ29kZSUy
# MFNpZ25pbmclMjBQQ0ElMjAyMDIxLmNydDAtBggrBgEFBQcwAYYhaHR0cDovL29u
# ZW9jc3AubWljcm9zb2Z0LmNvbS9vY3NwMA0GCSqGSIb3DQEBDAUAA4ICAQB3/utL
# ItkwLTp4Nfh99vrbpSsL8NwPIj2+TBnZGL3C8etTGYs+HZUxNG+rNeZa+Rzu9oEc
# AZJDiGjEWytzMavD6Bih3nEWFsIW4aGh4gB4n/pRPeeVrK4i1LG7jJ3kPLRhNOHZ
# iLUQtmrF4V6IxtUFjvBnijaZ9oIxsSSQP8iHMjP92pjQrHBFWHGDbkmx+yO6Ian3
# QN3YmbdfewzSvnQmKbkiTibJgcJ1L0TZ7BwmsDvm+0XRsPOfFgnzhLVqZdEyWww1
# 0bflOeBKqkb3SaCNQTz8nshaUZhrxVU5qNgYjaaDQQm+P2SEpBF7RolEC3lllfuL
# 4AOGCtoNdPOWrx9vBZTXAVdTE2r0IDk8+5y1kLGTLKzmNFn6kVCc5BddM7xoDWQ4
# aUoCRXcsBeRhsclk7kVXP+zJGPOXwjUJbnz2Kt9iF/8B6FDO4blGuGrogMpyXkuw
# CC2Z4XcfyMjPDhqZYAPGGTUINMtFbau5RtGG1DOWE9edCahtuPMDgByfPixvhy3s
# n7zUHgIC/YsOTMxVuMQi/bgamemo/VNKZrsZaS0nzmOxKpg9qDefj5fJ9gIHXcp2
# F0OHcVwe3KnEXa8kqzMDfrRl/wwKrNSFn3p7g0b44Ad1ONDmWt61MLQvF54LG62i
# 6ffhTCeoFT9Z9pbUo2gxlyTFg7Bm0fgOlnRfGDCCB54wggWGoAMCAQICEzMAAAAH
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
# ji+tHD6n58vhavFIrmcxghc/MIIXOwIBATBxMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBBT0MgQ0EgMDECEzMABNsLDvGmYeSHNNUAAAAE2wswDQYJ
# YIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQg/IU0WLPizKaZNxnWpcWlTf5Grcge
# fPXq+7B4CV/1L58wDQYJKoZIhvcNAQEBBQAEggGAWGLDF+UHN2FB78R4HsIdb2YH
# 9XKHDgjY60NHaD0S5CqFQafJvFayATY9xM9kiBqrnNiu6S7lS1xHri2J7LPPX785
# zW03JJEe4sZ76G+Y83lVus0lJ3lPAkxxn7BN5jWYTkTax/rw73+6gI+ghNrbWgHT
# fb1g0NZLu/+IL3nTI4tlaZgso/ldTXKuH85xSINBtQ6ORk2071wS2GNHi1XMZZks
# i5yMRTzayVQQWWhOXvUzYrAiyBrluwQS+v8ZPNI7vkhFE8BIjRtfALFJ+BmMxQ+4
# JnlNe3n1GTNpQGjaVIRFmMkznrB8CTCY5WsqUYW3n+wXOZnEC1uHs+1vYTQBc1YQ
# c/h0bHeE1v6rnjYiORrQyJsxDXMlEL4sBe7TlzVLfxyxZQLyFSaBc+EV39OO88D6
# 43oLxba5vQQ7UZlewxvSrD61gCrdY0oLCXtyWgkvBAZPGr/56nkHAfSfxE8h4WbD
# l0iFV75/Vh4zC+WkACFJdxih8ok4I7OhCQbHMFwNoYIUvzCCFLsGCisGAQQBgjcD
# AwExghSrMIIUpwYJKoZIhvcNAQcCoIIUmDCCFJQCAQMxDzANBglghkgBZQMEAgIF
# ADCCAXAGCyqGSIb3DQEJEAEEoIIBXwSCAVswggFXAgEBBgorBgEEAYRZCgMBMEEw
# DQYJYIZIAWUDBAICBQAEMAy9CeKnqAHyb5RbthubAqUZtACI85yrzLRnUkQKitWC
# ky9+vZ6NDerBZLB9z0ylUAIGaIs+oEF9GBIyMDI1MDgwODExMTgwNS42NlowBIAC
# AfSggeCkgd0wgdoxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# JTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsT
# HVRoYWxlcyBUU1MgRVNOOkJCNzMtOTZGRC03N0VGMTUwMwYDVQQDEyxNaWNyb3Nv
# ZnQgUHVibGljIFJTQSBUaW1lIFN0YW1waW5nIEF1dGhvcml0eaCCDyAwggeCMIIF
# aqADAgECAhMzAAAABeXPD/9mLsmHAAAAAAAFMA0GCSqGSIb3DQEBDAUAMHcxCzAJ
# BgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xSDBGBgNV
# BAMTP01pY3Jvc29mdCBJZGVudGl0eSBWZXJpZmljYXRpb24gUm9vdCBDZXJ0aWZp
# Y2F0ZSBBdXRob3JpdHkgMjAyMDAeFw0yMDExMTkyMDMyMzFaFw0zNTExMTkyMDQy
# MzFaMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVzdGFtcGluZyBD
# QSAyMDIwMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAnnznUmP94MWf
# BX1jtQYioxwe1+eXM9ETBb1lRkd3kcFdcG9/sqtDlwxKoVIcaqDb+omFio5DHC4R
# BcbyQHjXCwMk/l3TOYtgoBjxnG/eViS4sOx8y4gSq8Zg49REAf5huXhIkQRKe3Qx
# s8Sgp02KHAznEa/Ssah8nWo5hJM1xznkRsFPu6rfDHeZeG1Wa1wISvlkpOQooTUL
# Fm809Z0ZYlQ8Lp7i5F9YciFlyAKwn6yjN/kR4fkquUWfGmMopNq/B8U/pdoZkZZQ
# bxNlqJOiBGgCWpx69uKqKhTPVi3gVErnc/qi+dR8A2MiAz0kN0nh7SqINGbmw5OI
# RC0EsZ31WF3Uxp3GgZwetEKxLms73KG/Z+MkeuaVDQQheangOEMGJ4pQZH55ngI0
# Tdy1bi69INBV5Kn2HVJo9XxRYR/JPGAaM6xGl57Ei95HUw9NV/uC3yFjrhc087qL
# JQawSC3xzY/EXzsT4I7sDbxOmM2rl4uKK6eEpurRduOQ2hTkmG1hSuWYBunFGNv2
# 1Kt4N20AKmbeuSnGnsBCd2cjRKG79+TX+sTehawOoxfeOO/jR7wo3liwkGdzPJYH
# gnJ54UxbckF914AqHOiEV7xTnD1a69w/UTxwjEugpIPMIIE67SFZ2PMo27xjlLAH
# WW3l1CEAFjLNHd3EQ79PUr8FUXetXr0CAwEAAaOCAhswggIXMA4GA1UdDwEB/wQE
# AwIBhjAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUa2koOjUvSGNAz3vYr0np
# Ptk92yEwVAYDVR0gBE0wSzBJBgRVHSAAMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTATBgNV
# HSUEDDAKBggrBgEFBQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAPBgNV
# HRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFMh+0mqFKhvKGZgEByfPUBBPaKiiMIGE
# BgNVHR8EfTB7MHmgd6B1hnNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L2NybC9NaWNyb3NvZnQlMjBJZGVudGl0eSUyMFZlcmlmaWNhdGlvbiUyMFJvb3Ql
# MjBDZXJ0aWZpY2F0ZSUyMEF1dGhvcml0eSUyMDIwMjAuY3JsMIGUBggrBgEFBQcB
# AQSBhzCBhDCBgQYIKwYBBQUHMAKGdWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
# a2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwSWRlbnRpdHklMjBWZXJpZmljYXRpb24l
# MjBSb290JTIwQ2VydGlmaWNhdGUlMjBBdXRob3JpdHklMjAyMDIwLmNydDANBgkq
# hkiG9w0BAQwFAAOCAgEAX4h2x35ttVoVdedMeGj6TuHYRJklFaW4sTQ5r+k77iB7
# 9cSLNe+GzRjv4pVjJviceW6AF6ycWoEYR0LYhaa0ozJLU5Yi+LCmcrdovkl53DNt
# 4EXs87KDogYb9eGEndSpZ5ZM74LNvVzY0/nPISHz0Xva71QjD4h+8z2XMOZzY7YQ
# 0Psw+etyNZ1CesufU211rLslLKsO8F2aBs2cIo1k+aHOhrw9xw6JCWONNboZ497m
# wYW5EfN0W3zL5s3ad4Xtm7yFM7Ujrhc0aqy3xL7D5FR2J7x9cLWMq7eb0oYioXhq
# V2tgFqbKHeDick+P8tHYIFovIP7YG4ZkJWag1H91KlELGWi3SLv10o4KGag42psw
# jybTi4toQcC/irAodDW8HNtX+cbz0sMptFJK+KObAnDFHEsukxD+7jFfEV9Hh/+C
# SxKRsmnuiovCWIOb+H7DRon9TlxydiFhvu88o0w35JkNbJxTk4MhF/KgaXn0GxdH
# 8elEa2Imq45gaa8D+mTm8LWVydt4ytxYP/bqjN49D9NZ81coE6aQWm88TwIf4R4Y
# ZbOpMKN0CyejaPNN41LGXHeCUMYmBx3PkP8ADHD1J2Cr/6tjuOOCztfp+o9Nc+Zo
# IAkpUcA/X2gSMkgHAPUvIdtoSAHEUKiBhI6JQivRepyvWcl+JYbYbBh7pmgAXVsw
# ggeWMIIFfqADAgECAhMzAAAARd975+cMCRaeAAAAAABFMA0GCSqGSIb3DQEBDAUA
# MGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# MjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVzdGFtcGluZyBDQSAy
# MDIwMB4XDTI0MTEyNjE4NDg0N1oXDTI1MTExOTE4NDg0N1owgdoxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
# bWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkJCNzMt
# OTZGRC03N0VGMTUwMwYDVQQDEyxNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1lIFN0
# YW1waW5nIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIB
# AMCO0/Q3QmA1J2H4+L2vjJPbXT5sdt3C8JRxyAPGRCLkxIKxVfBeYCABw874Hay6
# WgHzWLecvlbaceUR2xVSZ0YJ8FhNxawyhjta/pBV3F0Qsc2o2+67+5/qQUsIcMCp
# kHokwPFGTbo6LC0NVtKIzhC+8THOJeZsy7oAOgi+tfMC+4GmVsGjhqukUTgu2L9a
# 9fPstTtpkqBDMzN5Va9z7yI91E5rW6L0XmTnOzZT7hj0wMI17aqUtehlOw3+Aqwb
# wvWuZ/TNeaKgrVo2RGZbIHzMwNvCr0iqqkv1MkQVMGyxAtJD+nf6zs8stLsQoD9u
# fZ7c1BenPje15guV9ODxaOzkpynLCdNOI/VuIJIujLURwZT1tYQdxFJT8zH8e7z1
# ZPv9Hq4dwynuVFImeeGguoXJZN6nO+DqEXF5EYqoXhO3wyzJpBsxs4jH4ovKNStH
# 3A1IS9RLX39hi+htDd6rP9rLSa7ZuKMqFESWsJUzecifOc83BdV0mjOz+feY4Rc/
# IAeEAU77Ou8EGuZ6zCURzVk5b6mGyJqGGF+8oc5gFCxTt3rLJ67yK4hqYtab+Db6
# D0rL4KEO9A41VKw24n/IMDpSHn6XLp2xmMwijWQt6znsVOiRnlNDZWSwPVD2hd6c
# Xp4xBarGVla9ySn+v7G7LQCBbMjNmTjIr5SPKX2lkuFvAgMBAAGjggHLMIIBxzAd
# BgNVHQ4EFgQUJdDb6vUl0ETJp/Adxq89h2MrlfIwHwYDVR0jBBgwFoAUa2koOjUv
# SGNAz3vYr0npPtk92yEwbAYDVR0fBGUwYzBhoF+gXYZbaHR0cDovL3d3dy5taWNy
# b3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNBJTIw
# VGltZXN0YW1waW5nJTIwQ0ElMjAyMDIwLmNybDB5BggrBgEFBQcBAQRtMGswaQYI
# KwYBBQUHMAKGXWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2VydHMv
# TWljcm9zb2Z0JTIwUHVibGljJTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0ElMjAy
# MDIwLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMA4G
# A1UdDwEB/wQEAwIHgDBmBgNVHSAEXzBdMFEGDCsGAQQBgjdMg30BATBBMD8GCCsG
# AQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVw
# b3NpdG9yeS5odG0wCAYGZ4EMAQQCMA0GCSqGSIb3DQEBDAUAA4ICAQBsvbXnWngk
# +LHhRxiyoELXkYj8tLcDbaC6jlPNIFms6ItC+Qx0BoV4lQzFSW/c7tSFNyebpzcc
# GnfYQOv+I3rv5B4GRc9xBLM3M0+PNJ88Mevc1rVT7gh//2+4dajWdKe2CqWplA7t
# WYwVrkpoD4SvxoFS1yztU0Op7a428/GzCX9+R7FBVrwka2z6V+IYTXqVGy9I1N5d
# WBAh6JXg4ba56leb/q8/5V0MYRslUoz4fjU4PNF8JPDn/+7GmJ7zHVtvMaHpVCyG
# Jxak8T5/tbyiV9UJ5R8wQVLVilQz1P3zBEXFNlBdOdnIYp9EwkGsj/HAAXdY2GCC
# 0DGrYmCc0iwAHTYjzMf3JaaA9MNd3oKTA/Qd28dKsq7s9jECt9SkeGcKChi3wsLr
# msswdmhA3Kd0PklRoJ4GJ/Emk453lGS6IYf1pPQOCzpGYQwWIxUNQaLW03PSmFFd
# OSVzWoXjEsEYhULgnmZ07asITflKUzvpWRswY8T2E1zm0GK2Or7AeI85oM1dvlJB
# Oidp3MyT+i3Yoxq9jyj6UN21RvHaapzmmPGoSrUKLqE3yTxxtuQa619sIT3IfMWQ
# WElp9DWI/8mSo3v3K6iWL1KBAC4aJkG7gVOfhb+FP0fMczFBiYKHhyIfJ/TqDTdi
# RLTDnsqSOqE6xlUbSmLR8mZm+GuYFDPE1zGCA+QwggPgAgEBMHgwYTELMAkGA1UE
# BhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMp
# TWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIwMjACEzMAAABF
# 33vn5wwJFp4AAAAAAEUwDQYJYIZIAWUDBAICBQCgggE9MBoGCSqGSIb3DQEJAzEN
# BgsqhkiG9w0BCRABBDA/BgkqhkiG9w0BCQQxMgQw/I1te+CrS2YHc0zPe1AU3YbD
# 9LWwON17UafqAeoTUZwujw5Gd0VubWU0WbDVckLiMIHdBgsqhkiG9w0BCRACLzGB
# zTCByjCBxzCBoAQguARVOsjIij9x4y/muE8czvSIz0XS68pBFQ5+Id/SbnEwfDBl
# pGMwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENB
# IDIwMjACEzMAAABF33vn5wwJFp4AAAAAAEUwIgQgXVo6FP6VqwTGR3RLhVgVVLbG
# ZxDw75/vRP3s/V3vMxYwDQYJKoZIhvcNAQEMBQAEggIAnX+umeazaWCHaFKoT/9W
# XL7i08VSRmRxM1oqGJsZ5xE5YTVg0CWDnzhpsmaOJ9ed6hXqwp5FUIfrQlsUhZb3
# UVRZD12FCSuFMgPrBuGTHLGMw81k1bJy42TZwufxYxaYS1sK/Nh0NGsufFk5kSHr
# 9FOK4utzvreBdiUbYzUUl6odW6KuNyJoiPsNwEmHYS/0kRw8YYYus9EZpcqMMWFz
# L3G7c4I1hDbymdkAUvu74theJ7UHvpV6qSr7mvXEi99mgcmb44kBoeE6pLch6SMx
# cyWtx2YuBP4nWYAz+LfBJdXXAWrhZVN1vH23DABXvb5XRoJixpg2XnM9x66flPKy
# fg/fc4E3rFBFIwKSwxHRolaTnbk3x3Az/tJVJXpWXAx8QH952/n5C6e2aF6JsPoP
# fRfbmWOa1Xuxv7tdJY4s+R3sbEdA0AljsfZjWjMjqFecVzR3E8xwYopUmstErpRT
# ath9NSj1ZkRzR8UMSh5UL4FbAsNHUZS8QfCZjg3+yL7E3vi6ZhNkZzp0lSzZPQYc
# XKYpwYe9J0yoxaCPKKknLS+/xYxTNngLBArGbZS49oXuIwDmTWW8Ds3Z9Znyc1Np
# cEt7rMqNLOlmL/ireP2rCE8cF/+KS1HQMxwLj4S4D+b0pjU53Eo1dACeC+Bw7AKv
# w/eRbYdwBW6364ZjZibh628=
# SIG # End signature block
