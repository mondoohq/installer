#Requires -Version 5
#Requires -RunAsAdministrator
<#
    .SYNOPSIS
    This PowerShell script installs the latest Mondoo agent on windows. Usage:
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://install.mondoo.com/ps1')); Install-Mondoo;
    
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
    Import-Module ./install.ps1; Install-Mondoo -Proxy 1.1.1.1:3128
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

  function fail($msg) { Write-Error -ErrorAction Stop -Message $msg }
  function info($msg) {  Write-Host $msg -f white }
  function success($msg) { Write-Host $msg -f darkgreen }
  function purple($msg) { Write-Host $msg -f magenta }

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

  function determine_latest($product, $filetype) {
    $url = "https://releases.mondoo.com/${product}/latest.json"
    If([string]::IsNullOrEmpty($filetype)) {
      $filetype = [regex]::escape('msi')
    }
    $wc = New-Object Net.Webclient
    If(![string]::IsNullOrEmpty($Proxy)) {
      $wc.proxy = New-Object System.Net.WebProxy($Proxy)
    }
    $wc.Headers.Add('User-Agent', (Get-UserAgent))
    $latest = $wc.DownloadString($url) | ConvertFrom-Json 
    $entry = $latest.files | where { $_.platform -eq "windows" -and $_.filename -match "${filetype}$" -and $_.filename -NotMatch "enterprise" -and $_.filename -match "amd64" }
    $entry.filename
  }

  function determine_version($product, $filetype, $version) {
    $arch = 'amd64'
    $res = "https://releases.mondoo.com/${product}/${version}/${product}_${version}_windows_${arch}.${filetype}"
    $res
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
    info "Set Mondoo Client to run as a service automatically at startup and start the service"
    Set-Service -Name mondoo -Status Running -StartupType Automatic
    If(![string]::IsNullOrEmpty($Proxy)) {
      # set register key for Mondoo Service to use proxy for internet connection
      reg add hklm\SYSTEM\CurrentControlSet\Services\Mondoo /v Environment /t REG_MULTI_SZ /d "https_proxy=$Proxy" /f
    }
    if(((Get-Service -Name Mondoo).Status -eq 'Running') -and ((Get-Service -Name Mondoo).StartType -eq 'Automatic') ) {
      success "* Mondoo Service is running and start type is automatic"
    } Else {
      fail "Mondoo service configuration failed"
    }
  }

  Function NewScheduledTaskFolder($taskpath)
  {
      $ErrorActionPreference = "stop"
      $scheduleObject = New-Object -ComObject schedule.service
      $scheduleObject.connect()
      $rootFolder = $scheduleObject.GetFolder("\")
      Try { $null = $scheduleObject.GetFolder($taskpath) }
      Catch { $null = $rootFolder.CreateFolder($taskpath) }
      Finally { $ErrorActionPreference = "continue" }
  }

  Function CreateAndRegisterMondooUpdaterTask($taskname, $taskpath)
  {
      info "Create and register the Mondoo update task"
      NewScheduledTaskFolder $taskpath

      $taskArgument = '-NoProfile -WindowStyle Hidden -ExecutionPolicy RemoteSigned -Command &{ [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $wc = New-Object Net.Webclient; '

      If(![string]::IsNullOrEmpty($Proxy)) {
        # Add proxy config to scheduling task
        $taskArgument = $taskArgument += '$wc.proxy = New-Object System.Net.WebProxy(\"' + $Proxy + '\"); '
      }

      $taskArgument = $taskArgument += 'iex ($wc.DownloadString(\"https://install.mondoo.com/ps1\")); Install-Mondoo '

      # Set product name in scheduling task
      $taskArgument = $taskArgument += '-Product ' + $Product + ' '

      # Set Path in scheduling task
      $taskArgument = $taskArgument += '-Path \"' + $Path + '\" '

      # Service enabled
      If($Service.ToLower() -eq 'enable' -and $Product.ToLower() -eq 'mondoo') {
        $taskArgument = $taskArgument += '-Service enable '
      }

      # Proxy enabled
      If (![string]::IsNullOrEmpty($Proxy)) {
        $taskArgument = $taskArgument += '-Proxy ' + $Proxy + ' '
      }

      # Recreate scheduling task
      If($UpdateTask.ToLower() -eq 'enable') {
        $taskArgument = $taskArgument += '-UpdateTask enable -Time ' + $Time + ' -Interval ' + $Interval +' '
      }

      $taskArgument = $taskArgument += ';}'

      $action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $taskArgument
      $trigger =  @(
        $(New-ScheduledTaskTrigger -Daily -DaysInterval $Interval -At $Time)
      )
      $principal = New-ScheduledTaskPrincipal -GroupId "NT AUTHORITY\SYSTEM" -RunLevel Highest
      Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskname -Description "$Product Updater Task" -TaskPath $taskpath -Principal $principal

      If(Get-ScheduledTask -TaskName $taskname -EA 0)
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
                  
  info "Welcome to the Mondoo Binary Download Script. It downloads the Mondoo binary for
  Windows into $ENV:UserProfile\mondoo and adds the path to the user's environment PATH. If 
  you are experiencing any issues, please do not hesitate to reach out: 

    * Mondoo Community GitHub Discussions https://github.com/orgs/mondoohq/discussions

  This script source is available at: https://github.com/mondoohq/client
  "

  # Any subsequent commands which fails will stop the execution of the shell script
  $previous_erroractionpreference = $erroractionpreference
  $erroractionpreference = 'stop'

  # verify powershell pre-conditions
  if(($PSVersionTable.PSVersion.Major) -lt 5) {
    fail "
  The install script requires PowerShell 5 or later.
  To upgrade PowerShell visit https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell
  "
  }

  # show notification to change execution policy:
  if((Get-ExecutionPolicy) -gt 'RemoteSigned' -or (Get-ExecutionPolicy) -eq 'ByPass') {
    fail "
  PowerShell requires an execution policy of 'RemoteSigned'. Please change the policy by running:
  Set-ExecutionPolicy RemoteSigned -scope CurrentUser
  "
  }

  # we only support x86_64 at this point, stop if we got arm
  if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64' -and -not ($env:PROCESSOR_ARCHITECTURE -eq "x86" -and [Environment]::Is64BitOperatingSystem)) {
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
  if($Product -ne 'mondoo') {
    $filetype = 'zip'
  }

  $releaseurl = ''
  If(![string]::IsNullOrEmpty($Version)) {
    # specific version
    $releaseurl = determine_version $Product $filetype $Version
  } else {
    # latest release
    $releaseurl = determine_latest $Product $filetype
  }

  # Check if Path exists
  $Path = $Path.trim('\')
  if (!(Test-Path $Path)) {New-Item -Path $Path -ItemType Directory}

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

    If($UpdateTask.ToLower() -eq 'enable') {
      # Creating a scheduling task to automatically update the Mondoo client
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

    If(![string]::IsNullOrEmpty($RegistrationToken)) {
      info "
      Register $Product Client
      "
      # Set Proxy if enabled
      If (![string]::IsNullOrEmpty($Proxy)) {
        $env:https_proxy = $Proxy;
      }
      $env:Path = "$PATH;" + $env:Path
      iex "$Product register -t '$RegistrationToken' --config 'C:\ProgramData\Mondoo\mondoo.yml'"
    }

    If (@(0,3010) -contains $process.ExitCode) { 
      success " * $Product was installed successfully!"
    } Else {
      fail (" * $Product installation failed with exit code: {0}" -f $process.ExitCode)
    }

    # Check if Service parameter is set and Parameter Product is set to mondoo
    If($Service.ToLower() -eq 'enable' -and $Product.ToLower() -eq 'mondoo') {
      # start Mondoo service
      enable_service
    }

    If($UpdateTask.ToLower() -eq 'enable') {
      # Creating a scheduling task to automatically update the Mondoo client
      $taskname = $Product + "Updater"
      $taskpath = $Product
      If(Get-ScheduledTask -TaskName $taskname -EA 0)
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
  info "
  If you have any questions, please come join us in our Mondoo Community on GitHub Discussions:

    * https://github.com/orgs/mondoohq/discussions
  "

  # reset erroractionpreference
  $erroractionpreference = $previous_erroractionpreference
  }
}

# SIG # Begin signature block
# MIIJkAYJKoZIhvcNAQcCoIIJgTCCCX0CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA3G10wx3MhPRbs
# Hqdbys7calRrhlY5xbkJnMV6zJ7gyKCCB1kwggNZMIIC36ADAgECAhAPuKdAuRWN
# A1FDvFnZ8EApMAoGCCqGSM49BAMDMGExCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxE
# aWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xIDAeBgNVBAMT
# F0RpZ2lDZXJ0IEdsb2JhbCBSb290IEczMB4XDTIxMDQyOTAwMDAwMFoXDTM2MDQy
# ODIzNTk1OVowZDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MTwwOgYDVQQDEzNEaWdpQ2VydCBHbG9iYWwgRzMgQ29kZSBTaWduaW5nIEVDQyBT
# SEEzODQgMjAyMSBDQTEwdjAQBgcqhkjOPQIBBgUrgQQAIgNiAAS7tKwnpUgNolNf
# jy6BPi9TdrgIlKKaqoqLmLWx8PwqFbu5s6UiL/1qwL3iVWhga5c0wWZTcSP8GtXK
# IA8CQKKjSlpGo5FTK5XyA+mrptOHdi/nZJ+eNVH8w2M1eHbk+HejggFXMIIBUzAS
# BgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBSbX7A2up0GrhknvcCgIsCLizh3
# 7TAfBgNVHSMEGDAWgBSz20ik+aHF2K42QcwRY2liKbxLxjAOBgNVHQ8BAf8EBAMC
# AYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdgYIKwYBBQUHAQEEajBoMCQGCCsGAQUF
# BzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQAYIKwYBBQUHMAKGNGh0dHA6
# Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEdsb2JhbFJvb3RHMy5jcnQw
# QgYDVR0fBDswOTA3oDWgM4YxaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lD
# ZXJ0R2xvYmFsUm9vdEczLmNybDAcBgNVHSAEFTATMAcGBWeBDAEDMAgGBmeBDAEE
# ATAKBggqhkjOPQQDAwNoADBlAjB4vUmVZXEB0EZXaGUOaKncNgjB7v3UjttAZT8N
# /5Ovwq5jhqN+y7SRWnjsBwNnB3wCMQDnnx/xB1usNMY4vLWlUM7m6jh+PnmQ5KRb
# qwIN6Af8VqZait2zULLd8vpmdJ7QFmMwggP4MIIDfqADAgECAhAMQh2DVCNS9gAH
# AUDbyB/QMAoGCCqGSM49BAMDMGQxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdp
# Q2VydCwgSW5jLjE8MDoGA1UEAxMzRGlnaUNlcnQgR2xvYmFsIEczIENvZGUgU2ln
# bmluZyBFQ0MgU0hBMzg0IDIwMjEgQ0ExMB4XDTIyMDcyNjAwMDAwMFoXDTIzMDgy
# MzIzNTk1OVowYTELMAkGA1UEBhMCVVMxFzAVBgNVBAgTDk5vcnRoIENhcm9saW5h
# MQ0wCwYDVQQHEwRDYXJ5MRQwEgYDVQQKEwtNb25kb28sIEluYzEUMBIGA1UEAxML
# TW9uZG9vLCBJbmMwdjAQBgcqhkjOPQIBBgUrgQQAIgNiAARUDKJuSitW5Rlrgatr
# LGPgCr66+QWf9M9k+XRq3cvUvZIfU4O8WRoGfx85BDNFg53VhEyTXf/Ue9TJOm3c
# MxPrVdzIrcfEKWUR2yJ9MGHHu7kUKtenxj68jeb+4f6yQJSjggH2MIIB8jAfBgNV
# HSMEGDAWgBSbX7A2up0GrhknvcCgIsCLizh37TAdBgNVHQ4EFgQUzssLU2l+Zcug
# 4YeJgjphzhUKG1gwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMD
# MIGrBgNVHR8EgaMwgaAwTqBMoEqGSGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydEdsb2JhbEczQ29kZVNpZ25pbmdFQ0NTSEEzODQyMDIxQ0ExLmNybDBO
# oEygSoZIaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0R2xvYmFsRzND
# b2RlU2lnbmluZ0VDQ1NIQTM4NDIwMjFDQTEuY3JsMD4GA1UdIAQ3MDUwMwYGZ4EM
# AQQBMCkwJwYIKwYBBQUHAgEWG2h0dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzCB
# jgYIKwYBBQUHAQEEgYEwfzAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNl
# cnQuY29tMFcGCCsGAQUFBzAChktodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRHbG9iYWxHM0NvZGVTaWduaW5nRUNDU0hBMzg0MjAyMUNBMS5jcnQw
# DAYDVR0TAQH/BAIwADAKBggqhkjOPQQDAwNoADBlAjEAv9kLshibq22ggP6mJrc5
# r2Tr35w1xGELT/N4FteiR+kcXnHg9xM6XiwVVbr+Rg1eAjBAb1FUqzS/PEWYyFcW
# 1LYHRuRNofwObaW/1ug35EkXC23yn6bh9z4ZUkU3Sv+Rbj0xggGNMIIBiQIBATB4
# MGQxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE8MDoGA1UE
# AxMzRGlnaUNlcnQgR2xvYmFsIEczIENvZGUgU2lnbmluZyBFQ0MgU0hBMzg0IDIw
# MjEgQ0ExAhAMQh2DVCNS9gAHAUDbyB/QMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisG
# AQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJCu
# O8ss7VnXMYzpBib9v4jnlnidcCkDmPrTepVfuBJ6MAsGByqGSM49AgEFAARnMGUC
# MAsfHHLG52sGKubzuOfptBPLCc+ekfZU+iJ9fUsm08PzmXKZaDOsRMvj94RT/DsC
# 7gIxAKDfDj84COyd0AhpN30cRjHxho+GIZjkrAS3evCpL+EPgx3oq5tgKP/nQ2Cj
# a3bhRw==
# SIG # End signature block
