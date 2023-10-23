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
    have one: https://mondoo.com/docs/server/registration
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
    info "Set cnspec to run as a service automatically at startup and start the service"
    Set-Service -Name mondoo -Status Running -StartupType Automatic
    If(((Get-Service -Name Mondoo).Status -eq 'Running') -and ((Get-Service -Name Mondoo).StartType -eq 'Automatic') ) {
      success "* Mondoo Service is running and start type is automatic"
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
    info "Create and register the Mondoo update task"
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

  If ($version -ne  $installed_version.version) {
    # Check if Path exists
    $Path = $Path.trim('\')
    If (!(Test-Path $Path)) {New-Item -Path $Path -ItemType Directory}

    # download windows binary zip/msi
    $downloadlocation = "$Path\$Product.$filetype"
    info " * Downloading $Product from $releaseurl to $downloadlocation"
    download $releaseurl $downloadlocation

    If ($filetype -eq 'zip') {
      info ' * Extracting zip...'
      # remove older version if it is still there
      Remove-Item "$Path\$Product.exe" -Force -ErrorAction Ignore
      Add-Type -Assembly "System.IO.Compression.FileSystem"
      [IO.Compression.ZipFile]::ExtractToDirectory($downloadlocation,$Path)
      Remove-Item $downloadlocation -Force

      success " * $Product was downloaded successfully! You can find it in $Path\$Product.exe"

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

      If (![string]::IsNullOrEmpty($RegistrationToken)) {
        info " * Register $Product Client"
        $login_params = @("login", "-t", "$RegistrationToken", "--config", "C:\ProgramData\Mondoo\mondoo.yml")
        If (![string]::IsNullOrEmpty($Proxy)) {
           $login_params = $login_params + @("--api-proxy", "$Proxy")
        }
        $program = "$Path\cnspec.exe"
        & $program $login_params
      }

      If (@(0,3010) -contains $process.ExitCode) {
        success " * $Product was installed successfully!"
      } Else {
        fail (" * $Product installation failed with exit code: {0}" -f $process.ExitCode)
      }

      # Check if Service parameter is set and Parameter Product is set to mondoo
      If ($Service.ToLower() -eq 'enable' -and $Product.ToLower() -eq 'mondoo') {
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

      Remove-Item $downloadlocation -Force

    } Else {
      fail "${filetype} is not supported for download"
    }

    # Display final message
    info "
    Thank you for installing $Product!"

  } Else {
    # Display final message
    info "
    Latest $Product version alread installed!"
  }
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
# MIKVBAYJKoZIhvcNAQcCoIKU9TCClPECAQExDTALBglghkgBZQMEAgEweQYKKwYB
# BAGCNwIBBKBrMGkwNAYKKwYBBAGCNwIBHjAmAgMBAAAEEB/MO2BZSwhOtyTSxil+
# 81ECAQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQgnGCsgv5AO9Hkh7Nh
# 4XyuL71oxeP0xD6NcdaqtXaswligghpiMIIDWTCCAt+gAwIBAgIQD7inQLkVjQNR
# Q7xZ2fBAKTAKBggqhkjOPQQDAzBhMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGln
# aUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdE
# aWdpQ2VydCBHbG9iYWwgUm9vdCBHMzAeFw0yMTA0MjkwMDAwMDBaFw0zNjA0Mjgy
# MzU5NTlaMGQxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE8
# MDoGA1UEAxMzRGlnaUNlcnQgR2xvYmFsIEczIENvZGUgU2lnbmluZyBFQ0MgU0hB
# Mzg0IDIwMjEgQ0ExMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEu7SsJ6VIDaJTX48u
# gT4vU3a4CJSimqqKi5i1sfD8KhW7ubOlIi/9asC94lVoYGuXNMFmU3Ej/BrVyiAP
# AkCio0paRqORUyuV8gPpq6bTh3Yv52SfnjVR/MNjNXh25Ph3o4IBVzCCAVMwEgYD
# VR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUm1+wNrqdBq4ZJ73AoCLAi4s4d+0w
# HwYDVR0jBBgwFoAUs9tIpPmhxdiuNkHMEWNpYim8S8YwDgYDVR0PAQH/BAQDAgGG
# MBMGA1UdJQQMMAoGCCsGAQUFBwMDMHYGCCsGAQUFBwEBBGowaDAkBggrBgEFBQcw
# AYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEAGCCsGAQUFBzAChjRodHRwOi8v
# Y2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRHbG9iYWxSb290RzMuY3J0MEIG
# A1UdHwQ7MDkwN6A1oDOGMWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dEdsb2JhbFJvb3RHMy5jcmwwHAYDVR0gBBUwEzAHBgVngQwBAzAIBgZngQwBBAEw
# CgYIKoZIzj0EAwMDaAAwZQIweL1JlWVxAdBGV2hlDmip3DYIwe791I7bQGU/Df+T
# r8KuY4ajfsu0kVp47AcDZwd8AjEA558f8QdbrDTGOLy1pVDO5uo4fj55kOSkW6sC
# DegH/FamWords1Cy3fL6ZnSe0BZjMIID+DCCA36gAwIBAgIQDEIdg1QjUvYABwFA
# 28gf0DAKBggqhkjOPQQDAzBkMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNl
# cnQsIEluYy4xPDA6BgNVBAMTM0RpZ2lDZXJ0IEdsb2JhbCBHMyBDb2RlIFNpZ25p
# bmcgRUNDIFNIQTM4NCAyMDIxIENBMTAeFw0yMjA3MjYwMDAwMDBaFw0yMzA4MjMy
# MzU5NTlaMGExCzAJBgNVBAYTAlVTMRcwFQYDVQQIEw5Ob3J0aCBDYXJvbGluYTEN
# MAsGA1UEBxMEQ2FyeTEUMBIGA1UEChMLTW9uZG9vLCBJbmMxFDASBgNVBAMTC01v
# bmRvbywgSW5jMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEVAyibkorVuUZa4Grayxj
# 4Aq+uvkFn/TPZPl0at3L1L2SH1ODvFkaBn8fOQQzRYOd1YRMk13/1HvUyTpt3DMT
# 61XcyK3HxCllEdsifTBhx7u5FCrXp8Y+vI3m/uH+skCUo4IB9jCCAfIwHwYDVR0j
# BBgwFoAUm1+wNrqdBq4ZJ73AoCLAi4s4d+0wHQYDVR0OBBYEFM7LC1NpfmXLoOGH
# iYI6Yc4VChtYMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzCB
# qwYDVR0fBIGjMIGgME6gTKBKhkhodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGln
# aUNlcnRHbG9iYWxHM0NvZGVTaWduaW5nRUNDU0hBMzg0MjAyMUNBMS5jcmwwTqBM
# oEqGSGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEdsb2JhbEczQ29k
# ZVNpZ25pbmdFQ0NTSEEzODQyMDIxQ0ExLmNybDA+BgNVHSAENzA1MDMGBmeBDAEE
# ATApMCcGCCsGAQUFBwIBFhtodHRwOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgY4G
# CCsGAQUFBwEBBIGBMH8wJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0
# LmNvbTBXBggrBgEFBQcwAoZLaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0R2xvYmFsRzNDb2RlU2lnbmluZ0VDQ1NIQTM4NDIwMjFDQTEuY3J0MAwG
# A1UdEwEB/wQCMAAwCgYIKoZIzj0EAwMDaAAwZQIxAL/ZC7IYm6ttoID+pia3Oa9k
# 69+cNcRhC0/zeBbXokfpHF5x4PcTOl4sFVW6/kYNXgIwQG9RVKs0vzxFmMhXFtS2
# B0bkTaH8Dm2lv9boN+RJFwtt8p+m4fc+GVJFN0r/kW49MIIFjTCCBHWgAwIBAgIQ
# DpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMjIwODAx
# MDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMM
# RGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQD
# ExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3DQEBAQUAA4IC
# DwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZwuEppz1Yq3aa
# za57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4VpX6+n6lXFllV
# cq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAdYyktzuxeTsiT
# +CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3T6cw2Vbuyntd
# 463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjUN6QuBX2I9YI+
# EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNdaSaTC5qmgZ92k
# J7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtmmnTK3kse5w5j
# rubU75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyVw4/3IbKyEbe7
# f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3AeEPlAwhHbJU
# KSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYiCd98THU/Y+wh
# X8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmpsh3lGwIDAQAB
# o4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7NfjgtJxXWRM3y5n
# P+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDgYDVR0P
# AQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUGA1UdHwQ+MDww
# OqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3DQEBDAUAA4IB
# AQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+IcaaVQi7aSId229
# GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096wwepqLsl7Uz9FD
# RJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcDx4eo0kxAGTVG
# amlUsLihVo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsgjTVgHAIDyyCw
# rFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37YOtnwtoeW/VvR
# XKwYw02fc7cBqZ9Xql4o4rmUMIIGrjCCBJagAwIBAgIQBzY3tyRUfNhHrP0oZipe
# WzANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNl
# cnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdp
# Q2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjIwMzIzMDAwMDAwWhcNMzcwMzIyMjM1
# OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5
# BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0
# YW1waW5nIENBMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAxoY1Bkmz
# wT1ySVFVxyUDxPKRN6mXUaHW0oPRnkyibaCwzIP5WvYRoUQVQl+kiPNo+n3znIkL
# f50fng8zH1ATCyZzlm34V6gCff1DtITaEfFzsbPuK4CEiiIY3+vaPcQXf6sZKz5C
# 3GeO6lE98NZW1OcoLevTsbV15x8GZY2UKdPZ7Gnf2ZCHRgB720RBidx8ald68Dd5
# n12sy+iEZLRS8nZH92GDGd1ftFQLIWhuNyG7QKxfst5Kfc71ORJn7w6lY2zkpsUd
# zTYNXNXmG6jBZHRAp8ByxbpOH7G1WE15/tePc5OsLDnipUjW8LAxE6lXKZYnLvWH
# po9OdhVVJnCYJn+gGkcgQ+NDY4B7dW4nJZCYOjgRs/b2nuY7W+yB3iIU2YIqx5K/
# oN7jPqJz+ucfWmyU8lKVEStYdEAoq3NDzt9KoRxrOMUp88qqlnNCaJ+2RrOdOqPV
# A+C/8KI8ykLcGEh/FDTP0kyr75s9/g64ZCr6dSgkQe1CvwWcZklSUPRR8zZJTYsg
# 0ixXNXkrqPNFYLwjjVj33GHek/45wPmyMKVM1+mYSlg+0wOI/rOP015LdhJRk8mM
# DDtbiiKowSYI+RQQEgN9XyO7ZONj4KbhPvbCdLI/Hgl27KtdRnXiYKNYCQEoAA6E
# VO7O6V3IXjASvUaetdN2udIOa5kM0jO0zbECAwEAAaOCAV0wggFZMBIGA1UdEwEB
# /wQIMAYBAf8CAQAwHQYDVR0OBBYEFLoW2W1NhS9zKXaaL3WMaiCPnshvMB8GA1Ud
# IwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9PMA4GA1UdDwEB/wQEAwIBhjATBgNV
# HSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0
# dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2Vy
# dHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcnQwQwYDVR0f
# BDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcB
# MA0GCSqGSIb3DQEBCwUAA4ICAQB9WY7Ak7ZvmKlEIgF+ZtbYIULhsBguEE0TzzBT
# zr8Y+8dQXeJLKftwig2qKWn8acHPHQfpPmDI2AvlXFvXbYf6hCAlNDFnzbYSlm/E
# UExiHQwIgqgWvalWzxVzjQEiJc6VaT9Hd/tydBTX/6tPiix6q4XNQ1/tYLaqT5Fm
# niye4Iqs5f2MvGQmh2ySvZ180HAKfO+ovHVPulr3qRCyXen/KFSJ8NWKcXZl2szw
# cqMj+sAngkSumScbqyQeJsG33irr9p6xeZmBo1aGqwpFyd/EjaDnmPv7pp1yr8TH
# wcFqcdnGE4AJxLafzYeHJLtPo0m5d2aR8XKc6UsCUqc3fpNTrDsdCEkPlM05et3/
# JWOZJyw9P2un8WbDQc1PtkCbISFA0LcTJM3cHXg65J6t5TRxktcma+Q4c6umAU+9
# Pzt4rUyt+8SVe+0KXzM5h0F4ejjpnOHdI/0dKNPH+ejxmF/7K9h+8kaddSweJywm
# 228Vex4Ziza4k9Tm8heZWcpw8De/mADfIBZPJ/tgZxahZrrdVcA6KYawmKAr7ZVB
# tzrVFZgxtGIJDwq9gdkT/r+k0fNX2bwE+oLeMt8EifAAzV3C+dAjfwAL5HYCJtnw
# ZXZCpimHCUcr5n8apIUP/JiW9lVUKx+A+sDyDivl1vupL0QVSucTDh3bNzgaoSv2
# 7dZ8/DCCBsIwggSqoAMCAQICEAVEr/OUnQg5pr/bP1/lYRYwDQYJKoZIhvcNAQEL
# BQAwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYD
# VQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFt
# cGluZyBDQTAeFw0yMzA3MTQwMDAwMDBaFw0zNDEwMTMyMzU5NTlaMEgxCzAJBgNV
# BAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjEgMB4GA1UEAxMXRGlnaUNl
# cnQgVGltZXN0YW1wIDIwMjMwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
# AQCjU0WHHYOOW6w+VLMj4M+f1+XS512hDgncL0ijl3o7Kpxn3GIVWMGpkxGnzaqy
# at0QKYoeYmNp01icNXG/OpfrlFCPHCDqx5o7L5Zm42nnaf5bw9YrIBzBl5S0pVCB
# 8s/LB6YwaMqDQtr8fwkklKSCGtpqutg7yl3eGRiF+0XqDWFsnf5xXsQGmjzwxS55
# DxtmUuPI1j5f2kPThPXQx/ZILV5FdZZ1/t0QoRuDwbjmUpW1R9d4KTlr4HhZl+NE
# K0rVlc7vCBfqgmRN/yPjyobutKQhZHDr1eWg2mOzLukF7qr2JPUdvJscsrdf3/Du
# dn0xmWVHVZ1KJC+sK5e+n+T9e3M+Mu5SNPvUu+vUoCw0m+PebmQZBzcBkQ8ctVHN
# qkxmg4hoYru8QRt4GW3k2Q/gWEH72LEs4VGvtK0VBhTqYggT02kefGRNnQ/fztFe
# jKqrUBXJs8q818Q7aESjpTtC/XN97t0K/3k0EH6mXApYTAA+hWl1x4Nk1nXNjxJ2
# VqUk+tfEayG66B80mC866msBsPf7Kobse1I4qZgJoXGybHGvPrhvltXhEBP+YUcK
# jP7wtsfVx95sJPC/QoLKoHE9nJKTBLRpcCcNT7e1NtHJXwikcKPsCvERLmTgyyIr
# yvEoEyFJUX4GZtM7vvrrkTjYUQfKlLfiUKHzOtOKg8tAewIDAQABo4IBizCCAYcw
# DgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYB
# BQUHAwgwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMB8GA1UdIwQY
# MBaAFLoW2W1NhS9zKXaaL3WMaiCPnshvMB0GA1UdDgQWBBSltu8T5+/N0GSh1Vap
# ZTGj3tXjSTBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsMy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0Eu
# Y3JsMIGQBggrBgEFBQcBAQSBgzCBgDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3Au
# ZGlnaWNlcnQuY29tMFgGCCsGAQUFBzAChkxodHRwOi8vY2FjZXJ0cy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5n
# Q0EuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCBGtbeoKm1mBe8cI1PijxonNgl/8ss
# 5M3qXSKS7IwiAqm4z4Co2efjxe0mgopxLxjdTrbebNfhYJwr7e09SI64a7p8Xb3C
# YTdoSXej65CqEtcnhfOOHpLawkA4n13IoC4leCWdKgV6hCmYtld5j9smViuw86e9
# NwzYmHZPVrlSwradOKmB521BXIxp0bkrxMZ7z5z6eOKTGnaiaXXTUOREEr4gDZ6p
# RND45Ul3CFohxbTPmJUaVLq5vMFpGbrPFvKDNzRusEEm3d5al08zjdSNd311RaGl
# WCZqA0Xe2VC1UIyvVr1MxeFGxSjTredDAHDezJieGYkD6tSRN+9NUvPJYCHEVkft
# 2hFLjDLDiOZY4rbbPvlfsELWj+MXkdGqwFXjhr+sJyxB0JozSqg21Llyln6XeThI
# X8rC3D0y33XWNmdaifj2p8flTzU8AL2+nCpseQHc2kTmOt44OwdeOVj0fHMxVaCA
# EcsUDH6uvP6k63llqmjWIso765qCNVcoFstp8jKastLYOrixRoZruhf9xHdsFWyu
# q69zOuhJRrfVf8y2OMDY7Bz1tqG4QyzfTkx9HmhwwHcK1ALgXGC7KP845VJa1qwX
# IiNO9OzTF/tQa/8Hdx9xl0RBybhG02wyfFgvZ0dl5Rtztpn5aywGRu9BHvDwX+Db
# 2a2QgESvgBBBijGCefowgnn2AgEBMHgwZDELMAkGA1UEBhMCVVMxFzAVBgNVBAoT
# DkRpZ2lDZXJ0LCBJbmMuMTwwOgYDVQQDEzNEaWdpQ2VydCBHbG9iYWwgRzMgQ29k
# ZSBTaWduaW5nIEVDQyBTSEEzODQgMjAyMSBDQTECEAxCHYNUI1L2AAcBQNvIH9Aw
# DQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkq
# hkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGC
# NwIBFTAvBgkqhkiG9w0BCQQxIgQgaFKnBa0C2cLoSs5c2DTpogQghQbKhv8yoqlp
# xNaOW3kwCwYHKoZIzj0CAQUABGYwZAIwSnfbbGSQkcsUkayhiZKZBBU1IU68mScK
# 3Huw0Y7OCljo5aOluo1ScmExOqs/gO+iAjBsFSpzJOxl+4iPXdZObyezVcZD4aAm
# 9Kr7ZAn0XTfdxFvzq6yrzPJ4iuSDZQQ8PiShgnhqMIIDHAYJKoZIhvcNAQkGMYID
# DTCCAwkCAQEwdzBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIElu
# Yy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYg
# VGltZVN0YW1waW5nIENBAhAFRK/zlJ0IOaa/2z9f5WEWMA0GCWCGSAFlAwQCAQUA
# oGkwGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjMw
# ODIzMDk1ODA0WjAvBgkqhkiG9w0BCQQxIgQglG+cZq/+6C3623HaOY+JWchVOY1c
# 3ejjJ7ttAzVe+3EwDQYJKoZIhvcNAQEBBQAEggIAAYKirDiRrDjxB5u8SPWBfQy7
# 2MoJWJO3nj9L+y1qQPoCRRwbj5MjSJhwP8t46g3/z/ElPYHqNGUwEGn2HezUzPzD
# yT+QnykmxEGolKzemRuJgEe5wrM7jfce+arQxD0y5HpGkKwxCzYrqZoVMS77V+sf
# BS1NUVvgxzsS44hS0ecZHfcP/9aIB5t4Xyk1qDaW7U6J0I5X5tSahe352UNGBA/S
# 0uehLRVvgPuBEGyDE5V2Eg6IXykWczjiFgzCFzz8FtYHtWmw6wdqbT0YtZJC9m6M
# Yek1eh9bdN5lS1uXAwijAR/YmJUn6prJeoK5QEL13Dd3A9P3ZjDpCUoovn7kAsz9
# sLDXHUyAhbTNdkIDg03OG3SPi5eH9YdBCldV9to3/XwfNqwEVwdU8TvFqEM9lQ/Y
# 7HTM+oXDsU10d0XfdcgBbeRe8Q7H5+l2ZHD4GjF5cwRQM8lTRcOzPUB2lgqgadDn
# zDQYC1LcAn68VWEHgRBuZJyNGTEd3QRydpWkFoIZXWGhQZV1oayUuj63rx+B+yaz
# QTQ9ysfJz1/KcDsG0TDOsy/GuEx9QKkOlWHQKqv7lAczCmKgq9lBdQ+6brzmIluZ
# +j2HxKkajCSw6znzEJ7LNqvzK5k7KgXPswlM77Fg3d0R71t0NEgesdao+k90WVDE
# agbHGH8MJpVK/3HCQXowgnVGBgorBgEEAYI3AgQBMYJ1NjCCJw4GCSqGSIb3DQEH
# AqCCJv8wgib7AgEBMQ8wDQYJYIZIAWUDBAIBBQAweQYKKwYBBAGCNwIBBKBrMGkw
# NAYKKwYBBAGCNwIBHjAmAgMBAAAEEB/MO2BZSwhOtyTSxil+81ECAQACAQACAQAC
# AQACAQAwMTANBglghkgBZQMEAgEFAAQgl4MLoAjYjOtzacWhd00jw9exuVw7yDdV
# EhhqP6kJ38KggiCaMIIFjTCCBHWgAwIBAgIQDpsYjvnQLefv21DiCEAYWjANBgkq
# hkiG9w0BAQwFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5j
# MRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBB
# c3N1cmVkIElEIFJvb3QgQ0EwHhcNMjIwODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5
# WjBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQL
# ExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJv
# b3QgRzQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC/5pBzaN675F1K
# PDAiMGkz7MKnJS7JIT3yithZwuEppz1Yq3aaza57G4QNxDAf8xukOBbrVsaXbR2r
# snnyyhHS5F/WBTxSD1Ifxp4VpX6+n6lXFllVcq9ok3DCsrp1mWpzMpTREEQQLt+C
# 8weE5nQ7bXHiLQwb7iDVySAdYyktzuxeTsiT+CFhmzTrBcZe7FsavOvJz82sNEBf
# sXpm7nfISKhmV1efVFiODCu3T6cw2Vbuyntd463JT17lNecxy9qTXtyOj4DatpGY
# QJB5w3jHtrHEtWoYOAMQjdjUN6QuBX2I9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8
# rhsDdV14Ztk6MUSaM0C/CNdaSaTC5qmgZ92kJ7yhTzm1EVgX9yRcRo9k98FpiHaY
# dj1ZXUJ2h4mXaXpI8OCiEhtmmnTK3kse5w5jrubU75KSOp493ADkRSWJtppEGSt+
# wJS00mFt6zPZxd9LBADMfRyVw4/3IbKyEbe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw
# ++hkpjPRiQfhvbfmQ6QYuKZ3AeEPlAwhHbJUKSWJbOUOUlFHdL4mrLZBdd56rF+N
# P8m800ERElvlEFDrMcXKchYiCd98THU/Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7F
# wI+isX4KJpn15GkvmB0t9dmpsh3lGwIDAQABo4IBOjCCATYwDwYDVR0TAQH/BAUw
# AwEB/zAdBgNVHQ4EFgQU7NfjgtJxXWRM3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAU
# Reuir/SSy4IxLVGLp6chnfNtyA8wDgYDVR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEB
# BG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsG
# AQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3J0MEUGA1UdHwQ+MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAow
# CDAGBgRVHSAAMA0GCSqGSIb3DQEBDAUAA4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/
# Vwe9mqyhhyzshV6pGrsi+IcaaVQi7aSId229GhT0E0p6Ly23OO/0/4C5+KH38nLe
# JLxSA8hO0Cre+i1Wz/n096wwepqLsl7Uz9FDRJtDIeuWcqFItJnLnU+nBgMTdydE
# 1Od/6Fmo8L8vC6bp8jQ87PcDx4eo0kxAGTVGamlUsLihVo7spNU96LHc/RzY9Hda
# XFSMb++hUD38dglohJ9vytsgjTVgHAIDyyCwrFigDkBjxZgiwbJZ9VVrzyerbHbO
# byMt9H5xaiNrIv8SuFQtJ37YOtnwtoeW/VvRXKwYw02fc7cBqZ9Xql4o4rmUMIIG
# rjCCBJagAwIBAgIQBzY3tyRUfNhHrP0oZipeWzANBgkqhkiG9w0BAQsFADBiMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQw
# HhcNMjIwMzIzMDAwMDAwWhcNMzcwMzIyMjM1OTU5WjBjMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0
# ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEAxoY1BkmzwT1ySVFVxyUDxPKRN6mXUaHW0oPR
# nkyibaCwzIP5WvYRoUQVQl+kiPNo+n3znIkLf50fng8zH1ATCyZzlm34V6gCff1D
# tITaEfFzsbPuK4CEiiIY3+vaPcQXf6sZKz5C3GeO6lE98NZW1OcoLevTsbV15x8G
# ZY2UKdPZ7Gnf2ZCHRgB720RBidx8ald68Dd5n12sy+iEZLRS8nZH92GDGd1ftFQL
# IWhuNyG7QKxfst5Kfc71ORJn7w6lY2zkpsUdzTYNXNXmG6jBZHRAp8ByxbpOH7G1
# WE15/tePc5OsLDnipUjW8LAxE6lXKZYnLvWHpo9OdhVVJnCYJn+gGkcgQ+NDY4B7
# dW4nJZCYOjgRs/b2nuY7W+yB3iIU2YIqx5K/oN7jPqJz+ucfWmyU8lKVEStYdEAo
# q3NDzt9KoRxrOMUp88qqlnNCaJ+2RrOdOqPVA+C/8KI8ykLcGEh/FDTP0kyr75s9
# /g64ZCr6dSgkQe1CvwWcZklSUPRR8zZJTYsg0ixXNXkrqPNFYLwjjVj33GHek/45
# wPmyMKVM1+mYSlg+0wOI/rOP015LdhJRk8mMDDtbiiKowSYI+RQQEgN9XyO7ZONj
# 4KbhPvbCdLI/Hgl27KtdRnXiYKNYCQEoAA6EVO7O6V3IXjASvUaetdN2udIOa5kM
# 0jO0zbECAwEAAaOCAV0wggFZMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYE
# FLoW2W1NhS9zKXaaL3WMaiCPnshvMB8GA1UdIwQYMBaAFOzX44LScV1kTN8uZz/n
# upiuHA9PMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDCDB3Bggr
# BgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNv
# bTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lD
# ZXJ0VHJ1c3RlZFJvb3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2Ny
# bDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0g
# BBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQB9
# WY7Ak7ZvmKlEIgF+ZtbYIULhsBguEE0TzzBTzr8Y+8dQXeJLKftwig2qKWn8acHP
# HQfpPmDI2AvlXFvXbYf6hCAlNDFnzbYSlm/EUExiHQwIgqgWvalWzxVzjQEiJc6V
# aT9Hd/tydBTX/6tPiix6q4XNQ1/tYLaqT5Fmniye4Iqs5f2MvGQmh2ySvZ180HAK
# fO+ovHVPulr3qRCyXen/KFSJ8NWKcXZl2szwcqMj+sAngkSumScbqyQeJsG33irr
# 9p6xeZmBo1aGqwpFyd/EjaDnmPv7pp1yr8THwcFqcdnGE4AJxLafzYeHJLtPo0m5
# d2aR8XKc6UsCUqc3fpNTrDsdCEkPlM05et3/JWOZJyw9P2un8WbDQc1PtkCbISFA
# 0LcTJM3cHXg65J6t5TRxktcma+Q4c6umAU+9Pzt4rUyt+8SVe+0KXzM5h0F4ejjp
# nOHdI/0dKNPH+ejxmF/7K9h+8kaddSweJywm228Vex4Ziza4k9Tm8heZWcpw8De/
# mADfIBZPJ/tgZxahZrrdVcA6KYawmKAr7ZVBtzrVFZgxtGIJDwq9gdkT/r+k0fNX
# 2bwE+oLeMt8EifAAzV3C+dAjfwAL5HYCJtnwZXZCpimHCUcr5n8apIUP/JiW9lVU
# Kx+A+sDyDivl1vupL0QVSucTDh3bNzgaoSv27dZ8/DCCBrAwggSYoAMCAQICEAit
# QLJg0pxMn17Nqb2TrtkwDQYJKoZIhvcNAQEMBQAwYjELMAkGA1UEBhMCVVMxFTAT
# BgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEh
# MB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290IEc0MB4XDTIxMDQyOTAwMDAw
# MFoXDTM2MDQyODIzNTk1OVowaTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lD
# ZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IENvZGUgU2ln
# bmluZyBSU0E0MDk2IFNIQTM4NCAyMDIxIENBMTCCAiIwDQYJKoZIhvcNAQEBBQAD
# ggIPADCCAgoCggIBANW0L0LQKK14t13VOVkbsYhC9TOM6z2Bl3DFu8SFJjCfpI5o
# 2Fz16zQkB+FLT9N4Q/QX1x7a+dLVZxpSTw6hV/yImcGRzIEDPk1wJGSzjeIIfTR9
# TIBXEmtDmpnyxTsf8u/LR1oTpkyzASAl8xDTi7L7CPCK4J0JwGWn+piASTWHPVEZ
# 6JAheEUuoZ8s4RjCGszF7pNJcEIyj/vG6hzzZWiRok1MghFIUmjeEL0UV13oGBNl
# xX+yT4UsSKRWhDXW+S6cqgAV0Tf+GgaUwnzI6hsy5srC9KejAw50pa85tqtgEuPo
# 1rn3MeHcreQYoNjBI0dHs6EPbqOrbZgGgxu3amct0r1EGpIQgY+wOwnXx5syWsL/
# amBUi0nBk+3htFzgb+sm+YzVsvk4EObqzpH1vtP7b5NhNFy8k0UogzYqZihfsHPO
# iyYlBrKD1Fz2FRlM7WLgXjPy6OjsCqewAyuRsjZ5vvetCB51pmXMu+NIUPN3kRr+
# 21CiRshhWJj1fAIWPIMorTmG7NS3DVPQ+EfmdTCN7DCTdhSmW0tddGFNPxKRdt6/
# WMtyEClB8NXFbSZ2aBFBE1ia3CYrAfSJTVnbeM+BSj5AR1/JgVBzhRAjIVlgimRU
# wcwhGug4GXxmHM14OEUwmU//Y09Mu6oNCFNBfFg9R7P6tuyMMgkCzGw8DFYRAgMB
# AAGjggFZMIIBVTASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBRoN+Drtjv4
# XxGG+/5hewiIZfROQjAfBgNVHSMEGDAWgBTs1+OC0nFdZEzfLmc/57qYrhwPTzAO
# BgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYIKwYBBQUHAQEE
# azBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQQYIKwYB
# BQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0
# ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2lj
# ZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3JsMBwGA1UdIAQVMBMwBwYF
# Z4EMAQMwCAYGZ4EMAQQBMA0GCSqGSIb3DQEBDAUAA4ICAQA6I0Q9jQh27o+8OpnT
# VuACGqX4SDTzLLbmdGb3lHKxAMqvbDAnExKekESfS/2eo3wm1Te8Ol1IbZXVP0n0
# J7sWgUVQ/Zy9toXgdn43ccsi91qqkM/1k2rj6yDR1VB5iJqKisG2vaFIGH7c2IAa
# ERkYzWGZgVb2yeN258TkG19D+D6U/3Y5PZ7Umc9K3SjrXyahlVhI1Rr+1yc//ZDR
# dobdHLBgXPMNqO7giaG9OeE4Ttpuuzad++UhU1rDyulq8aI+20O4M8hPOBSSmfXd
# zlRt2V0CFB9AM3wD4pWywiF1c1LLRtjENByipUuNzW92NyyFPxrOJukYvpAHsEN/
# lYgggnDwzMrv/Sk1XB+JOFX3N4qLCaHLC+kxGv8uGVw5ceG+nKcKBtYmZ7eS5k5f
# 3nqsSc8upHSSrds8pJyGH+PBVhsrI/+PteqIe3Br5qC6/To/RabE6BaRUotBwEiE
# S5ZNq0RA443wFSjO7fEYVgcqLxDEDAhkPDOPriiMPMuPiAsNvzv0zh57ju+168u3
# 8HcT5ucoP6wSrqUvImxB+YJcFWbMbA7KxYbD9iYzDAdLoNMHAmpqQDBISzSoUSC7
# rRuFCOJZDW3KBVAr6kocnqX9oKcfBnTn8tZSkP2vhUgh+Vc7tJwD7YZF9LRhbr9o
# 4iZghurIr6n+lB3nYxs6hlZ4TjCCBsIwggSqoAMCAQICEAVEr/OUnQg5pr/bP1/l
# YRYwDQYJKoZIhvcNAQELBQAwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lD
# ZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYg
# U0hBMjU2IFRpbWVTdGFtcGluZyBDQTAeFw0yMzA3MTQwMDAwMDBaFw0zNDEwMTMy
# MzU5NTlaMEgxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjEg
# MB4GA1UEAxMXRGlnaUNlcnQgVGltZXN0YW1wIDIwMjMwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCjU0WHHYOOW6w+VLMj4M+f1+XS512hDgncL0ijl3o7
# Kpxn3GIVWMGpkxGnzaqyat0QKYoeYmNp01icNXG/OpfrlFCPHCDqx5o7L5Zm42nn
# af5bw9YrIBzBl5S0pVCB8s/LB6YwaMqDQtr8fwkklKSCGtpqutg7yl3eGRiF+0Xq
# DWFsnf5xXsQGmjzwxS55DxtmUuPI1j5f2kPThPXQx/ZILV5FdZZ1/t0QoRuDwbjm
# UpW1R9d4KTlr4HhZl+NEK0rVlc7vCBfqgmRN/yPjyobutKQhZHDr1eWg2mOzLukF
# 7qr2JPUdvJscsrdf3/Dudn0xmWVHVZ1KJC+sK5e+n+T9e3M+Mu5SNPvUu+vUoCw0
# m+PebmQZBzcBkQ8ctVHNqkxmg4hoYru8QRt4GW3k2Q/gWEH72LEs4VGvtK0VBhTq
# YggT02kefGRNnQ/fztFejKqrUBXJs8q818Q7aESjpTtC/XN97t0K/3k0EH6mXApY
# TAA+hWl1x4Nk1nXNjxJ2VqUk+tfEayG66B80mC866msBsPf7Kobse1I4qZgJoXGy
# bHGvPrhvltXhEBP+YUcKjP7wtsfVx95sJPC/QoLKoHE9nJKTBLRpcCcNT7e1NtHJ
# XwikcKPsCvERLmTgyyIryvEoEyFJUX4GZtM7vvrrkTjYUQfKlLfiUKHzOtOKg8tA
# ewIDAQABo4IBizCCAYcwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwFgYD
# VR0lAQH/BAwwCgYIKwYBBQUHAwgwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZI
# AYb9bAcBMB8GA1UdIwQYMBaAFLoW2W1NhS9zKXaaL3WMaiCPnshvMB0GA1UdDgQW
# BBSltu8T5+/N0GSh1VapZTGj3tXjSTBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2
# VGltZVN0YW1waW5nQ0EuY3JsMIGQBggrBgEFBQcBAQSBgzCBgDAkBggrBgEFBQcw
# AYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFgGCCsGAQUFBzAChkxodHRwOi8v
# Y2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hB
# MjU2VGltZVN0YW1waW5nQ0EuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCBGtbeoKm1
# mBe8cI1PijxonNgl/8ss5M3qXSKS7IwiAqm4z4Co2efjxe0mgopxLxjdTrbebNfh
# YJwr7e09SI64a7p8Xb3CYTdoSXej65CqEtcnhfOOHpLawkA4n13IoC4leCWdKgV6
# hCmYtld5j9smViuw86e9NwzYmHZPVrlSwradOKmB521BXIxp0bkrxMZ7z5z6eOKT
# GnaiaXXTUOREEr4gDZ6pRND45Ul3CFohxbTPmJUaVLq5vMFpGbrPFvKDNzRusEEm
# 3d5al08zjdSNd311RaGlWCZqA0Xe2VC1UIyvVr1MxeFGxSjTredDAHDezJieGYkD
# 6tSRN+9NUvPJYCHEVkft2hFLjDLDiOZY4rbbPvlfsELWj+MXkdGqwFXjhr+sJyxB
# 0JozSqg21Llyln6XeThIX8rC3D0y33XWNmdaifj2p8flTzU8AL2+nCpseQHc2kTm
# Ot44OwdeOVj0fHMxVaCAEcsUDH6uvP6k63llqmjWIso765qCNVcoFstp8jKastLY
# OrixRoZruhf9xHdsFWyuq69zOuhJRrfVf8y2OMDY7Bz1tqG4QyzfTkx9HmhwwHcK
# 1ALgXGC7KP845VJa1qwXIiNO9OzTF/tQa/8Hdx9xl0RBybhG02wyfFgvZ0dl5Rtz
# tpn5aywGRu9BHvDwX+Db2a2QgESvgBBBijCCBtkwggTBoAMCAQICEAO9mAyby0zd
# GdDhV+Woa9UwDQYJKoZIhvcNAQELBQAwaTELMAkGA1UEBhMCVVMxFzAVBgNVBAoT
# DkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IENv
# ZGUgU2lnbmluZyBSU0E0MDk2IFNIQTM4NCAyMDIxIENBMTAeFw0yMzA4MjAwMDAw
# MDBaFw0yNDA4MTkyMzU5NTlaMGExCzAJBgNVBAYTAlVTMRcwFQYDVQQIEw5Ob3J0
# aCBDYXJvbGluYTENMAsGA1UEBxMEQ2FyeTEUMBIGA1UEChMLTW9uZG9vLCBJbmMx
# FDASBgNVBAMTC01vbmRvbywgSW5jMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIB
# igKCAYEAwk0Zem7HmvV8dIC7/30Eq4RrA+TGy+ZADNd7RyMEuA66Yd8520cDBSz8
# INztuHXKbx2MUq3IYxbVxfI1dS67J6Bh2hW4UZoB9DDi+7YCUmjKL1yXS8c+DViI
# 2Mz6ySvkqh7VcqPa47AJMxcX7p6F4Xi1XWMQtNhoB1OVetq2QZzRV65Pevhqjaw4
# x0HABFjB8hIP8U179vk4+tONZXX+ylPsvoNPptHyf3145jTVkc8Dwe2D2lhBA9+r
# 4y3xPpxuMXOeeilk5fP0RL0KgOUZU1CK4yoY654ulYfr5efFDnHvZuEuV/oJPN+x
# 7w3HbUt4EB4tWN1W6SSA8LP2pI36rJh2j/WLEdrJi9K8IEMzrvmi17/PRO5dK6sL
# g8jsQ7pehojRremdlTzPBzHUs9xDOyfte0NyZLlzQ0TrSPhpVHbtu6cq0uXt4D2q
# 17NRA5fJAwZ108DVzIPQpTEmF9Ge0HS9pgQWfk6ChbTPOUIvpspk3h6dCszH+Jd8
# dmRQARI5AgMBAAGjggIDMIIB/zAfBgNVHSMEGDAWgBRoN+Drtjv4XxGG+/5hewiI
# ZfROQjAdBgNVHQ4EFgQUtwLF3gv3f7ZHlrGO3kPKN51LD7gwDgYDVR0PAQH/BAQD
# AgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMIG1BgNVHR8Ega0wgaowU6BRoE+GTWh0
# dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWdu
# aW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEuY3JsMFOgUaBPhk1odHRwOi8vY3JsNC5k
# aWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRDb2RlU2lnbmluZ1JTQTQwOTZT
# SEEzODQyMDIxQ0ExLmNybDA+BgNVHSAENzA1MDMGBmeBDAEEATApMCcGCCsGAQUF
# BwIBFhtodHRwOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgZQGCCsGAQUFBwEBBIGH
# MIGEMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXAYIKwYB
# BQUHMAKGUGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0
# ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEuY3J0MAkGA1UdEwQC
# MAAwDQYJKoZIhvcNAQELBQADggIBAFmvrbYD6OLWwCp8B7hgbmmEXsFYJY2TcmsX
# pG95u2zF8CSw7afR3JpKdSrknRMhb/PKyHEjH9dW5DapkQ2EvmGmeW0ey0b7UtkR
# DVRK7Zdt7XtbonsGuqSuVGljGRO1vpBQZPVc1Jd1IhVEApxsZaBGXytp62nHn0Ug
# WNZv+kPc+JCzcwpdnZBzj73I9qUXGNboci7DFT22dQSk95EOkfoAXsDNBLfoxaWI
# q08W5jkl47w0fRlkrRiZMmaPlHbb0JdCddcRicekEgAvg7gnIGAJ7HN40hvFQ3vN
# gy2jVj2wrNCp4XdUtOqsaiycn5QNZ28YSNrCWMao5FWRqtL5uwqtSGOnpJFCoXo5
# JGkpVBFMRIEoQYOG/KYWeYOpAH5PwFVGS4Ts64qdzlmDrkTauhTjieOeGLYZ2OHp
# XUel17M0UUpoBY7gEHTBzc6uvDnmNfEr6qux1n/L31hykpkrfU2YzyRo7qMKONU5
# kiRwyA2C85MWnAYrF9jeoqYZHibKfZE0I/GadJPcGPzrPH5FWEdedhOxAemW9LoF
# BqnkeSKIKnrm0c2YdyioLlCHvC5AUqyeyOqUFonBGCJ4d+5MUg0VrBj3h19YTXgR
# rE4XnY3fEdlBBSGDAlySQU0J6hFgSuD6OQ4odIGVW4mmuaejgzlv0nreIgZdgdw4
# eD6D0xhOMYIFyjCCBcYCAQEwfTBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGln
# aUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgQ29kZSBT
# aWduaW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0ExAhADvZgMm8tM3RnQ4VflqGvV
# MA0GCWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkD
# MQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJ
# KoZIhvcNAQkEMSIEIFF2W5l3CrAM7HdmxtEIAAs29MCXeBoEDjm1fvjyQ3H9MA0G
# CSqGSIb3DQEBAQUABIIBgE3E8FzwrqzKiaOsQuylwJt7fpXwBuwrl/0xgjK2NhK+
# s4H2SU4paeYIUGuj6vECqA2/54Jh0Vj3GQUQZ2RGyLNn8tF5IvbN5MeR64tejaw1
# 7g4uR7pnku6DwyV0q4aqi3FRMR6wVqMETlOM2VbWQYxDp5JmSEA6JbNRw0Xs38y4
# bQOiSvj4LkIyMF77JMz3COvHFAwEeWh7yV0ug0YNf03wRSfUABUgx6wsROPFPvaG
# XCdVRaCFmESi00qgLrGKG4kaz41ql7fvKKZpzggC4SFylZaFqg7Xq+FYtOm7O5A+
# 6X6CpxEJ6A+jtOx3pgSH/eaUr4+Bn7pvKmxtxiOxiSiToTAdbqoU5bIjZb/kw+a5
# Eq8XHeG7+mmyr2pCB0Orojdc90m+pzrxs54UivT4zbtXFQ3Yo7+FQQEdBVPpRYe9
# AK/Krvm4ir6aAPqfE6oAYzPZdFLkgiM8XzmIo0K5MwODRB7Bf9Y1lKmMQyIVb+bM
# fDzJ2V/5AZiLWViXqwzGA6GCAyAwggMcBgkqhkiG9w0BCQYxggMNMIIDCQIBATB3
# MGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UE
# AxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBp
# bmcgQ0ECEAVEr/OUnQg5pr/bP1/lYRYwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG
# 9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMzEwMjEwNzUyMDVa
# MC8GCSqGSIb3DQEJBDEiBCB8CnwfEdmOWYWA6L+vnaHtTILLhWWbKZUsvvKvhYml
# zDANBgkqhkiG9w0BAQEFAASCAgAlHH3Xgzhxgdv2kSD4igII6pczJj4lSewNmM43
# JWQSFXyGhW1+PAQafr95/luTwTCdMUyRPIVMsGBUjittOhpibnORJXjv6xInGAmm
# gCNPUGJmO7/TCknCy1x/hX/utiTYSpdbuXpC/wLs8djnoYDafi0ldhBfCXGXHRjy
# DkW7zX+J53HWeKK/TeibfI/oN0r4lSMJICvG+7wAWmNcWWIoBP+kdgEMtgZGQel4
# gzaKdINI09MhVM6NNWjwwB3GPvfzXRwfgR43uIQ67vrstXRtRPItts009InTgTKQ
# FRXZiZFvn1XIIi0cwgbqwKjG71T/uBWv32Ha2eDBiBNWi3STiqkQJ95PUz7wnmC4
# dERGkt6dYuunhh2XfiwwdClPv3jYlIG6aiw6whX72rb3aq8k7s4si096ATeBBPxE
# 7H/7ARei2/2/Hctgy1s5S2kA19p/XCC73NbNulpdfIuLb1RvGsBL4QQeZQ8CeP6J
# O487GgZRqR8fvqytKlmS0MMka/+pvjoilj3xSLgBQEVirpx0d7SQgUJAZTXMBV98
# ssHHAfwwfQWlz3JWiJAzdlK8OVGFHVrP66HasvtN3qx5fHRpIim04kgki63qEz3i
# hRbvY0e/UQYKCbPHx7E85/JBHe4LFUrCXLpduSJQGK8CwUWwbSswxSZE856UNJVK
# D+KArTCCJw4GCSqGSIb3DQEHAqCCJv8wgib7AgEBMQ8wDQYJYIZIAWUDBAIBBQAw
# eQYKKwYBBAGCNwIBBKBrMGkwNAYKKwYBBAGCNwIBHjAmAgMBAAAEEB/MO2BZSwhO
# tyTSxil+81ECAQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQgl4MLoAjY
# jOtzacWhd00jw9exuVw7yDdVEhhqP6kJ38KggiCaMIIFjTCCBHWgAwIBAgIQDpsY
# jvnQLefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYDVQQGEwJVUzEVMBMG
# A1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQw
# IgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMjIwODAxMDAw
# MDAwWhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGln
# aUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhE
# aWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZwuEppz1Yq3aaza57
# G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4VpX6+n6lXFllVcq9o
# k3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAdYyktzuxeTsiT+CFh
# mzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3T6cw2Vbuyntd463J
# T17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjUN6QuBX2I9YI+EJFw
# q1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNdaSaTC5qmgZ92kJ7yh
# Tzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtmmnTK3kse5w5jrubU
# 75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyVw4/3IbKyEbe7f/LV
# jHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3AeEPlAwhHbJUKSWJ
# bOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYiCd98THU/Y+whX8Qg
# UWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmpsh3lGwIDAQABo4IB
# OjCCATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7NfjgtJxXWRM3y5nP+e6
# mK4cD08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDgYDVR0PAQH/
# BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29jc3Au
# ZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUGA1UdHwQ+MDwwOqA4
# oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJv
# b3RDQS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3DQEBDAUAA4IBAQBw
# oL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+IcaaVQi7aSId229GhT0
# E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096wwepqLsl7Uz9FDRJtD
# IeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcDx4eo0kxAGTVGamlU
# sLihVo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsgjTVgHAIDyyCwrFig
# DkBjxZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37YOtnwtoeW/VvRXKwY
# w02fc7cBqZ9Xql4o4rmUMIIGrjCCBJagAwIBAgIQBzY3tyRUfNhHrP0oZipeWzAN
# BgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQg
# SW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2Vy
# dCBUcnVzdGVkIFJvb3QgRzQwHhcNMjIwMzIzMDAwMDAwWhcNMzcwMzIyMjM1OTU5
# WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNV
# BAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1w
# aW5nIENBMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAxoY1BkmzwT1y
# SVFVxyUDxPKRN6mXUaHW0oPRnkyibaCwzIP5WvYRoUQVQl+kiPNo+n3znIkLf50f
# ng8zH1ATCyZzlm34V6gCff1DtITaEfFzsbPuK4CEiiIY3+vaPcQXf6sZKz5C3GeO
# 6lE98NZW1OcoLevTsbV15x8GZY2UKdPZ7Gnf2ZCHRgB720RBidx8ald68Dd5n12s
# y+iEZLRS8nZH92GDGd1ftFQLIWhuNyG7QKxfst5Kfc71ORJn7w6lY2zkpsUdzTYN
# XNXmG6jBZHRAp8ByxbpOH7G1WE15/tePc5OsLDnipUjW8LAxE6lXKZYnLvWHpo9O
# dhVVJnCYJn+gGkcgQ+NDY4B7dW4nJZCYOjgRs/b2nuY7W+yB3iIU2YIqx5K/oN7j
# PqJz+ucfWmyU8lKVEStYdEAoq3NDzt9KoRxrOMUp88qqlnNCaJ+2RrOdOqPVA+C/
# 8KI8ykLcGEh/FDTP0kyr75s9/g64ZCr6dSgkQe1CvwWcZklSUPRR8zZJTYsg0ixX
# NXkrqPNFYLwjjVj33GHek/45wPmyMKVM1+mYSlg+0wOI/rOP015LdhJRk8mMDDtb
# iiKowSYI+RQQEgN9XyO7ZONj4KbhPvbCdLI/Hgl27KtdRnXiYKNYCQEoAA6EVO7O
# 6V3IXjASvUaetdN2udIOa5kM0jO0zbECAwEAAaOCAV0wggFZMBIGA1UdEwEB/wQI
# MAYBAf8CAQAwHQYDVR0OBBYEFLoW2W1NhS9zKXaaL3WMaiCPnshvMB8GA1UdIwQY
# MBaAFOzX44LScV1kTN8uZz/nupiuHA9PMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUE
# DDAKBggrBgEFBQcDCDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcnQwQwYDVR0fBDww
# OjA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3Rl
# ZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMA0G
# CSqGSIb3DQEBCwUAA4ICAQB9WY7Ak7ZvmKlEIgF+ZtbYIULhsBguEE0TzzBTzr8Y
# +8dQXeJLKftwig2qKWn8acHPHQfpPmDI2AvlXFvXbYf6hCAlNDFnzbYSlm/EUExi
# HQwIgqgWvalWzxVzjQEiJc6VaT9Hd/tydBTX/6tPiix6q4XNQ1/tYLaqT5Fmniye
# 4Iqs5f2MvGQmh2ySvZ180HAKfO+ovHVPulr3qRCyXen/KFSJ8NWKcXZl2szwcqMj
# +sAngkSumScbqyQeJsG33irr9p6xeZmBo1aGqwpFyd/EjaDnmPv7pp1yr8THwcFq
# cdnGE4AJxLafzYeHJLtPo0m5d2aR8XKc6UsCUqc3fpNTrDsdCEkPlM05et3/JWOZ
# Jyw9P2un8WbDQc1PtkCbISFA0LcTJM3cHXg65J6t5TRxktcma+Q4c6umAU+9Pzt4
# rUyt+8SVe+0KXzM5h0F4ejjpnOHdI/0dKNPH+ejxmF/7K9h+8kaddSweJywm228V
# ex4Ziza4k9Tm8heZWcpw8De/mADfIBZPJ/tgZxahZrrdVcA6KYawmKAr7ZVBtzrV
# FZgxtGIJDwq9gdkT/r+k0fNX2bwE+oLeMt8EifAAzV3C+dAjfwAL5HYCJtnwZXZC
# pimHCUcr5n8apIUP/JiW9lVUKx+A+sDyDivl1vupL0QVSucTDh3bNzgaoSv27dZ8
# /DCCBrAwggSYoAMCAQICEAitQLJg0pxMn17Nqb2TrtkwDQYJKoZIhvcNAQEMBQAw
# YjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290
# IEc0MB4XDTIxMDQyOTAwMDAwMFoXDTM2MDQyODIzNTk1OVowaTELMAkGA1UEBhMC
# VVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBU
# cnVzdGVkIEc0IENvZGUgU2lnbmluZyBSU0E0MDk2IFNIQTM4NCAyMDIxIENBMTCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBANW0L0LQKK14t13VOVkbsYhC
# 9TOM6z2Bl3DFu8SFJjCfpI5o2Fz16zQkB+FLT9N4Q/QX1x7a+dLVZxpSTw6hV/yI
# mcGRzIEDPk1wJGSzjeIIfTR9TIBXEmtDmpnyxTsf8u/LR1oTpkyzASAl8xDTi7L7
# CPCK4J0JwGWn+piASTWHPVEZ6JAheEUuoZ8s4RjCGszF7pNJcEIyj/vG6hzzZWiR
# ok1MghFIUmjeEL0UV13oGBNlxX+yT4UsSKRWhDXW+S6cqgAV0Tf+GgaUwnzI6hsy
# 5srC9KejAw50pa85tqtgEuPo1rn3MeHcreQYoNjBI0dHs6EPbqOrbZgGgxu3amct
# 0r1EGpIQgY+wOwnXx5syWsL/amBUi0nBk+3htFzgb+sm+YzVsvk4EObqzpH1vtP7
# b5NhNFy8k0UogzYqZihfsHPOiyYlBrKD1Fz2FRlM7WLgXjPy6OjsCqewAyuRsjZ5
# vvetCB51pmXMu+NIUPN3kRr+21CiRshhWJj1fAIWPIMorTmG7NS3DVPQ+EfmdTCN
# 7DCTdhSmW0tddGFNPxKRdt6/WMtyEClB8NXFbSZ2aBFBE1ia3CYrAfSJTVnbeM+B
# Sj5AR1/JgVBzhRAjIVlgimRUwcwhGug4GXxmHM14OEUwmU//Y09Mu6oNCFNBfFg9
# R7P6tuyMMgkCzGw8DFYRAgMBAAGjggFZMIIBVTASBgNVHRMBAf8ECDAGAQH/AgEA
# MB0GA1UdDgQWBBRoN+Drtjv4XxGG+/5hewiIZfROQjAfBgNVHSMEGDAWgBTs1+OC
# 0nFdZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5k
# aWdpY2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDowOKA2oDSG
# Mmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQu
# Y3JsMBwGA1UdIAQVMBMwBwYFZ4EMAQMwCAYGZ4EMAQQBMA0GCSqGSIb3DQEBDAUA
# A4ICAQA6I0Q9jQh27o+8OpnTVuACGqX4SDTzLLbmdGb3lHKxAMqvbDAnExKekESf
# S/2eo3wm1Te8Ol1IbZXVP0n0J7sWgUVQ/Zy9toXgdn43ccsi91qqkM/1k2rj6yDR
# 1VB5iJqKisG2vaFIGH7c2IAaERkYzWGZgVb2yeN258TkG19D+D6U/3Y5PZ7Umc9K
# 3SjrXyahlVhI1Rr+1yc//ZDRdobdHLBgXPMNqO7giaG9OeE4Ttpuuzad++UhU1rD
# yulq8aI+20O4M8hPOBSSmfXdzlRt2V0CFB9AM3wD4pWywiF1c1LLRtjENByipUuN
# zW92NyyFPxrOJukYvpAHsEN/lYgggnDwzMrv/Sk1XB+JOFX3N4qLCaHLC+kxGv8u
# GVw5ceG+nKcKBtYmZ7eS5k5f3nqsSc8upHSSrds8pJyGH+PBVhsrI/+PteqIe3Br
# 5qC6/To/RabE6BaRUotBwEiES5ZNq0RA443wFSjO7fEYVgcqLxDEDAhkPDOPriiM
# PMuPiAsNvzv0zh57ju+168u38HcT5ucoP6wSrqUvImxB+YJcFWbMbA7KxYbD9iYz
# DAdLoNMHAmpqQDBISzSoUSC7rRuFCOJZDW3KBVAr6kocnqX9oKcfBnTn8tZSkP2v
# hUgh+Vc7tJwD7YZF9LRhbr9o4iZghurIr6n+lB3nYxs6hlZ4TjCCBsIwggSqoAMC
# AQICEAVEr/OUnQg5pr/bP1/lYRYwDQYJKoZIhvcNAQELBQAwYzELMAkGA1UEBhMC
# VVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBU
# cnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQTAeFw0yMzA3
# MTQwMDAwMDBaFw0zNDEwMTMyMzU5NTlaMEgxCzAJBgNVBAYTAlVTMRcwFQYDVQQK
# Ew5EaWdpQ2VydCwgSW5jLjEgMB4GA1UEAxMXRGlnaUNlcnQgVGltZXN0YW1wIDIw
# MjMwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCjU0WHHYOOW6w+VLMj
# 4M+f1+XS512hDgncL0ijl3o7Kpxn3GIVWMGpkxGnzaqyat0QKYoeYmNp01icNXG/
# OpfrlFCPHCDqx5o7L5Zm42nnaf5bw9YrIBzBl5S0pVCB8s/LB6YwaMqDQtr8fwkk
# lKSCGtpqutg7yl3eGRiF+0XqDWFsnf5xXsQGmjzwxS55DxtmUuPI1j5f2kPThPXQ
# x/ZILV5FdZZ1/t0QoRuDwbjmUpW1R9d4KTlr4HhZl+NEK0rVlc7vCBfqgmRN/yPj
# yobutKQhZHDr1eWg2mOzLukF7qr2JPUdvJscsrdf3/Dudn0xmWVHVZ1KJC+sK5e+
# n+T9e3M+Mu5SNPvUu+vUoCw0m+PebmQZBzcBkQ8ctVHNqkxmg4hoYru8QRt4GW3k
# 2Q/gWEH72LEs4VGvtK0VBhTqYggT02kefGRNnQ/fztFejKqrUBXJs8q818Q7aESj
# pTtC/XN97t0K/3k0EH6mXApYTAA+hWl1x4Nk1nXNjxJ2VqUk+tfEayG66B80mC86
# 6msBsPf7Kobse1I4qZgJoXGybHGvPrhvltXhEBP+YUcKjP7wtsfVx95sJPC/QoLK
# oHE9nJKTBLRpcCcNT7e1NtHJXwikcKPsCvERLmTgyyIryvEoEyFJUX4GZtM7vvrr
# kTjYUQfKlLfiUKHzOtOKg8tAewIDAQABo4IBizCCAYcwDgYDVR0PAQH/BAQDAgeA
# MAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwIAYDVR0gBBkw
# FzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMB8GA1UdIwQYMBaAFLoW2W1NhS9zKXaa
# L3WMaiCPnshvMB0GA1UdDgQWBBSltu8T5+/N0GSh1VapZTGj3tXjSTBaBgNVHR8E
# UzBRME+gTaBLhklodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVz
# dGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3JsMIGQBggrBgEFBQcB
# AQSBgzCBgDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFgG
# CCsGAQUFBzAChkxodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRU
# cnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3J0MA0GCSqGSIb3
# DQEBCwUAA4ICAQCBGtbeoKm1mBe8cI1PijxonNgl/8ss5M3qXSKS7IwiAqm4z4Co
# 2efjxe0mgopxLxjdTrbebNfhYJwr7e09SI64a7p8Xb3CYTdoSXej65CqEtcnhfOO
# HpLawkA4n13IoC4leCWdKgV6hCmYtld5j9smViuw86e9NwzYmHZPVrlSwradOKmB
# 521BXIxp0bkrxMZ7z5z6eOKTGnaiaXXTUOREEr4gDZ6pRND45Ul3CFohxbTPmJUa
# VLq5vMFpGbrPFvKDNzRusEEm3d5al08zjdSNd311RaGlWCZqA0Xe2VC1UIyvVr1M
# xeFGxSjTredDAHDezJieGYkD6tSRN+9NUvPJYCHEVkft2hFLjDLDiOZY4rbbPvlf
# sELWj+MXkdGqwFXjhr+sJyxB0JozSqg21Llyln6XeThIX8rC3D0y33XWNmdaifj2
# p8flTzU8AL2+nCpseQHc2kTmOt44OwdeOVj0fHMxVaCAEcsUDH6uvP6k63llqmjW
# Iso765qCNVcoFstp8jKastLYOrixRoZruhf9xHdsFWyuq69zOuhJRrfVf8y2OMDY
# 7Bz1tqG4QyzfTkx9HmhwwHcK1ALgXGC7KP845VJa1qwXIiNO9OzTF/tQa/8Hdx9x
# l0RBybhG02wyfFgvZ0dl5Rtztpn5aywGRu9BHvDwX+Db2a2QgESvgBBBijCCBtkw
# ggTBoAMCAQICEAO9mAyby0zdGdDhV+Woa9UwDQYJKoZIhvcNAQELBQAwaTELMAkG
# A1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdp
# Q2VydCBUcnVzdGVkIEc0IENvZGUgU2lnbmluZyBSU0E0MDk2IFNIQTM4NCAyMDIx
# IENBMTAeFw0yMzA4MjAwMDAwMDBaFw0yNDA4MTkyMzU5NTlaMGExCzAJBgNVBAYT
# AlVTMRcwFQYDVQQIEw5Ob3J0aCBDYXJvbGluYTENMAsGA1UEBxMEQ2FyeTEUMBIG
# A1UEChMLTW9uZG9vLCBJbmMxFDASBgNVBAMTC01vbmRvbywgSW5jMIIBojANBgkq
# hkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAwk0Zem7HmvV8dIC7/30Eq4RrA+TGy+ZA
# DNd7RyMEuA66Yd8520cDBSz8INztuHXKbx2MUq3IYxbVxfI1dS67J6Bh2hW4UZoB
# 9DDi+7YCUmjKL1yXS8c+DViI2Mz6ySvkqh7VcqPa47AJMxcX7p6F4Xi1XWMQtNho
# B1OVetq2QZzRV65Pevhqjaw4x0HABFjB8hIP8U179vk4+tONZXX+ylPsvoNPptHy
# f3145jTVkc8Dwe2D2lhBA9+r4y3xPpxuMXOeeilk5fP0RL0KgOUZU1CK4yoY654u
# lYfr5efFDnHvZuEuV/oJPN+x7w3HbUt4EB4tWN1W6SSA8LP2pI36rJh2j/WLEdrJ
# i9K8IEMzrvmi17/PRO5dK6sLg8jsQ7pehojRremdlTzPBzHUs9xDOyfte0NyZLlz
# Q0TrSPhpVHbtu6cq0uXt4D2q17NRA5fJAwZ108DVzIPQpTEmF9Ge0HS9pgQWfk6C
# hbTPOUIvpspk3h6dCszH+Jd8dmRQARI5AgMBAAGjggIDMIIB/zAfBgNVHSMEGDAW
# gBRoN+Drtjv4XxGG+/5hewiIZfROQjAdBgNVHQ4EFgQUtwLF3gv3f7ZHlrGO3kPK
# N51LD7gwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMIG1BgNV
# HR8Ega0wgaowU6BRoE+GTWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dFRydXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEuY3JsMFOg
# UaBPhk1odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRD
# b2RlU2lnbmluZ1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNybDA+BgNVHSAENzA1MDMG
# BmeBDAEEATApMCcGCCsGAQUFBwIBFhtodHRwOi8vd3d3LmRpZ2ljZXJ0LmNvbS9D
# UFMwgZQGCCsGAQUFBwEBBIGHMIGEMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5k
# aWdpY2VydC5jb20wXAYIKwYBBQUHMAKGUGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIw
# MjFDQTEuY3J0MAkGA1UdEwQCMAAwDQYJKoZIhvcNAQELBQADggIBAFmvrbYD6OLW
# wCp8B7hgbmmEXsFYJY2TcmsXpG95u2zF8CSw7afR3JpKdSrknRMhb/PKyHEjH9dW
# 5DapkQ2EvmGmeW0ey0b7UtkRDVRK7Zdt7XtbonsGuqSuVGljGRO1vpBQZPVc1Jd1
# IhVEApxsZaBGXytp62nHn0UgWNZv+kPc+JCzcwpdnZBzj73I9qUXGNboci7DFT22
# dQSk95EOkfoAXsDNBLfoxaWIq08W5jkl47w0fRlkrRiZMmaPlHbb0JdCddcRicek
# EgAvg7gnIGAJ7HN40hvFQ3vNgy2jVj2wrNCp4XdUtOqsaiycn5QNZ28YSNrCWMao
# 5FWRqtL5uwqtSGOnpJFCoXo5JGkpVBFMRIEoQYOG/KYWeYOpAH5PwFVGS4Ts64qd
# zlmDrkTauhTjieOeGLYZ2OHpXUel17M0UUpoBY7gEHTBzc6uvDnmNfEr6qux1n/L
# 31hykpkrfU2YzyRo7qMKONU5kiRwyA2C85MWnAYrF9jeoqYZHibKfZE0I/GadJPc
# GPzrPH5FWEdedhOxAemW9LoFBqnkeSKIKnrm0c2YdyioLlCHvC5AUqyeyOqUFonB
# GCJ4d+5MUg0VrBj3h19YTXgRrE4XnY3fEdlBBSGDAlySQU0J6hFgSuD6OQ4odIGV
# W4mmuaejgzlv0nreIgZdgdw4eD6D0xhOMYIFyjCCBcYCAQEwfTBpMQswCQYDVQQG
# EwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0
# IFRydXN0ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0Ex
# AhADvZgMm8tM3RnQ4VflqGvVMA0GCWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIB
# DDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFF2W5l3CrAM7HdmxtEIAAs2
# 9MCXeBoEDjm1fvjyQ3H9MA0GCSqGSIb3DQEBAQUABIIBgE3E8FzwrqzKiaOsQuyl
# wJt7fpXwBuwrl/0xgjK2NhK+s4H2SU4paeYIUGuj6vECqA2/54Jh0Vj3GQUQZ2RG
# yLNn8tF5IvbN5MeR64tejaw17g4uR7pnku6DwyV0q4aqi3FRMR6wVqMETlOM2VbW
# QYxDp5JmSEA6JbNRw0Xs38y4bQOiSvj4LkIyMF77JMz3COvHFAwEeWh7yV0ug0YN
# f03wRSfUABUgx6wsROPFPvaGXCdVRaCFmESi00qgLrGKG4kaz41ql7fvKKZpzggC
# 4SFylZaFqg7Xq+FYtOm7O5A+6X6CpxEJ6A+jtOx3pgSH/eaUr4+Bn7pvKmxtxiOx
# iSiToTAdbqoU5bIjZb/kw+a5Eq8XHeG7+mmyr2pCB0Orojdc90m+pzrxs54UivT4
# zbtXFQ3Yo7+FQQEdBVPpRYe9AK/Krvm4ir6aAPqfE6oAYzPZdFLkgiM8XzmIo0K5
# MwODRB7Bf9Y1lKmMQyIVb+bMfDzJ2V/5AZiLWViXqwzGA6GCAyAwggMcBgkqhkiG
# 9w0BCQYxggMNMIIDCQIBATB3MGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdp
# Q2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2
# IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0ECEAVEr/OUnQg5pr/bP1/lYRYwDQYJYIZI
# AWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJ
# BTEPFw0yMzEwMjEwODEyMDdaMC8GCSqGSIb3DQEJBDEiBCB8CnwfEdmOWYWA6L+v
# naHtTILLhWWbKZUsvvKvhYmlzDANBgkqhkiG9w0BAQEFAASCAgBvpSHj6s3TG1HQ
# uz2eSclBkPsIg5hwCKxOMrt0TNN5Fc8ZlN8G9ctg2lcKTDOCOPT52I+oLF2UmVzJ
# WyG8898CH5/HX+0QRs28yWg/8KGP9aUYCcIftXrIXYiIz64FPXRnqw7JgpXVBXMi
# KAy1yKnTv8FaMjyDuLidH6JI85GQVpFHD2eiMtbmeStefJMLMCI82gRf5XLqjlRx
# WLKMjPRSxdO3ZzngdpBD6MUFdj3rbzLEK45n92ape7Z3afUGQVITWf/XUQ4R7Mkd
# INrJsdx9mfog5B7IOPPcQyeyI/ivxE5L2Y0QHP+TMwS69iK7H6vZ9uYUMDMPQmOB
# lY+FHjIprM8MfQPmauxMDxGzrwANgXIqxETt4I3dNnLy39nHGyvqT2vrKCn5zBXz
# 1lXh0HtD8cHAnPJps7/aK23KVvDklhrJ/jI4j2r7CujxXGd8bXxVSIvkimPlzlqt
# MpFfYHt64FAf27cu94Wf/YAn6KDsK+zUb2UvDUXr/vxImSqmumxP0ZskR7ZSoMhL
# 0iJq0A0ZV2/9rHSuHHMpuutCgBKw9fjjcQ7CWTiBwKlGxIlsKAj2IoDnSxYgUuE8
# PrdR1hNfvLIrhOomVQd79Y3Q4ue1p0pXsb+dskbrJXg4G08lB7L5j2IKOv1x70Uu
# G9enXqbLFf+1QwvNiQ0ADuHVt7m2JTCCJw4GCSqGSIb3DQEHAqCCJv8wgib7AgEB
# MQ8wDQYJYIZIAWUDBAIBBQAweQYKKwYBBAGCNwIBBKBrMGkwNAYKKwYBBAGCNwIB
# HjAmAgMBAAAEEB/MO2BZSwhOtyTSxil+81ECAQACAQACAQACAQACAQAwMTANBglg
# hkgBZQMEAgEFAAQgl4MLoAjYjOtzacWhd00jw9exuVw7yDdVEhhqP6kJ38KggiCa
# MIIFjTCCBHWgAwIBAgIQDpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBl
# MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
# d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJv
# b3QgQ0EwHhcNMjIwODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQG
# EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNl
# cnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0G
# CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7J
# IT3yithZwuEppz1Yq3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxS
# D1Ifxp4VpX6+n6lXFllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb
# 7iDVySAdYyktzuxeTsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1ef
# VFiODCu3T6cw2Vbuyntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoY
# OAMQjdjUN6QuBX2I9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSa
# M0C/CNdaSaTC5qmgZ92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI
# 8OCiEhtmmnTK3kse5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9L
# BADMfRyVw4/3IbKyEbe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfm
# Q6QYuKZ3AeEPlAwhHbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDr
# McXKchYiCd98THU/Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15Gkv
# mB0t9dmpsh3lGwIDAQABo4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4E
# FgQU7NfjgtJxXWRM3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGL
# p6chnfNtyA8wDgYDVR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEF
# BQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRw
# Oi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0Eu
# Y3J0MEUGA1UdHwQ+MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0G
# CSqGSIb3DQEBDAUAA4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6p
# Grsi+IcaaVQi7aSId229GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1W
# z/n096wwepqLsl7Uz9FDRJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp
# 8jQ87PcDx4eo0kxAGTVGamlUsLihVo7spNU96LHc/RzY9HdaXFSMb++hUD38dglo
# hJ9vytsgjTVgHAIDyyCwrFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8S
# uFQtJ37YOtnwtoeW/VvRXKwYw02fc7cBqZ9Xql4o4rmUMIIGrjCCBJagAwIBAgIQ
# BzY3tyRUfNhHrP0oZipeWzANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjIwMzIzMDAw
# MDAwWhcNMzcwMzIyMjM1OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGln
# aUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5
# NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMIICIjANBgkqhkiG9w0BAQEFAAOCAg8A
# MIICCgKCAgEAxoY1BkmzwT1ySVFVxyUDxPKRN6mXUaHW0oPRnkyibaCwzIP5WvYR
# oUQVQl+kiPNo+n3znIkLf50fng8zH1ATCyZzlm34V6gCff1DtITaEfFzsbPuK4CE
# iiIY3+vaPcQXf6sZKz5C3GeO6lE98NZW1OcoLevTsbV15x8GZY2UKdPZ7Gnf2ZCH
# RgB720RBidx8ald68Dd5n12sy+iEZLRS8nZH92GDGd1ftFQLIWhuNyG7QKxfst5K
# fc71ORJn7w6lY2zkpsUdzTYNXNXmG6jBZHRAp8ByxbpOH7G1WE15/tePc5OsLDni
# pUjW8LAxE6lXKZYnLvWHpo9OdhVVJnCYJn+gGkcgQ+NDY4B7dW4nJZCYOjgRs/b2
# nuY7W+yB3iIU2YIqx5K/oN7jPqJz+ucfWmyU8lKVEStYdEAoq3NDzt9KoRxrOMUp
# 88qqlnNCaJ+2RrOdOqPVA+C/8KI8ykLcGEh/FDTP0kyr75s9/g64ZCr6dSgkQe1C
# vwWcZklSUPRR8zZJTYsg0ixXNXkrqPNFYLwjjVj33GHek/45wPmyMKVM1+mYSlg+
# 0wOI/rOP015LdhJRk8mMDDtbiiKowSYI+RQQEgN9XyO7ZONj4KbhPvbCdLI/Hgl2
# 7KtdRnXiYKNYCQEoAA6EVO7O6V3IXjASvUaetdN2udIOa5kM0jO0zbECAwEAAaOC
# AV0wggFZMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFLoW2W1NhS9zKXaa
# L3WMaiCPnshvMB8GA1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9PMA4GA1Ud
# DwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcBAQRrMGkw
# JAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcw
# AoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJv
# b3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAIBgZngQwB
# BAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQB9WY7Ak7ZvmKlEIgF+
# ZtbYIULhsBguEE0TzzBTzr8Y+8dQXeJLKftwig2qKWn8acHPHQfpPmDI2AvlXFvX
# bYf6hCAlNDFnzbYSlm/EUExiHQwIgqgWvalWzxVzjQEiJc6VaT9Hd/tydBTX/6tP
# iix6q4XNQ1/tYLaqT5Fmniye4Iqs5f2MvGQmh2ySvZ180HAKfO+ovHVPulr3qRCy
# Xen/KFSJ8NWKcXZl2szwcqMj+sAngkSumScbqyQeJsG33irr9p6xeZmBo1aGqwpF
# yd/EjaDnmPv7pp1yr8THwcFqcdnGE4AJxLafzYeHJLtPo0m5d2aR8XKc6UsCUqc3
# fpNTrDsdCEkPlM05et3/JWOZJyw9P2un8WbDQc1PtkCbISFA0LcTJM3cHXg65J6t
# 5TRxktcma+Q4c6umAU+9Pzt4rUyt+8SVe+0KXzM5h0F4ejjpnOHdI/0dKNPH+ejx
# mF/7K9h+8kaddSweJywm228Vex4Ziza4k9Tm8heZWcpw8De/mADfIBZPJ/tgZxah
# ZrrdVcA6KYawmKAr7ZVBtzrVFZgxtGIJDwq9gdkT/r+k0fNX2bwE+oLeMt8EifAA
# zV3C+dAjfwAL5HYCJtnwZXZCpimHCUcr5n8apIUP/JiW9lVUKx+A+sDyDivl1vup
# L0QVSucTDh3bNzgaoSv27dZ8/DCCBrAwggSYoAMCAQICEAitQLJg0pxMn17Nqb2T
# rtkwDQYJKoZIhvcNAQEMBQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGln
# aUNlcnQgVHJ1c3RlZCBSb290IEc0MB4XDTIxMDQyOTAwMDAwMFoXDTM2MDQyODIz
# NTk1OVowaTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEw
# PwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IENvZGUgU2lnbmluZyBSU0E0MDk2
# IFNIQTM4NCAyMDIxIENBMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIB
# ANW0L0LQKK14t13VOVkbsYhC9TOM6z2Bl3DFu8SFJjCfpI5o2Fz16zQkB+FLT9N4
# Q/QX1x7a+dLVZxpSTw6hV/yImcGRzIEDPk1wJGSzjeIIfTR9TIBXEmtDmpnyxTsf
# 8u/LR1oTpkyzASAl8xDTi7L7CPCK4J0JwGWn+piASTWHPVEZ6JAheEUuoZ8s4RjC
# GszF7pNJcEIyj/vG6hzzZWiRok1MghFIUmjeEL0UV13oGBNlxX+yT4UsSKRWhDXW
# +S6cqgAV0Tf+GgaUwnzI6hsy5srC9KejAw50pa85tqtgEuPo1rn3MeHcreQYoNjB
# I0dHs6EPbqOrbZgGgxu3amct0r1EGpIQgY+wOwnXx5syWsL/amBUi0nBk+3htFzg
# b+sm+YzVsvk4EObqzpH1vtP7b5NhNFy8k0UogzYqZihfsHPOiyYlBrKD1Fz2FRlM
# 7WLgXjPy6OjsCqewAyuRsjZ5vvetCB51pmXMu+NIUPN3kRr+21CiRshhWJj1fAIW
# PIMorTmG7NS3DVPQ+EfmdTCN7DCTdhSmW0tddGFNPxKRdt6/WMtyEClB8NXFbSZ2
# aBFBE1ia3CYrAfSJTVnbeM+BSj5AR1/JgVBzhRAjIVlgimRUwcwhGug4GXxmHM14
# OEUwmU//Y09Mu6oNCFNBfFg9R7P6tuyMMgkCzGw8DFYRAgMBAAGjggFZMIIBVTAS
# BgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBRoN+Drtjv4XxGG+/5hewiIZfRO
# QjAfBgNVHSMEGDAWgBTs1+OC0nFdZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMC
# AYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUF
# BzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6
# Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0
# MEMGA1UdHwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdp
# Q2VydFRydXN0ZWRSb290RzQuY3JsMBwGA1UdIAQVMBMwBwYFZ4EMAQMwCAYGZ4EM
# AQQBMA0GCSqGSIb3DQEBDAUAA4ICAQA6I0Q9jQh27o+8OpnTVuACGqX4SDTzLLbm
# dGb3lHKxAMqvbDAnExKekESfS/2eo3wm1Te8Ol1IbZXVP0n0J7sWgUVQ/Zy9toXg
# dn43ccsi91qqkM/1k2rj6yDR1VB5iJqKisG2vaFIGH7c2IAaERkYzWGZgVb2yeN2
# 58TkG19D+D6U/3Y5PZ7Umc9K3SjrXyahlVhI1Rr+1yc//ZDRdobdHLBgXPMNqO7g
# iaG9OeE4Ttpuuzad++UhU1rDyulq8aI+20O4M8hPOBSSmfXdzlRt2V0CFB9AM3wD
# 4pWywiF1c1LLRtjENByipUuNzW92NyyFPxrOJukYvpAHsEN/lYgggnDwzMrv/Sk1
# XB+JOFX3N4qLCaHLC+kxGv8uGVw5ceG+nKcKBtYmZ7eS5k5f3nqsSc8upHSSrds8
# pJyGH+PBVhsrI/+PteqIe3Br5qC6/To/RabE6BaRUotBwEiES5ZNq0RA443wFSjO
# 7fEYVgcqLxDEDAhkPDOPriiMPMuPiAsNvzv0zh57ju+168u38HcT5ucoP6wSrqUv
# ImxB+YJcFWbMbA7KxYbD9iYzDAdLoNMHAmpqQDBISzSoUSC7rRuFCOJZDW3KBVAr
# 6kocnqX9oKcfBnTn8tZSkP2vhUgh+Vc7tJwD7YZF9LRhbr9o4iZghurIr6n+lB3n
# Yxs6hlZ4TjCCBsIwggSqoAMCAQICEAVEr/OUnQg5pr/bP1/lYRYwDQYJKoZIhvcN
# AQELBQAwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTsw
# OQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVT
# dGFtcGluZyBDQTAeFw0yMzA3MTQwMDAwMDBaFw0zNDEwMTMyMzU5NTlaMEgxCzAJ
# BgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjEgMB4GA1UEAxMXRGln
# aUNlcnQgVGltZXN0YW1wIDIwMjMwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQCjU0WHHYOOW6w+VLMj4M+f1+XS512hDgncL0ijl3o7Kpxn3GIVWMGpkxGn
# zaqyat0QKYoeYmNp01icNXG/OpfrlFCPHCDqx5o7L5Zm42nnaf5bw9YrIBzBl5S0
# pVCB8s/LB6YwaMqDQtr8fwkklKSCGtpqutg7yl3eGRiF+0XqDWFsnf5xXsQGmjzw
# xS55DxtmUuPI1j5f2kPThPXQx/ZILV5FdZZ1/t0QoRuDwbjmUpW1R9d4KTlr4HhZ
# l+NEK0rVlc7vCBfqgmRN/yPjyobutKQhZHDr1eWg2mOzLukF7qr2JPUdvJscsrdf
# 3/Dudn0xmWVHVZ1KJC+sK5e+n+T9e3M+Mu5SNPvUu+vUoCw0m+PebmQZBzcBkQ8c
# tVHNqkxmg4hoYru8QRt4GW3k2Q/gWEH72LEs4VGvtK0VBhTqYggT02kefGRNnQ/f
# ztFejKqrUBXJs8q818Q7aESjpTtC/XN97t0K/3k0EH6mXApYTAA+hWl1x4Nk1nXN
# jxJ2VqUk+tfEayG66B80mC866msBsPf7Kobse1I4qZgJoXGybHGvPrhvltXhEBP+
# YUcKjP7wtsfVx95sJPC/QoLKoHE9nJKTBLRpcCcNT7e1NtHJXwikcKPsCvERLmTg
# yyIryvEoEyFJUX4GZtM7vvrrkTjYUQfKlLfiUKHzOtOKg8tAewIDAQABo4IBizCC
# AYcwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYI
# KwYBBQUHAwgwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMB8GA1Ud
# IwQYMBaAFLoW2W1NhS9zKXaaL3WMaiCPnshvMB0GA1UdDgQWBBSltu8T5+/N0GSh
# 1VapZTGj3tXjSTBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5n
# Q0EuY3JsMIGQBggrBgEFBQcBAQSBgzCBgDAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMFgGCCsGAQUFBzAChkxodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1w
# aW5nQ0EuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCBGtbeoKm1mBe8cI1PijxonNgl
# /8ss5M3qXSKS7IwiAqm4z4Co2efjxe0mgopxLxjdTrbebNfhYJwr7e09SI64a7p8
# Xb3CYTdoSXej65CqEtcnhfOOHpLawkA4n13IoC4leCWdKgV6hCmYtld5j9smViuw
# 86e9NwzYmHZPVrlSwradOKmB521BXIxp0bkrxMZ7z5z6eOKTGnaiaXXTUOREEr4g
# DZ6pRND45Ul3CFohxbTPmJUaVLq5vMFpGbrPFvKDNzRusEEm3d5al08zjdSNd311
# RaGlWCZqA0Xe2VC1UIyvVr1MxeFGxSjTredDAHDezJieGYkD6tSRN+9NUvPJYCHE
# Vkft2hFLjDLDiOZY4rbbPvlfsELWj+MXkdGqwFXjhr+sJyxB0JozSqg21Llyln6X
# eThIX8rC3D0y33XWNmdaifj2p8flTzU8AL2+nCpseQHc2kTmOt44OwdeOVj0fHMx
# VaCAEcsUDH6uvP6k63llqmjWIso765qCNVcoFstp8jKastLYOrixRoZruhf9xHds
# FWyuq69zOuhJRrfVf8y2OMDY7Bz1tqG4QyzfTkx9HmhwwHcK1ALgXGC7KP845VJa
# 1qwXIiNO9OzTF/tQa/8Hdx9xl0RBybhG02wyfFgvZ0dl5Rtztpn5aywGRu9BHvDw
# X+Db2a2QgESvgBBBijCCBtkwggTBoAMCAQICEAO9mAyby0zdGdDhV+Woa9UwDQYJ
# KoZIhvcNAQELBQAwaTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IENvZGUgU2lnbmluZyBS
# U0E0MDk2IFNIQTM4NCAyMDIxIENBMTAeFw0yMzA4MjAwMDAwMDBaFw0yNDA4MTky
# MzU5NTlaMGExCzAJBgNVBAYTAlVTMRcwFQYDVQQIEw5Ob3J0aCBDYXJvbGluYTEN
# MAsGA1UEBxMEQ2FyeTEUMBIGA1UEChMLTW9uZG9vLCBJbmMxFDASBgNVBAMTC01v
# bmRvbywgSW5jMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAwk0Zem7H
# mvV8dIC7/30Eq4RrA+TGy+ZADNd7RyMEuA66Yd8520cDBSz8INztuHXKbx2MUq3I
# YxbVxfI1dS67J6Bh2hW4UZoB9DDi+7YCUmjKL1yXS8c+DViI2Mz6ySvkqh7VcqPa
# 47AJMxcX7p6F4Xi1XWMQtNhoB1OVetq2QZzRV65Pevhqjaw4x0HABFjB8hIP8U17
# 9vk4+tONZXX+ylPsvoNPptHyf3145jTVkc8Dwe2D2lhBA9+r4y3xPpxuMXOeeilk
# 5fP0RL0KgOUZU1CK4yoY654ulYfr5efFDnHvZuEuV/oJPN+x7w3HbUt4EB4tWN1W
# 6SSA8LP2pI36rJh2j/WLEdrJi9K8IEMzrvmi17/PRO5dK6sLg8jsQ7pehojRremd
# lTzPBzHUs9xDOyfte0NyZLlzQ0TrSPhpVHbtu6cq0uXt4D2q17NRA5fJAwZ108DV
# zIPQpTEmF9Ge0HS9pgQWfk6ChbTPOUIvpspk3h6dCszH+Jd8dmRQARI5AgMBAAGj
# ggIDMIIB/zAfBgNVHSMEGDAWgBRoN+Drtjv4XxGG+/5hewiIZfROQjAdBgNVHQ4E
# FgQUtwLF3gv3f7ZHlrGO3kPKN51LD7gwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMIG1BgNVHR8Ega0wgaowU6BRoE+GTWh0dHA6Ly9jcmwzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNI
# QTM4NDIwMjFDQTEuY3JsMFOgUaBPhk1odHRwOi8vY3JsNC5kaWdpY2VydC5jb20v
# RGlnaUNlcnRUcnVzdGVkRzRDb2RlU2lnbmluZ1JTQTQwOTZTSEEzODQyMDIxQ0Ex
# LmNybDA+BgNVHSAENzA1MDMGBmeBDAEEATApMCcGCCsGAQUFBwIBFhtodHRwOi8v
# d3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgZQGCCsGAQUFBwEBBIGHMIGEMCQGCCsGAQUF
# BzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wXAYIKwYBBQUHMAKGUGh0dHA6
# Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWdu
# aW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEuY3J0MAkGA1UdEwQCMAAwDQYJKoZIhvcN
# AQELBQADggIBAFmvrbYD6OLWwCp8B7hgbmmEXsFYJY2TcmsXpG95u2zF8CSw7afR
# 3JpKdSrknRMhb/PKyHEjH9dW5DapkQ2EvmGmeW0ey0b7UtkRDVRK7Zdt7XtbonsG
# uqSuVGljGRO1vpBQZPVc1Jd1IhVEApxsZaBGXytp62nHn0UgWNZv+kPc+JCzcwpd
# nZBzj73I9qUXGNboci7DFT22dQSk95EOkfoAXsDNBLfoxaWIq08W5jkl47w0fRlk
# rRiZMmaPlHbb0JdCddcRicekEgAvg7gnIGAJ7HN40hvFQ3vNgy2jVj2wrNCp4XdU
# tOqsaiycn5QNZ28YSNrCWMao5FWRqtL5uwqtSGOnpJFCoXo5JGkpVBFMRIEoQYOG
# /KYWeYOpAH5PwFVGS4Ts64qdzlmDrkTauhTjieOeGLYZ2OHpXUel17M0UUpoBY7g
# EHTBzc6uvDnmNfEr6qux1n/L31hykpkrfU2YzyRo7qMKONU5kiRwyA2C85MWnAYr
# F9jeoqYZHibKfZE0I/GadJPcGPzrPH5FWEdedhOxAemW9LoFBqnkeSKIKnrm0c2Y
# dyioLlCHvC5AUqyeyOqUFonBGCJ4d+5MUg0VrBj3h19YTXgRrE4XnY3fEdlBBSGD
# AlySQU0J6hFgSuD6OQ4odIGVW4mmuaejgzlv0nreIgZdgdw4eD6D0xhOMYIFyjCC
# BcYCAQEwfTBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4x
# QTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgQ29kZSBTaWduaW5nIFJTQTQw
# OTYgU0hBMzg0IDIwMjEgQ0ExAhADvZgMm8tM3RnQ4VflqGvVMA0GCWCGSAFlAwQC
# AQUAoHwwEAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcC
# AQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIE
# IFF2W5l3CrAM7HdmxtEIAAs29MCXeBoEDjm1fvjyQ3H9MA0GCSqGSIb3DQEBAQUA
# BIIBgE3E8FzwrqzKiaOsQuylwJt7fpXwBuwrl/0xgjK2NhK+s4H2SU4paeYIUGuj
# 6vECqA2/54Jh0Vj3GQUQZ2RGyLNn8tF5IvbN5MeR64tejaw17g4uR7pnku6DwyV0
# q4aqi3FRMR6wVqMETlOM2VbWQYxDp5JmSEA6JbNRw0Xs38y4bQOiSvj4LkIyMF77
# JMz3COvHFAwEeWh7yV0ug0YNf03wRSfUABUgx6wsROPFPvaGXCdVRaCFmESi00qg
# LrGKG4kaz41ql7fvKKZpzggC4SFylZaFqg7Xq+FYtOm7O5A+6X6CpxEJ6A+jtOx3
# pgSH/eaUr4+Bn7pvKmxtxiOxiSiToTAdbqoU5bIjZb/kw+a5Eq8XHeG7+mmyr2pC
# B0Orojdc90m+pzrxs54UivT4zbtXFQ3Yo7+FQQEdBVPpRYe9AK/Krvm4ir6aAPqf
# E6oAYzPZdFLkgiM8XzmIo0K5MwODRB7Bf9Y1lKmMQyIVb+bMfDzJ2V/5AZiLWViX
# qwzGA6GCAyAwggMcBgkqhkiG9w0BCQYxggMNMIIDCQIBATB3MGMxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQg
# VHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0ECEAVEr/OU
# nQg5pr/bP1/lYRYwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMzEwMjMyMjQ1MzZaMC8GCSqGSIb3DQEJ
# BDEiBCB8CnwfEdmOWYWA6L+vnaHtTILLhWWbKZUsvvKvhYmlzDANBgkqhkiG9w0B
# AQEFAASCAgCUWImHoVPpY8EveLFNUtbmNeHpMw61cZiCYiBHA3GhxCVuKBCf/QYC
# TPK5jBKVvFBdkqSRwcx0nx6AX8DQz4I6KFAgpjLEUCTz7Mnik2Q/tebDWl6+DEsc
# iMEchQ7OyisHB9KA068/YC7tIvD/r6ZHJlBM+4OyN2ZcBZVRNBpSHM600QUFJcVJ
# mbW2CIM2wlzrBY396B44CqXmL9Dw43lS/53qbYjjEFQDXR6INm9Z1wZVfaEFIOj4
# vQrdVHSK1si5CPDic/a8wgeya02mUyBW6TAk0a2oEti6vz1KkO8J6oVW4k4wa3bg
# Dj3YmO8TdCo5/1FFi/EgecL+e9Zd/5EhvnkOyPvL3t2DJObxjG+wqI450rXpET0G
# 0nhqlDNlZwj+OfBglXqtLKo+m6o2SPD0AfB/Dv0YFL2sWUCwXo6gH+4ZNLZHGqoz
# 8cejQsgfBMgP/51wdH7PjnnvAWix2RTlsRIXZddKRtku42cFE9K2miS1xJLnw1bA
# jdKAIEhNFPlgRfoH0Axv7SQxxgTI+M3dXRma3JqGfuz3DqMExE9UmV019vl2Luc7
# kAVJUG2TGrmhV+f7uZb/Tw37hi+D7nuCcmu0Wb4HpE/LXlhWfxkWm5+fK3TfogH3
# 20pf1rGbUBkEyBZTVlJBUWVR98r/JwGao5I5JR0isBOi5nl8+n3N/Q==
# SIG # End signature block
