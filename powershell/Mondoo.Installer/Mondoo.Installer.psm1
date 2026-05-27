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
  # mql and cnspec only ship as zip
  If ($product -ne 'mondoo') {
    $filetype = 'zip'
  }
  # get the installed mondoo version
  $Apps = @()
  $Apps += Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" # 32 Bit
  $Apps += Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" # 64 Bit
  $installed_version = $Apps | where-object Publisher -eq "Mondoo, Inc." | Select-Object -Last 1
  if ($installed_version){
    $installed_version | Add-Member -NotePropertyName version -NotePropertyValue $installed_version.DisplayVersion -Force
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
# MII9SAYJKoZIhvcNAQcCoII9OTCCPTUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCWj2U/WnIVDpe/
# Wbq983F93BO3SwzcUVmYArPMI6/GKqCCIeowggXMMIIDtKADAgECAhBUmNLR1FsZ
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
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggaiMIIEiqADAgECAhMzAAFgWgIZ
# tgVMEH4kAAAAAWBaMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBBT0MgQ0EgMDQwHhcNMjYwNTI3MDMyMzQ1WhcNMjYwNTMw
# MDMyMzQ1WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAsYkm
# uT/tO+a41SUwXfAHRsJ4eXTHDmOzAtOGADP++pFLDeFFofVQ0ykYNT9udbKuAPg/
# XEzbrz6lD0zL6DOEgCyCoZAwnWTOifLisJT5oEqkWC6mIRHcH/yCncfhWA97AGp6
# NeomaPXTWguetmv0kUYkN9umIXQtlOYfLWyjeK3Y3t8/cpvhMK02w8ZSW3ZK5lEk
# DYJ55bPJDmwDrvuwyJtZ7CpkKv9BcbG0cF5PSxEBUTtRfH/HgckmE4MRXSpjKYhZ
# g9P/5GMqQjMjqEHRxrLkdjYQMvahMnxMFqiyt/MFpLvwzPXaPWgiQo5bHNu40j/e
# Lc9jQzxCHOpHHpcZlkfJeOKr0W8p0vrpjuOqSWSqhIxTKaEv4ZZ1LiCiGF1B3aHC
# StvH8wryOmJGXPMIGCIgh2ku4bA+r+9tXwhBMbx6T8SWqFo9axnSOvO/o6zWD59u
# No7yLsk/F0EP4mHEY0zNMfy98IRuXGAvjHKsyDQoqMgaiIv/PW85DRQ3pORRAgMB
# AAGjggHWMIIB0jAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQU1vaDIaqPm2FyfMhKZVX4OsNXFHAwHwYDVR0jBBgw
# FoAUayVB3vtrfP0YgAotf492XapzPbgwZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwQU9DJTIwQ0ElMjAwNC5jcmwwdAYIKwYBBQUHAQEEaDBm
# MGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Nl
# cnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEFPQyUyMENBJTIw
# MDQuY3J0MFQGA1UdIARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wDQYJ
# KoZIhvcNAQEMBQADggIBACBFCQx0gv0pOIp1/eTJ+Ty/0/7t0ZzPXv0/scL1GDn/
# gHDJJgaxpj2EuhvBQIit7eUzGpLOQi0B604RgW8EExTujrsGEMzalYe1qauJShJN
# ahSG7adThtFzeJzfjnDKMYZaRVH0JERNKRALdmreqtE0B4eiHyuJnTP3REF2llwg
# z2tWK0ZkfNSgNeutqJPj9JSk5MEVYCktzQOdBNgGOJ0gU7Ixy4XNkygThywNJy8D
# IeXBWKlbGYTku4nINNWnHwVK2Y8ZwMsUD0e67rKsZInLMuha/HUsCq2nRVFsx+uN
# DaiN/iO/blwusjsjR8HcFW1NO3x6yKopOYCFGK0PveXaqLJrT4fSHfy1VTHfbjYk
# yM7wp5PLyNejrsagRfl8biyuow7mufewZ1kZaj/s1dppNp14m1wbUoq4FJ2sEYRU
# d4Spdh4x8hUVQikmx5qZYmoKP6qEGxC4pPriifFuiQUBfKst2LzjU+CJxEiNi33U
# pxXzMDn96W8TGQlvn79CUDB/R0WljnKO6/pd1yLkn+FJJjRf76dfDJcBckxuhxMK
# zz53pYoqkC6B/sPo/1G7ARaGavGOqgwqsXu+8bGrbSkREdHo8QNMg46hhk9dWutS
# oNq2SMGfqFC2hS2rWoVMUc2i/zEY2qFwX/eOHcleaH9vLmyuviq4R/exq4PAhYYH
# MIIGojCCBIqgAwIBAgITMwABYFoCGbYFTBB+JAAAAAFgWjANBgkqhkiG9w0BAQwF
# ADBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgQU9DIENBIDA0MB4X
# DTI2MDUyNzAzMjM0NVoXDTI2MDUzMDAzMjM0NVowYzELMAkGA1UEBhMCVVMxFzAV
# BgNVBAgTDk5vcnRoIENhcm9saW5hMQ0wCwYDVQQHEwRDYXJ5MRUwEwYDVQQKEwxN
# b25kb28sIEluYy4xFTATBgNVBAMTDE1vbmRvbywgSW5jLjCCAaIwDQYJKoZIhvcN
# AQEBBQADggGPADCCAYoCggGBALGJJrk/7TvmuNUlMF3wB0bCeHl0xw5jswLThgAz
# /vqRSw3hRaH1UNMpGDU/bnWyrgD4P1xM268+pQ9My+gzhIAsgqGQMJ1kzony4rCU
# +aBKpFgupiER3B/8gp3H4VgPewBqejXqJmj101oLnrZr9JFGJDfbpiF0LZTmHy1s
# o3it2N7fP3Kb4TCtNsPGUlt2SuZRJA2CeeWzyQ5sA677sMibWewqZCr/QXGxtHBe
# T0sRAVE7UXx/x4HJJhODEV0qYymIWYPT/+RjKkIzI6hB0cay5HY2EDL2oTJ8TBao
# srfzBaS78Mz12j1oIkKOWxzbuNI/3i3PY0M8QhzqRx6XGZZHyXjiq9FvKdL66Y7j
# qklkqoSMUymhL+GWdS4gohhdQd2hwkrbx/MK8jpiRlzzCBgiIIdpLuGwPq/vbV8I
# QTG8ek/ElqhaPWsZ0jrzv6Os1g+fbjaO8i7JPxdBD+JhxGNMzTH8vfCEblxgL4xy
# rMg0KKjIGoiL/z1vOQ0UN6TkUQIDAQABo4IB1jCCAdIwDAYDVR0TAQH/BAIwADAO
# BgNVHQ8BAf8EBAMCB4AwPQYDVR0lBDYwNAYKKwYBBAGCN2EBAAYIKwYBBQUHAwMG
# HCsGAQQBgjdhgqndkVaCp5bkUoGRmP1vg9zbqyowHQYDVR0OBBYEFNb2gyGqj5th
# cnzISmVV+DrDVxRwMB8GA1UdIwQYMBaAFGslQd77a3z9GIAKLX+Pdl2qcz24MGcG
# A1UdHwRgMF4wXKBaoFiGVmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEFPQyUyMENBJTIw
# MDQuY3JsMHQGCCsGAQUFBwEBBGgwZjBkBggrBgEFBQcwAoZYaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlm
# aWVkJTIwQ1MlMjBBT0MlMjBDQSUyMDA0LmNydDBUBgNVHSAETTBLMEkGBFUdIAAw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMA0GCSqGSIb3DQEBDAUAA4ICAQAgRQkMdIL9KTiK
# df3kyfk8v9P+7dGcz179P7HC9Rg5/4BwySYGsaY9hLobwUCIre3lMxqSzkItAetO
# EYFvBBMU7o67BhDM2pWHtamriUoSTWoUhu2nU4bRc3ic345wyjGGWkVR9CRETSkQ
# C3Zq3qrRNAeHoh8riZ0z90RBdpZcIM9rVitGZHzUoDXrraiT4/SUpOTBFWApLc0D
# nQTYBjidIFOyMcuFzZMoE4csDScvAyHlwVipWxmE5LuJyDTVpx8FStmPGcDLFA9H
# uu6yrGSJyzLoWvx1LAqtp0VRbMfrjQ2ojf4jv25cLrI7I0fB3BVtTTt8esiqKTmA
# hRitD73l2qiya0+H0h38tVUx3242JMjO8KeTy8jXo67GoEX5fG4srqMO5rn3sGdZ
# GWo/7NXaaTadeJtcG1KKuBSdrBGEVHeEqXYeMfIVFUIpJseamWJqCj+qhBsQuKT6
# 4onxbokFAXyrLdi841PgicRIjYt91KcV8zA5/elvExkJb5+/QlAwf0dFpY5yjuv6
# Xdci5J/hSSY0X++nXwyXAXJMbocTCs8+d6WKKpAugf7D6P9RuwEWhmrxjqoMKrF7
# vvGxq20pERHR6PEDTIOOoYZPXVrrUqDatkjBn6hQtoUtq1qFTFHNov8xGNqhcF/3
# jh3JXmh/by5srr4quEf3sauDwIWGBzCCBygwggUQoAMCAQICEzMAAAAWMZKNkgJl
# e5oAAAAAABYwDQYJKoZIhvcNAQEMBQAwYzELMAkGA1UEBhMCVVMxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjE0MDIGA1UEAxMrTWljcm9zb2Z0IElEIFZl
# cmlmaWVkIENvZGUgU2lnbmluZyBQQ0EgMjAyMTAeFw0yNjAzMjYxODExMjlaFw0z
# MTAzMjYxODExMjlaMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJpZmllZCBDUyBB
# T0MgQ0EgMDQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDKVfrI2+gJ
# MM/0bQ5OVKNdvOASzLbUUMvXuf+Vl7YGuofPaZHVo3gMHF5inT+GMSpIcfIZ9qtX
# U1UG68ry8vNbQtOL4Nm30ifXpqI1+ByiAWLO1YT0WnzG7XPOuoTeeWsNZv5FmjxC
# sReBZvyzyzCyXZbu1EQfJxWTH4ebUwtAiW9rqMf9eDj/wYhiEfNteJV3ZFeibD2z
# tCHr9JhFdd97XbnCHgQoTIqc02X5xlRKtUGBa++OtHBBjiJ/uwBnzTkqu4FjpZjQ
# eJtrmda+ur1CT2jflWIB/ypn7u7V9tvW9wJbJYt/H2EtJ0GONWxJZ7TEu8jWPind
# OO3lzPP7UtzS/mVDV94HucWaltmsra6zSG8BoEJ87IM8QSb7vfm/O41FhYkUv89W
# Ij5ES2O4kxyiMSfe95CMivCuYrRP2hKvx7egPMrWgDDBkxMLgrKZO9hRNUMm8vk3
# w5b9SogHOyJVhxyFm8aFXfIxgqDF4S0g4bhbhnzljmSlCLlumMZcXFGDjpF2tNoA
# u3VGFGYtHtTSNVKvZpgB3b4ynaoDkbPf+Wg4523jt4VneasBgZhC1srZI2NCnCBB
# fgjLq04pqEKAWEohyW2K29KSkkHvt5VaE1ac3Yt+oyiOzMS57tXwQDJLGvLg/OXF
# O0VNvczDndfIfXYExB/ab2PuMSwd5VIBOwIDAQABo4IB3DCCAdgwDgYDVR0PAQH/
# BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRrJUHe+2t8/RiACi1/
# j3ZdqnM9uDBUBgNVHSAETTBLMEkGBFUdIAAwQTA/BggrBgEFBQcCARYzaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBkG
# CSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMBIGA1UdEwEB/wQIMAYBAf8CAQAwHwYD
# VR0jBBgwFoAU2UEpsA8PY2zvadf1zSmepEhqMOYwcAYDVR0fBGkwZzBloGOgYYZf
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIw
# SUQlMjBWZXJpZmllZCUyMENvZGUlMjBTaWduaW5nJTIwUENBJTIwMjAyMS5jcmww
# fQYIKwYBBQUHAQEEcTBvMG0GCCsGAQUFBzAChmFodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBD
# b2RlJTIwU2lnbmluZyUyMFBDQSUyMDIwMjEuY3J0MA0GCSqGSIb3DQEBDAUAA4IC
# AQAG1VBeVHTVRBljlcZD3IiMxwPyMjQyLNaEnVu5mODm2hRBJfH8GsBLATmrHAc8
# F47jmk5CnpUPiIguCbw6Z/KVj4Dsoiq228NSLMLewFfGMri7uwNGLISC5ccp8vUd
# ADDEIsS2dE+QI9OwkDpv3XuUD7d+hAgcLVcMOl1AsfEZtsZenhGvSYUrm/FuLq0B
# qEGL9GXM5c+Ho9q8o+Vn/S+GWQN2y+gkRO15s0kI05nUpq/dOD4ri9rgVs6tipEd
# 0YZqGgD+CZNiaZWrDTOQbNPncd2F9qOsUa20miYruoT5PwJAaI+QQiTE2ZJeMJOk
# OpzhTUgqVMZwZidEUZKCqudaeQA08WwnkQMfKyHzaU8j48ULcU4hUwvMsv7fSurO
# e9GAdRQCPvF8WcSK5oDHe8VVJM4tv6KKCm91HqLx9JamBgRI6R2SfY3nu26EGznu
# 0rCg/769z8xWm4PVcC2ZaL6VlKVqFp1NsN8YqMyf5t+bbGVb09noFKcJG/UwyGlx
# RmQBlfeBUQx5/ytlzZzsEnhrJF9fTAfje8j3OdX5lEnePTFQLRlvzZFBqUXnIeQK
# v3fHQjC9m2fo/Z01DII/qp3d8LhGVUW0BCG04fRwHJNH8iqqCG/qofMv+kym2AxB
# DnHzNgRjL60JOFiBgiurvLhYQNhB95KWojFA6shQnggkMTCCB54wggWGoAMCAQIC
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
# c29mdCBJRCBWZXJpZmllZCBDUyBBT0MgQ0EgMDQCEzMAAWBaAhm2BUwQfiQAAAAB
# YFowDQYJYIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQgVeoKcOjq+O+kQndncrAG
# L8pcSBxgKnVOAZO+o54T2iMwDQYJKoZIhvcNAQEBBQAEggGAcl621cA0ZELkSPQr
# fw9cURgv/H29qaEl7I0BpAkT37DOjsy/KVlw1/BXVMwn/a19v0tmvSPdZkSlhEJ9
# 2+vdqmBgJ8XcMfzc5gZdewgVV4ok7wcI9in6Xek91TRZBB7xmY/ojlg3KWtbcVc9
# 9RF0Lg5Vv9zzlHZxGU6IqZTQ3kH1YhysXGNcjeRFillPyqhUnYyXU2JEz+2eKcad
# tqpB+og4sc7FfU2I/4gbxYFYm2GO7cJAIroLJrfIaa9gC/NzAU45B3bA1iSsKSTr
# An659PFGtlU8YRzr2EKm+nCpQ9Cc4vQcH2vYgiRuheisLVWyJ0CJVw3Czldr2spI
# Fm93jNN8l4k98xlHfas9hmhUSqd9ukK9qhgE9Wi7kSd6Ub2en9v+o7HCOGgwI3fC
# s4aURx0dVpAfdoWVvlFB8mfZRLD89+rrBtJZ5NgO48ltmd1XZmfnNVpOeECj6n8H
# U4qrmYyU4lrbiLTwuBLQd4N7nK8FmaEeLLaY3ue8B4xIvC5voYIYNDCCGDAGCisG
# AQQBgjcDAwExghggMIIYHAYJKoZIhvcNAQcCoIIYDTCCGAkCAQMxDzANBglghkgB
# ZQMEAgIFADCCAXIGCyqGSIb3DQEJEAEEoIIBYQSCAV0wggFZAgEBBgorBgEEAYRZ
# CgMBMEEwDQYJYIZIAWUDBAICBQAEMNorvKaT/4qU+Pa7r5h6t8BvJmS67kGKhP9X
# T19opfKDmB/FrJDC7XBHO3Ed3U6XngIGagxE5nAtGBMyMDI2MDUyNzExMjQyNS4x
# MzZaMASAAgH0oIHhpIHeMIHbMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScw
# JQYDVQQLEx5uU2hpZWxkIFRTUyBFU046NzgwMC0wNUUwLUQ5NDcxNTAzBgNVBAMT
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
# GHumaABdWzCCB5cwggV/oAMCAQICEzMAAABXJNOV4KLpyTEAAAAAAFcwDQYJKoZI
# hvcNAQEMBQAwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1w
# aW5nIENBIDIwMjAwHhcNMjUxMDIzMjA0NjUzWhcNMjYxMDIyMjA0NjUzWjCB2zEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWlj
# cm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1Mg
# RVNOOjc4MDAtMDVFMC1EOTQ3MTUwMwYDVQQDEyxNaWNyb3NvZnQgUHVibGljIFJT
# QSBUaW1lIFN0YW1waW5nIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBALFspQqTCH24syS2NZD1ztnJl9h0Vr0WwJnikmeXse/4wspnVexG
# qfiHNoqkbVg5CinuYC+iVfNMLZ+QtqhySz8VGBSjRt1JB5ACNtTKAjfmFp4U/Cv2
# Lj4m+vuve9I3W3hSiImTFsHeYZ6V/Sd43rXrhHV26fw3xQSteSbg9yTs1rhdrLkA
# j4KmI0D5P4KavtygirVyUW10gkifWLSE1NiB8Jn3RO5dj32deeMNONaaPnw3k49I
# CTs3Ffyb+ekNDPsNfYwCqPyOTxM6y1dSD0J5j+KK9V+EWyV5PDjV8jjn1zsStlS6
# TcYJJStcgHs2xT9rs6ooWl5FtYfRkCxhDShEp3s8IHUWizTWmLZvAE/6WR2Cd+Zm
# VapGXTCHJKUByZPxdX0i8gynirR+EwuHHNxEilDICLatO2WZu+CQrH4Zq0NYo1TQ
# 4tUpZ/kAWpoAu1r4mW5EJ3HkEavQ2PuoQDcDq2rAGVIla9pD7o9Yxwzl81BuDvUE
# yu9D/6F0qmQDdaE791HxfCUxpgMYPpdWTzs+dDGPehwQ8P92yP8ARjby5Ony1Z68
# RjeQebpxf5WL441myFHcgT1UJzzil7tPEkR22NfTNR6Fl+jzWb/r80nqlXllhynS
# owtxo1Y22xqYviS24smikUsBKqOPbSS77uvXEO3VrG5LGouE1EZ1Y9pjAgMBAAGj
# ggHLMIIBxzAdBgNVHQ4EFgQUjoPJXi01DgIJSGfm416Yg+0SkqcwHwYDVR0jBBgw
# FoAUa2koOjUvSGNAz3vYr0npPtk92yEwbAYDVR0fBGUwYzBhoF+gXYZbaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwUHVibGlj
# JTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0ElMjAyMDIwLmNybDB5BggrBgEFBQcB
# AQRtMGswaQYIKwYBBQUHMAKGXWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY2VydHMvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNBJTIwVGltZXN0YW1waW5n
# JTIwQ0ElMjAyMDIwLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMA4GA1UdDwEB/wQEAwIHgDBmBgNVHSAEXzBdMFEGDCsGAQQBgjdMg30B
# ATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L0RvY3MvUmVwb3NpdG9yeS5odG0wCAYGZ4EMAQQCMA0GCSqGSIb3DQEBDAUAA4IC
# AQBydcB2POmZOUlAQz2NuXf7vWCVWmjWu9bsY1+HMjv1yeLjxDQkjsJEU5zaIDy8
# Uw9BYN8+ExX/9k/9CBUsXbVlbU44c65/liyJ83kWsFIUwhVazwSShFlbIZviIO/5
# weyWyTfPPpbSJgWy+ZE9UrQS3xulJLAHA2zUkMMPdAlF4RrngcZZ0r45AF9aIYjd
# estWwdrNK70MfArHqZdgrgXn03w6zBs1v7czceWGitg/DlsHqk1mXBpSTuGI2TSP
# N3E60IIXx5f/AFzh4/HFi98BBZbUELNsXkWAG9ynZ5e6CFiil1mgWCWOT90D7Igv
# g0zKe3o3WCk629/en94K/sC/zLOf2d7yFmTySb9fKjcONH1Db3kZ8MzEJ8fHTNmx
# rl10Gecuz/Gl0+ByTKN+PambZ+F0MIlBPww6fvjFC9JII73fw3qO169+9TxTz2G+
# E26GYY1dcffsAhw6DqTQgbflbl1O/MrSXSs0NSb9nBD9RfR/f8Ei7DA1L1jBO7vZ
# hhJTjw2TzFa/ALgRLi3W00hHWi8LGQaZc8SwXIMYWfwrN9MgYbhN0Iak9WA2dqWu
# ekXsTwNkmrD3E6E+oCYCehNOgZmds0Ezb1jo7OV0Kh22Ll3KHg3MHtlGguxAzhg/
# BpixPS4qrULLkAjO7+yNsUfrD2U9gMf/OR4yJDPtzM0ytTGCB1YwggdSAgEBMHgw
# YTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEy
# MDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIw
# MjACEzMAAABXJNOV4KLpyTEAAAAAAFcwDQYJYIZIAWUDBAICBQCgggSvMBEGCyqG
# SIb3DQEJEAIPMQIFADAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZI
# hvcNAQkFMQ8XDTI2MDUyNzExMjQyNVowPwYJKoZIhvcNAQkEMTIEMI02C7hxIgxE
# mETtREbR+kNz1u1f/OOR8KD16vhLGwu05VPYMa4stpR8jFaoBlpMCDCBuQYLKoZI
# hvcNAQkQAi8xgakwgaYwgaMwgaAEIPU8n2S1BW5MZYhsos7h/VVQ6VRTb0BEISkN
# mYVMeNtSMHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVz
# dGFtcGluZyBDQSAyMDIwAhMzAAAAVyTTleCi6ckxAAAAAABXMIIDYQYLKoZIhvcN
# AQkQAhIxggNQMIIDTKGCA0gwggNEMIICLAIBATCCAQmhgeGkgd4wgdsxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29m
# dCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo3
# ODAwLTA1RTAtRDk0NzE1MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGlt
# ZSBTdGFtcGluZyBBdXRob3JpdHmiIwoBATAHBgUrDgMCGgMVAP0vMTmcQlEBQTZK
# zfFooo9cecvDoGcwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRp
# bWVzdGFtcGluZyBDQSAyMDIwMA0GCSqGSIb3DQEBCwUAAgUA7cFPTzAiGA8yMDI2
# MDUyNzExMDkwM1oYDzIwMjYwNTI4MTEwOTAzWjB3MD0GCisGAQQBhFkKBAExLzAt
# MAoCBQDtwU9PAgEAMAoCAQACAgC1AgH/MAcCAQACAhH1MAoCBQDtwqDPAgEAMDYG
# CisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEA
# AgMBhqAwDQYJKoZIhvcNAQELBQADggEBAL+L2kf1ZN9lNe9Jarkj+YEavSE0GUV7
# lHxQTTKjm9ksLTif57q3UfWSdsKWGWXZq6hFn1V89hLjjr43waG2p2pSTcasrIRc
# NWaxwsonUTZl77YW24d16NK8QkoXcmsVvLy4G43MTqsPQxwP2yJPEPscDy3Jygh3
# Zvrcc3QKuw/SJsVfTL+EiboWmhtpZ6Ys1ysfaaXfVLb6zXsrjw59f2ztWtJLEeKT
# 2ABsIUPRL+OOGogM6lUu1Bcb1VmC8IEgs2AZ04gfDyI1JpxtsR/iRGb1vWW22isO
# xfkbqWkKE3R8kWDNEL4n94kd2VwgmP9uEsW49ULsXikJZ/e6WmAq+m4wDQYJKoZI
# hvcNAQEBBQAEggIAO7epez7OF0HzJOWhJjLlnsp5UvDh1moRsnq9QRRu2RDv7e3n
# iIgs26VJjk06Tm+AZA8qNcKpy/tf0yM//+k4vwgY6NUsu7iE+bMZwHZ3e55pK0xj
# cMB2Si4JRlUr/IEmsxzZQnUt1puSUGCNv6BHDs43da7N/83loHIgyzM73p8OSWcf
# IMdQSISbiR+Z4kQQxXYOY7AjhjQAGytjU9roQLRLm+8a7VWq3+FqXxEJM5+MmsgA
# 4KYPW0218QODYdwDihwdRpkg92qJdvuk6R20IJzrOPFU09b10dmU6sAssHzERJkO
# KSKAl3kEstkwiTOePmZi8Jblnk/fJQAAe07QGpcjcx4lnSUvR2CaGXcsxyJj5xP6
# FQLdlhZfgFPLXcn7hijMDUjyLvK/ird8pQ0wHzggNWFH/aq/zehrVASJzt53Zo39
# NpPbqYDakx/0CIIkk6kohvXOM7iqvv2P+B6TZvAXcsKQ4JuGta53HzMHQqI9UcGi
# e/GQwRdemPWcTXyH7FDkDGooiItMmNTY5YwJkPpOkUdipfwd4dbLiPMoDMiS8dJY
# pi4w71U7j8fE7YvVfukjRRD3+vgKfEox307zOMuGEcyFj31sJ079fX0hd3m5Y+ZM
# khXHBDqrPXyjTW6hOu+jTBr7UQHZIr1VXzMdJ2RKAi9ihgU9ggMrWJqNUas=
# SIG # End signature block
