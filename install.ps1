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
    .PARAMETER Annotation
    (Optional) Comma-separated key=value pairs to annotate the asset in mondoo.yml
    .PARAMETER Name
    (Optional) A custom asset name (defaults to machine hostname)
    .EXAMPLE
    Import-Module ./install.ps1; Install-Mondoo -RegistrationToken 'INSERTKEYHERE' -Annotation 'env=prod,role=db' -Name 'db-server-01'
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
      [string]   $taskpath = "Mondoo",
      [string]   $Timer = '60',
      [string]   $Splay = '60',
      [string]   $Annotation = '',
      [string]   $Name = ''
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

  function CreateAndRegisterMondooUpdaterTask($taskname, $taskpath) {
    info " * Create and register the Mondoo update task"
    NewScheduledTaskFolder $taskpath

    $taskArgument = '-NoProfile -WindowStyle Hidden -ExecutionPolicy RemoteSigned -Command &{ [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $wc = New-Object Net.Webclient; '
    if (![string]::IsNullOrEmpty($Proxy)) {
      $taskArgument += '$wc.proxy = New-Object System.Net.WebProxy("' + $Proxy + '"); '
    }
    $taskArgument += 'iex ($wc.DownloadString("https://install.mondoo.com/ps1")); Install-Mondoo '
    $taskArgument += '-Product ' + $Product + ' '
    $taskArgument += '-Path "' + $Path + '" '

    if ($Service.ToLower() -eq 'enable' -and $Product.ToLower() -eq 'mondoo') {
      $taskArgument += '-Service enable '
    }
    if (![string]::IsNullOrEmpty($Annotation)) {
      $taskArgument += '-Annotation ' + $Annotation + ' '
    }
    if (![string]::IsNullOrEmpty($Name)) {
      $taskArgument += '-Name ' + $Name + ' '
    }
    if (![string]::IsNullOrEmpty($Proxy)) {
      $taskArgument += '-Proxy ' + $Proxy + ' '
    }
    if ($UpdateTask.ToLower() -eq 'enable') {
      $taskArgument += '-UpdateTask enable -Time ' + $Time + ' -Interval ' + $Interval +' '
    }
    $taskArgument += ';}'

    $action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $taskArgument
    $trigger = New-ScheduledTaskTrigger -Daily -DaysInterval $Interval -At $Time
    $principal = New-ScheduledTaskPrincipal -GroupId "NT AUTHORITY\SYSTEM" -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -Compatibility Win8

    Register-ScheduledTask -Action $action -Settings $settings -Trigger $trigger -TaskName $taskname -Description "$Product Updater Task" -TaskPath $taskpath -Principal $principal

    if (Get-ScheduledTask -TaskName $taskname -EA 0) {
        success "* $Product Updater Task installed"
    } else {
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

  # check if we are on 64-bit intel, 64-bit arm, or a 32-bit process on a 64-bit intel system:
  If ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64' -and $env:PROCESSOR_ARCHITECTURE -ne 'ARM64' -and -not (($env:PROCESSOR_ARCHITECTURE -eq "x86" -and [Environment]::Is64BitOperatingSystem))) {
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
  info ("  Scan Interval:     {0}" -f $Timer)
  info ("  Splay:             {0}" -f $Splay)
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
  if ($env:PROCESSOR_ARCHITECTURE -match "ARM") {
    $arch = 'arm64'
  }
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
      If (![string]::IsNullOrEmpty($Timer)) {
          $login_params = $login_params + @("--timer", "$Timer")
      }
      If (![string]::IsNullOrEmpty($Splay)) {
          $login_params = $login_params + @("--splay", "$Splay")
      }
      if (![string]::IsNullOrEmpty($Annotation)) {
          $login_params = $login_params + @('--annotation',$Annotation)
      }
      if (![string]::IsNullOrEmpty($Name))       {
          $login_params = $login_params + @('--name',$Name)
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
# MII9/wYJKoZIhvcNAQcCoII98DCCPewCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBLyqvq8H/MTVGh
# p4bb4s9sKwk/KL2BP+9i+quHJS6hkqCCIqQwggXMMIIDtKADAgECAhBUmNLR1FsZ
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
# ji+tHD6n58vhavFIrmcxghqxMIIarQIBATBxMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBBT0MgQ0EgMDICEzMABLsK/JFojq5yAbcAAAAEuwowDQYJ
# YIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQgjGfbFD5aaOL/mHVVzF70Ro1wvIKr
# Zbm//QhqimJ7R/AwDQYJKoZIhvcNAQEBBQAEggGATrOQGzAPm5yuDUM83MARu0Us
# v6aJBI4z6yFo+/BqbPb357KmMdxfwGG0/U0E1YvBR9bBVzIl/v1wkjC0SVlQhlK1
# FQ8t6n6sI6um07ZdmP4jbuEUn4hpWTCzV69W5O0s8FMYbIjXWxlsJ8QikLLRRuK5
# OLIzqizG7S8WEjTTg4SE5G076C8lW9JoHBpMMB60kTJjlD93WZCWsUvZo0ytUtvq
# pQ1kjB8ELLI3mfWYaGiPX2lFYFoCM/hlqrG3NIUUmUQk2BC92n/2gDBIjSjmUpTS
# WTWWMQX1i9pVXR5CxCIhz8d2YZ470rFUrLlPedOmrKmCV/A/UHr5xo6AFeRCFmZf
# rMgzs+RiC18nF1/PYAf7LsI/8K1+LSSjRLuw1sDazooMbttIpfrnCJnpx7t2MD9U
# lg0DNvIgqkdsATNzCKie/UzNDS9en2ZCrI580f4MMQOWPqANpKjnXESDg9Yo0bMF
# KsX8Q+4VTMzGIHbuewxvpLOX0MNRjGX5HNBlBYi6oYIYMTCCGC0GCisGAQQBgjcD
# AwExghgdMIIYGQYJKoZIhvcNAQcCoIIYCjCCGAYCAQMxDzANBglghkgBZQMEAgIF
# ADCCAXIGCyqGSIb3DQEJEAEEoIIBYQSCAV0wggFZAgEBBgorBgEEAYRZCgMBMEEw
# DQYJYIZIAWUDBAICBQAEMOCKEwcF7p+jaoxYKvdzqugp/YKZK0Z/VFKKDWu/H3at
# 1G+SK+U9ydq806bnJ9522QIGaFl186LSGBMyMDI1MDgwNzA5NDc0NS4zMzdaMASA
# AgH0oIHhpIHeMIHbMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
# MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScwJQYDVQQL
# Ex5uU2hpZWxkIFRTUyBFU046QTUwMC0wNUUwLUQ5NDcxNTAzBgNVBAMTLE1pY3Jv
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
# WzCCB5cwggV/oAMCAQICEzMAAABIVXdyHnSSt/cAAAAAAEgwDQYJKoZIhvcNAQEM
# BQAwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENB
# IDIwMjAwHhcNMjQxMTI2MTg0ODUyWhcNMjUxMTE5MTg0ODUyWjCB2zELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0
# IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOkE1
# MDAtMDVFMC1EOTQ3MTUwMwYDVQQDEyxNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1l
# IFN0YW1waW5nIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAMt+gPdn75JVMhgkWcWc+tWUy9oliU9OuicMd7RW6IcA2cIpMiryomTjB5n5
# x/X68gntx2X7+DDcBpGABBP+INTq8s3pB8WDVgA7pxHu+ijbLhAMk+C4aMqka043
# EaP185q8CQNMfiBpMme4r2aG8jNSojtMQNXsmgrpLLSRixVxZunaYXhEngWWKoSb
# vRg1LAuOcqfmpghkmhBgqD1lZjNhpuCv1yUeyOVm0V6mxNifaGuKby9p4713KZ+T
# umZetBfY7zlRCXyToArYHwopBW402cFrfsQBZ/HGqU73tY6+TNug1lhYdYU6VLdq
# SW9Jr7vjY9JUjISCtoKCSogxmRW7MX7lCe7JV6Rdpn+HP7e6ObKvGyddRdtdiZCL
# p6dPtyiZYalN9GjZZm360TO+GXjpiZD0gZER+f5lEFavwIcD7HarW6qD0ZN81S+R
# DgfEtJ67h6oMUqP1WIiFC75if8gaK1aO5+Z8EqnaeKALgUVptF7i9KGsDvEm2ts4
# WYneMAhG2+7Z25+IjtW4ZAI83ZtdGOJp9sFd68S6EDf33wQLPi7CcZ9IUXW74tLv
# INktvw3PFee6I3hs/9fDcCMoEIav+WeZImILCgwRGFcLItvwpSEA7NcXToRk3TGf
# C53YD3g5NDujrqhduKLbVnorGOdIZXVeLMk0Jr4/XIUQGpUpAgMBAAGjggHLMIIB
# xzAdBgNVHQ4EFgQUpr139LrrfUoZ97y6Zho7Nzwc90cwHwYDVR0jBBgwFoAUa2ko
# OjUvSGNAz3vYr0npPtk92yEwbAYDVR0fBGUwYzBhoF+gXYZbaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNB
# JTIwVGltZXN0YW1waW5nJTIwQ0ElMjAyMDIwLmNybDB5BggrBgEFBQcBAQRtMGsw
# aQYIKwYBBQUHMAKGXWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0El
# MjAyMDIwLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
# MA4GA1UdDwEB/wQEAwIHgDBmBgNVHSAEXzBdMFEGDCsGAQQBgjdMg30BATBBMD8G
# CCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3Mv
# UmVwb3NpdG9yeS5odG0wCAYGZ4EMAQQCMA0GCSqGSIb3DQEBDAUAA4ICAQBNrYvg
# HjRMA0wxiAI1dPL5y4pOMPM1nd0An5Lg9sAp/vwUHBDv2FiKGpn+oiDoZa3+NDkY
# CwFKkFgo1k4y1QwCs1B8iVnjbLa3KUA//EEZDrDCa7S4GZfODpbdOiZNnnpuH3SW
# Ltk7gFuKIKDYICSm+1O+uBi7sVu+9OpMi/8u9dBoInH6zG8k+xsgDJZRJ8hhN0Ba
# VWjrewnwCQfmnOmJ++QvJeYvGraNPLBp4P+kprMQnBcBvLz67TigIZUJkNsP6wM4
# nvneFuXpfJY5eYKldW+PbA+hcl0j5PoM+1z0Za0zFINQpm1UlXZRWAAJrPHyA4OJ
# 2PqHdobA6vxS38Ww79fzndDUJil8dZ9bckSQtzcWyUp/YqXbMfXgQGgt5SlPKSGf
# w1lR5eEey64qM/HyZQAtb8uCVSNlfInfIFDU+I56+nFOi3xp9dzquWr0UnaSC0zq
# KPa5bt/1q3nIhx3AUz1VSbRoKCJe+O9GRB5JQggCbjQtfaq97aR0+A179m3zJvnM
# NywmMeFk+1eJbdOcFRguoKwucPp9WHpflC8Vu2MuUEgy3deW8BCe5UTOGjK3eKzD
# D3Dy36gYKDho2H3gh0q9Q1LV9/EL5D5euxPfAOVKWo1It+ijGGwK7mBcq3Ol+HHz
# 7iX2tUcnGBkT2fAYqIBvA1fEoUHdtWCbCh0ltTGCB1MwggdPAgEBMHgwYTELMAkG
# A1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UE
# AxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIwMjACEzMA
# AABIVXdyHnSSt/cAAAAAAEgwDQYJYIZIAWUDBAICBQCgggSsMBEGCyqGSIb3DQEJ
# EAIPMQIFADAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZIhvcNAQkF
# MQ8XDTI1MDgwNzA5NDc0NVowPwYJKoZIhvcNAQkEMTIEMAoUfcrrkT5cOQQ9V+eZ
# Xsv1iX+bP+Lwd8E3zv9lxON8slgrzwHJMj08ts/FkbcbTDCBuQYLKoZIhvcNAQkQ
# Ai8xgakwgaYwgaMwgaAEIOoqAVebTwjWn0P0gLwZ03YfjX3QvDtHZEl38m8i8x1B
# MHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVzdGFtcGlu
# ZyBDQSAyMDIwAhMzAAAASFV3ch50krf3AAAAAABIMIIDXgYLKoZIhvcNAQkQAhIx
# ggNNMIIDSaGCA0UwggNBMIICKQIBATCCAQmhgeGkgd4wgdsxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVy
# aWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpBNTAwLTA1
# RTAtRDk0NzE1MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZSBTdGFt
# cGluZyBBdXRob3JpdHmiIwoBATAHBgUrDgMCGgMVAOYSfUGUVzjpxDh59/qJiDRZ
# aMMnoGcwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVzdGFt
# cGluZyBDQSAyMDIwMA0GCSqGSIb3DQEBCwUAAgUA7D6ebjAiGA8yMDI1MDgwNzAz
# MzkyNloYDzIwMjUwODA4MDMzOTI2WjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDs
# Pp5uAgEAMAcCAQACAjAxMAcCAQACAhMYMAoCBQDsP+/uAgEAMDYGCisGAQQBhFkK
# BAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJ
# KoZIhvcNAQELBQADggEBAARq0UcnGQBv7RNutcBg5HMjh+DGuka/K+xbmRmhpLv3
# 822hFrK9KmPUdOHYSCkVguqKqlzj0lSFGrvATi159g+dp61lTO/m5bTiUV9NBziD
# F4oG/uRNHFRHy8oXELv/4H6t+VvCWUVEkH8Xif0gtEnJEOm+AQMKcjRTYKGHAkVQ
# ldQk0IqqIQqTv7vUzBNyabtP5jLRqYWGwfbHyVqg7t4WhrpNRKpqwjISSWTic5Oe
# aENAPtljiA8QGZqyfG7rZrvYNIUGiHw++JMlJ43YPBRvefUhPKjMvzxntPSmLUlj
# 00I6CH71o7uwGhLy0OYRxW8mf6AGGQ/W5ekT8qqUcNkwDQYJKoZIhvcNAQEBBQAE
# ggIArZO+7Lk3D76sTaEkp6JbHdBeT+DNbescm2G7H3zXcwlf+DAmmyoksW3kMALz
# AUFch99Zm2spHVvH9lNOYO2o/Uotc74SbFVXGwCT4DXgnZMdCRjA2GiaF3GlIMhT
# zrOcLhwiN9nPxG2XdYQ6jusRFHabkH28jru3oIcO6VXHEdwyDcqOchQFT431cZ6H
# EksxLdh5hqla6kiW2NhM2OANu5hmmZHCiyF4JvHA09Nd+Tf3Com1XgSj+EpKtmV/
# 0goPqkWy+aWzgBV6HDKCg+xF116KDnUBHw4BszcaoWeCHukL5hxpBZnuo8h8oOT4
# U1kuQwkhec9KoWfu6PYQhZAHerVeFPg+5D5HAY3/biNkBN3dGihE/Uvu+U0lVtfh
# kpcPviBgVZI/jJ4A6JsFxf/XP0yLHTckix+ZLAQzLEsqwsQ/1Vc2LIZklHVvo555
# Es5CHahnWkr2ZiW2icnsaEQupQYBtJp87aZughbLt9lrHe4ItWoUkbQ9LMi9c8qY
# Cv82mIfOuJSOiMwAYmhjxPD5y8bP68RrPdHTmR+k58oHGWHZa2x5IW0e2pzUT5PX
# APwkpmjQMskRbDaeO0FpD2ABrNNE3tIX+sZb+vfIXRgTzyt/5U4dnk5GqyzB0/i2
# i1OEzUD92pQ3ykWkygyPPTLM0ePOM/eIWZU1582ekjR1t7c=
# SIG # End signature block
