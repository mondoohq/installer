#Requires -Version 5
#Requires -RunAsAdministrator
<#
    .SYNOPSIS
    This PowerShell script installs the latest Mondoo agent on windows. Usage:
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://mondoo.com/install.ps1')); Install-Mondoo;
    
    .PARAMETER RegistrationToken
    The registration token for your mondoo installation. See our docs if you do not
    have one: https://mondoo.com/docs/server/registration
    .PARAMETER DownloadType
    Set 'msi' (default) to download the package or 'zip' for the agent binary instead
    .PARAMETER Version
    If provided, tries to download the specific version instead of the latest
    .EXAMPLE
    Import-Module ./install.ps1; Install-Mondoo -RegistrationToken INSERTKEYHERE
    Import-Module ./install.ps1; Install-Mondoo -Version 5.14.1
#>
function Install-Mondoo {
  [CmdletBinding()]
  Param(
      [string]   $RegistrationToken = '',
      [string]   $DownloadType = 'msi',
      [string]   $Version = ''
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
    $wc.Headers.Add('User-Agent', (Get-UserAgent))
    $wc.downloadFile($url,$to)
  }

  function determine_latest($filetype) {
    $url = 'https://releases.mondoo.com/mondoo/latest.json'
    If([string]::IsNullOrEmpty($filetype)) {
      $filetype = [regex]::escape('msi')
    }
    $wc = New-Object Net.Webclient
    $wc.Headers.Add('User-Agent', (Get-UserAgent))
    $latest = $wc.DownloadString($url) | ConvertFrom-Json 
    $entry = $latest.files | where { $_.platform -eq "windows" -and $_.filename -match "${filetype}$" -and $_.filename -NotMatch "enterprise" }
    $entry.filename
  }

  function determine_version($filetype, $version) {
    $arch = 'amd64'
    $res = "https://releases.mondoo.com/mondoo/${version}/mondoo_${version}_windows_${arch}.${filetype}"
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

    * Mondoo Community Slack https://mondoo.link/slack

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
  our Mondoo Community Slack https://mondoo.link/slack or email us at hello@mondoo.com
  "
  }

  info "Arguments:"
  info ("  RegistrationToken: {0}" -f $RegistrationToken)
  info ("  DownloadType:      {0}" -f $DownloadType)
  info ("  Version:           {0}" -f $Version)
  info ""

  # determine download url
  $filetype = $DownloadType
  $releaseurl = ''
  If(![string]::IsNullOrEmpty($Version)) {
    # specific version
    $releaseurl = determine_version $filetype $Version
  } else {
    # latest release
    $releaseurl = determine_latest $filetype
  }

  # download windows binary zip/msi
  $dir = Get-Location
  $downloadlocation = "$dir\mondoo.$filetype"
  info " * Downloading mondoo from $releaseurl to $downloadlocation"
  download $releaseurl $downloadlocation

  If ($filetype -eq 'zip') {
    info ' * Extracting zip...'
    # remove older version if it is still there
    Remove-Item "$dir\mondoo.exe" -Force -ErrorAction Ignore
    Add-Type -Assembly "System.IO.Compression.FileSystem"
    [IO.Compression.ZipFile]::ExtractToDirectory($downloadlocation,$dir)
    Remove-Item $downloadlocation -Force

    success ' * Mondoo was downloaded successfully!'
  } ElseIf ($filetype -eq 'msi') {
    info ' * Installing msi package...'
    $file = Get-Item $downloadlocation
    $packageName = "mondoo"
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

    # add registration token to args if set
    If(![string]::IsNullOrEmpty($RegistrationToken)) {
      $argsList = $argsList += "RegistrationToken={0}" -f $RegistrationToken
    }

    info (' * Run installer {0} and log into {1}' -f $downloadlocation, $logFile)
    $process = Start-Process "msiexec.exe" -Wait -NoNewWindow -PassThru -ArgumentList $argsList
    # https://docs.microsoft.com/en-us/windows/win32/msi/error-codes
    If (@(0,3010) -contains $process.ExitCode) { 
      success ' * Mondoo was installed successfully!'
    } Else {
      fail (" * Mondoo installation failed with exit code: {0}" -f $process.ExitCode)
    }
    Remove-Item $downloadlocation -Force
    
  } Else {
    fail "${filetype} is not supported for download"
  }

  # Display final message
  info "
  Thank you for installing Mondoo!"
  info "
  If you have any questions, please come join us in our Mondoo Community Slack:

    * https://mondoo.link/slack
  "

  # reset erroractionpreference
  $erroractionpreference = $previous_erroractionpreference

  }
}
