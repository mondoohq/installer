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
    Import-Module ./install.ps1; Install-Mondoo -CleanupStaleSystem32 disable
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
    [string]   $Name = '',
    [string]   $UpdatesUrl = '',
    [ValidateSet('enable', 'disable')]
    [string]   $CleanupStaleSystem32 = 'enable'
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


    function download($url, $to) {
      $wc = New-Object Net.Webclient
      If (![string]::IsNullOrEmpty($Proxy)) {
        $wc.proxy = New-Object System.Net.WebProxy($Proxy)
      }
      $wc.Headers.Add('User-Agent', (Get-UserAgent))
      $wc.downloadFile($url, $to)
    }

    function determine_latest {
      Param
      (
        [Parameter(Mandatory)]
        [string[]]$product
      )
      $url_version = "https://releases.mondoo.com/${product}/latest.json"
      $wc = New-Object Net.Webclient
      If (![string]::IsNullOrEmpty($Proxy)) {
        $wc.proxy = New-Object System.Net.WebProxy($Proxy)
      }
      $wc.Headers.Add('User-Agent', (Get-UserAgent))
      $json = $wc.DownloadString($url_version)
      $release = ConvertFrom-Json $json
      $release.version
    }

    function getenv($name, $global) {
      $target = 'User'; if ($global) { $target = 'Machine' }
      [System.Environment]::GetEnvironmentVariable($name, $target)
    }

    function setenv($name, $value, $global) {
      $target = 'User'; if ($global) { $target = 'Machine' }
      [System.Environment]::SetEnvironmentVariable($name, $value, $target)
    }

    function enable_service() {
      info " * Set cnspec to run as a service automatically at startup and start the service"
      If ((Get-Service -Name Mondoo).Status -eq 'Running') {
        info " * Restarting $Product Service as it is already running"
        Restart-Service -Name Mondoo -Force
      }
      IF ((Get-Host).Version.Major -le 5) {
        Set-Service -Name Mondoo -Status Running -StartupType Automatic
        sc.exe config Mondoo start=delayed-auto
      }
      Else {
        Set-Service -Name Mondoo -Status Running -StartupType AutomaticDelayedStart
      }

      If (((Get-Service -Name Mondoo).Status -eq 'Running') -and ((Get-Service -Name Mondoo).StartType -contains 'Automatic') ) {
        success "* $Product Service is running and start type is automatic delayed start"
      }
      Else {
        fail "Mondoo service configuration failed"
      }
    }

    function NewScheduledTaskFolder($taskpath) {
      $ErrorActionPreference = "stop"
      $scheduleObject = New-Object -ComObject schedule.service
      $scheduleObject.connect()
      $rootFolder = $scheduleObject.GetFolder("\")
      Try { $null = $scheduleObject.GetFolder($taskpath) }
      Catch { $null = $rootFolder.CreateFolder($taskpath) }
      Finally { $ErrorActionPreference = "continue" }
    }

    function Remove-StaleSystem32MondooBinary {
      [CmdletBinding(SupportsShouldProcess)]
      param()
      # Some customers have ended up with cnspec.exe / cnquery.exe inside
      # C:\Windows\System32. That copy shadows the supported install at
      # C:\Program Files\Mondoo\ because System32 sits earlier in PATH, and it
      # persists across MSI upgrades (MSI never placed files there, so it will
      # never remove them either). We only touch files we can positively
      # identify as Mondoo-signed via Authenticode — never a blind delete.
      #
      # Note for EDR operators: this function deletes files from System32,
      # which EDRs will rightfully flag. The operation is performed from the
      # signed Mondoo install script running elevated, only against binaries
      # whose Authenticode signer is Mondoo, Inc. Every decision (remove,
      # skip, error) is written to C:\ProgramData\Mondoo\system32-cleanup.log
      # so SOC teams can correlate the EDR event with a forensic artifact.
      # Pass -CleanupStaleSystem32 'disable' to skip this step if your
      # change-management policy requires removal via a separate approved
      # procedure.
      $logDir  = 'C:\ProgramData\Mondoo'
      $logPath = Join-Path $logDir 'system32-cleanup.log'

      function Write-CleanupLog([string]$line) {
        try {
          if (-not (Test-Path -LiteralPath $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
          }
          $ts = Get-Date -Format o
          Add-Content -LiteralPath $logPath -Value "$ts $line"
        } catch {
          # A failed log write must never break the cleanup itself, but
          # surface a warning so operators can fix the log-path permissions
          # or disk issue without the failure being completely silent.
          Write-Warning "Unable to write cleanup log at ${logPath}: $_"
        }
      }

      $system32 = [Environment]::GetFolderPath('System')
      $candidates = @('cnspec.exe', 'cnquery.exe', 'mql.exe') | ForEach-Object { Join-Path $system32 $_ }

      foreach ($path in $candidates) {
        if (-not (Test-Path -LiteralPath $path)) { continue }

        info " * Detected legacy binary at $path — verifying Authenticode signature before removal"

        $sig = $null
        try {
          $sig = Get-AuthenticodeSignature -FilePath $path -ErrorAction Stop
        } catch {
          $reason = "unable to read signature: $_"
          info "   Skipping $path — $reason. Leaving file in place for manual review."
          Write-CleanupLog "skipped path=`"$path`" reason=`"$reason`""
          continue
        }

        if ($sig.Status -ne 'Valid') {
          $reason = "Authenticode status is '$($sig.Status)'"
          info "   Skipping $path — $reason. Leaving file in place for manual review."
          Write-CleanupLog "skipped path=`"$path`" reason=`"$reason`""
          continue
        }

        # Require the certificate Organization (O=) field to be Mondoo — a
        # substring match anywhere in the DN would accept certs where 'Mondoo'
        # merely appears in CN/OU/L. Both the DigiCert and Azure Trusted
        # Signing certificates used by Mondoo builds set O="Mondoo, Inc.".
        $subject = $sig.SignerCertificate.Subject
        if ($subject -notmatch 'O="?Mondoo, Inc\.') {
          info "   Skipping $path — signed by '$subject', not a Mondoo, Inc. certificate. Leaving file in place for manual review."
          Write-CleanupLog "skipped path=`"$path`" reason=`"signer is not Mondoo, Inc.`" signer=`"$subject`""
          continue
        }

        info "   Verified Mondoo-signed ($subject). Removing stale copy from System32."
        if ($PSCmdlet.ShouldProcess($path, 'Remove stale Mondoo-signed binary from System32')) {
          try {
            Remove-Item -LiteralPath $path -Force -ErrorAction Stop
            success "   Removed $path"
            Write-CleanupLog "removed path=`"$path`" signer=`"$subject`""
          } catch {
            $reason = "failed to remove: $_"
            info "   Warning: failed to remove $path ($_). If a process has the file open, reboot and re-run this script, or delete manually."
            Write-CleanupLog "error path=`"$path`" reason=`"$reason`""
          }
        }
      }
    }

    function CreateAndRegisterMondooUpdaterTask($taskname, $taskpath) {
      info " * Create and register the Mondoo update task"
      NewScheduledTaskFolder $taskpath

      # Start building the command string
      $command = @(
        '[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;'
        '$wc = New-Object Net.Webclient;'
      )

      if (![string]::IsNullOrEmpty($Proxy)) {
        $command += '$wc.proxy = New-Object System.Net.WebProxy(' + "'$Proxy'" + ');'
      }

      $command += 'iex ($wc.DownloadString(' + "'https://install.mondoo.com/ps1'" + '));'

      # Start building the Install-Mondoo command
      $installCmd = @("Install-Mondoo")
      $installCmd += "-Product $Product"
      $installCmd += "-Path '$Path'"

      if ($Service.ToLower() -eq 'enable' -and $Product.ToLower() -eq 'mondoo') {
        $installCmd += "-Service enable"
      }
      if (![string]::IsNullOrEmpty($Annotation)) {
        $installCmd += "-Annotation '$Annotation'"
      }
      if (![string]::IsNullOrEmpty($Name)) {
        $installCmd += "-Name $Name"
      }
      if (![string]::IsNullOrEmpty($Proxy)) {
        $installCmd += "-Proxy $Proxy"
      }
      if ($UpdateTask.ToLower() -eq 'enable') {
        $installCmd += "-UpdateTask enable -Time $Time -Interval $Interval;"
      }

      $command += ($installCmd -join ' ')

      # Wrap command in quotes for -Command argument
      $taskArgument = "-NoProfile -WindowStyle Hidden -ExecutionPolicy RemoteSigned -Command `"&{ $($command -join ' ') }`""
      info " * Scheduled Task argument: $taskArgument"

      # Build scheduled task components
      $action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $taskArgument
      $trigger = New-ScheduledTaskTrigger -Daily -DaysInterval $Interval -At $Time
      $principal = New-ScheduledTaskPrincipal -GroupId "NT AUTHORITY\SYSTEM" -RunLevel Highest
      $settings = New-ScheduledTaskSettingsSet -Compatibility Win8

      Register-ScheduledTask -Action $action -Settings $settings -Trigger $trigger -TaskName $taskname -Description "$Product Updater Task" -TaskPath $taskpath -Principal $principal

      if (Get-ScheduledTask -TaskName $taskname -EA 0) {
        success "* $Product Updater Task installed"
      }
      else {
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
    info ("  CleanupStaleSystem32: {0}" -f $CleanupStaleSystem32)
    info ""

    function Clear-LegacyCnquery {
      # Remove cnquery if it is installed - it has been superseded by cnspec + mql.
      # cnquery was only distributed as a zip (never MSI), so we just remove the exe from the install path.
      $cnqueryExe = Join-Path $Path "cnquery.exe"
      if (Test-Path $cnqueryExe) {
        info " * Removing $cnqueryExe - superseded by cnspec and mql"
        Remove-Item $cnqueryExe -Force -ErrorAction SilentlyContinue
        success " * cnquery.exe removed"
      }
    }

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
    if ($installed_version) {
      $installed_version | Add-Member -NotePropertyName version -NotePropertyValue $installed_version.DisplayVersion -Force
    }

    $arch = 'amd64'
    if ($env:PROCESSOR_ARCHITECTURE -match "ARM") {
      $arch = 'arm64'
    }
    $releaseurl = ''
    $version = $Version

    If ([string]::IsNullOrEmpty($Version)) {
      # latest release
      $version = determine_latest -product $Product
    }
    # construct release URL from releases.mondoo.com
    $releaseurl = "https://releases.mondoo.com/${Product}/${version}/${Product}_${version}_windows_${arch}.${filetype}"

    # Check if Path exists
    $Path = $Path.trim('\')
    If (!(Test-Path $Path)) { New-Item -Path $Path -ItemType Directory }

    If ($version -ne $installed_version.version) {
      # download windows binary zip/msi
      $downloadlocation = "$Path\$Product.$filetype"
      info " * Downloading $Product from $releaseurl to $downloadlocation"
      download $releaseurl $downloadlocation
    }
    Else {
      info " * Do not download $Product as latest version is already installed."
    }

    If ($filetype -eq 'zip') {
      # cnspec and mql supersede cnquery - remove it if present
      If ($Product -in @('cnspec', 'mql')) {
        Clear-LegacyCnquery
      }
      If ($version -ne $installed_version.version) {
        info ' * Extracting zip...'
        # remove older version if it is still there
        Remove-Item "$Path\$Product.exe" -Force -ErrorAction Ignore
        Add-Type -Assembly "System.IO.Compression.FileSystem"
        [IO.Compression.ZipFile]::ExtractToDirectory($downloadlocation, $Path)
        Remove-Item $downloadlocation -Force

        success " * $Product was downloaded successfully! You can find it in $Path\$Product.exe"
      }

      If ($UpdateTask.ToLower() -eq 'enable') {
        # Creating a scheduling task to automatically update the Mondoo package
        $taskname = $Product + "Updater"
        $taskpath = $Product
        If (Get-ScheduledTask -TaskName $taskname -EA 0) {
          Unregister-ScheduledTask -TaskName $taskname -Confirm:$false
        }
        CreateAndRegisterMondooUpdaterTask $taskname $taskpath
      }
    }
    ElseIf ($filetype -eq 'msi') {
      If ($version -ne $installed_version.version) {
        info ' * Installing msi package...'
        $file = Get-Item $downloadlocation
        $packageName = $Product
        $timeStamp = Get-Date -Format yyyyMMddTHHmmss
        $logFile = '{0}\{1}-{2}.MsiInstall.log' -f $env:TEMP, $packageName, $timeStamp
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
          $login_params = $login_params + @('--annotation', $Annotation)
        }
        if (![string]::IsNullOrEmpty($Name)) {
          $login_params = $login_params + @('--name', $Name)
        }
        If (![string]::IsNullOrEmpty($UpdatesUrl)) {
          $login_params = $login_params + @("--updates-url", "$UpdatesUrl")
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
        }
        elseif ($output) {
          info "$output"
        }
        else {
          info "No output"
        }
      }

      If ($version -ne $installed_version.version) {
        If (@(0, 3010) -contains $process.ExitCode) {
          success " * $Product was installed successfully!"
        }
        Else {
          fail (" * $Product installation failed with exit code: {0}" -f $process.ExitCode)
        }
      }
      Else {
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
        If (Get-ScheduledTask -TaskName $taskname -EA 0) {
          Unregister-ScheduledTask -TaskName $taskname -Confirm:$false
        }
        CreateAndRegisterMondooUpdaterTask $taskname $taskpath
      }

      If ($version -ne $installed_version.version) {
        Remove-Item $downloadlocation -Force
      }

    }
    Else {
      fail "${filetype} is not supported for download"
    }

    # Clean up stale cnspec.exe / cnquery.exe in C:\Windows\System32 left
    # behind by historical misinstalls. Runs after the supported install at
    # C:\Program Files\Mondoo\ is in place, so the new binary is always the
    # fallback. Opt out with -CleanupStaleSystem32 'disable'.
    If ($CleanupStaleSystem32 -ine 'disable') {
      Remove-StaleSystem32MondooBinary
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
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    # reset erroractionpreference
    $erroractionpreference = $previous_erroractionpreference
  }
}

# SIG # Begin signature block
# MII9RAYJKoZIhvcNAQcCoII9NTCCPTECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD04Gqs3SLd8rz1
# zbTR1SjpZhVURUxzWV2AMZIiGxONTKCCIeowggXMMIIDtKADAgECAhBUmNLR1FsZ
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
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggaiMIIEiqADAgECAhMzAACQw/68
# /vJXPSxPAAAAAJDDMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBFT0MgQ0EgMDQwHhcNMjYwNDI4MDMzNTUzWhcNMjYwNTAx
# MDMzNTUzWjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAm+8m
# tmmPo8MhAtbN3rHMECBT06bhcNa1vTQsx8m7EaXOt69Nnzk2JcXgOy8fiW41XE3k
# 0YjGSwOlTAHTysEgS55EYA/HUP3fTG7kLRgEEVnNXNKwxqgNcsFgAoEUNJ2yfoYk
# DMg3bKbEDY6M5ly2n/zMWcgu5ts2CHeqxf1WvratkS9vgHOF98AI+xq3uDjNPEZK
# QsU5D3gK1MZqjb/mkojcbI6e0xWc544AI13u3G73+3rdsTjoQclIYx5RZupd0ZOC
# 8fgozYrrDuBNDy2dB7FQ3GY9d1qGTgX4WvRwRo2Wltivrg0O0lHerzikfrrRbvED
# pxoNmuu9VGhNYhbz5oehFQpJ7K84Pyn3GK6D4m0R1nKZRAuoJhHHGadWvXa2gkHL
# iHF7eqqADUwfUE85GRkaTf4kgyEMh64YXFWuYThSO7TheH7VjWYkRll5qqGCSRK1
# GrhHYz987O5l8ShB3m9M+OuGOorr2zGGvJVG3FMLMeuQ+D3nITyxw1ei+YTPAgMB
# AAGjggHWMIIB0jAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQUq3bjyKgeiJLd94a2+IDpay35y5IwHwYDVR0jBBgw
# FoAUmvFUd3UMhxY3RqCs3nn59H/BeOkwZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwRU9DJTIwQ0ElMjAwNC5jcmwwdAYIKwYBBQUHAQEEaDBm
# MGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Nl
# cnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIw
# MDQuY3J0MFQGA1UdIARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wDQYJ
# KoZIhvcNAQEMBQADggIBAEebvIJyp6C8ZD7UuvJpzfnMSy4scqf3TNpyKBguevB2
# ZhC8IUEPgKBxaSHSELkzdJCWq0X4JUe8mH3a4EiBvYYwwW73XkNeL4bKawNCKSCk
# ZdG5+y2JDj+a6Rlhf03Nt6SrG1T8yl9GYQ2lJnZqPJIajotU0rqDcvoBHWSFcuXy
# XJgi6Hma7V0I8gWQ4i4tIZxrM7Gim+nCSwB2DCSxaT0YiJKfuxIlGMeCHI+MONkE
# r4jmmZmskQZ8hrRgPI0LcsTSfbg0tUJhPcvwWFckKsr1h5ryy5cV2B7he5Dtk5aP
# PXZCE+LS5RqWeF2JviBP5WGMHRf1myCyQIXImat01e1yvpy12Nt2LkN2HanOia+6
# kLCPDosDqNgm85r0hj1xKCBdQDF7jcgjFIkKp61we62Y0PgDLwyFO9urlhfOyu4z
# +3yqtzzAWNtAsRn5PbXrl41BAhKfMnokhDVBrQNI0Xi+3WDzXEw9QmnccXrkXJxT
# sE56102Ca2tWabKrAcrrafU/x62Pb/KWq8/dOetfG074xjgcpjZFRsmnYd5eNzOM
# iHIucOd9hbHeDcxPuiLeNRT03PtRORqX5YS+KIogl/4w0Vak+5v1TXY2oaE2biM7
# c4SC0U7j2zdYXI8fK3FF5EgZ8UzVJ4pyOO1g1UI1F3/2zL6lReTnhIi5c2Fo3Sac
# MIIGojCCBIqgAwIBAgITMwAAkMP+vP7yVz0sTwAAAACQwzANBgkqhkiG9w0BAQwF
# ADBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgRU9DIENBIDA0MB4X
# DTI2MDQyODAzMzU1M1oXDTI2MDUwMTAzMzU1M1owYzELMAkGA1UEBhMCVVMxFzAV
# BgNVBAgTDk5vcnRoIENhcm9saW5hMQ0wCwYDVQQHEwRDYXJ5MRUwEwYDVQQKEwxN
# b25kb28sIEluYy4xFTATBgNVBAMTDE1vbmRvbywgSW5jLjCCAaIwDQYJKoZIhvcN
# AQEBBQADggGPADCCAYoCggGBAJvvJrZpj6PDIQLWzd6xzBAgU9Om4XDWtb00LMfJ
# uxGlzrevTZ85NiXF4DsvH4luNVxN5NGIxksDpUwB08rBIEueRGAPx1D930xu5C0Y
# BBFZzVzSsMaoDXLBYAKBFDSdsn6GJAzIN2ymxA2OjOZctp/8zFnILubbNgh3qsX9
# Vr62rZEvb4BzhffACPsat7g4zTxGSkLFOQ94CtTGao2/5pKI3GyOntMVnOeOACNd
# 7txu9/t63bE46EHJSGMeUWbqXdGTgvH4KM2K6w7gTQ8tnQexUNxmPXdahk4F+Fr0
# cEaNlpbYr64NDtJR3q84pH660W7xA6caDZrrvVRoTWIW8+aHoRUKSeyvOD8p9xiu
# g+JtEdZymUQLqCYRxxmnVr12toJBy4hxe3qqgA1MH1BPORkZGk3+JIMhDIeuGFxV
# rmE4Uju04Xh+1Y1mJEZZeaqhgkkStRq4R2M/fOzuZfEoQd5vTPjrhjqK69sxhryV
# RtxTCzHrkPg95yE8scNXovmEzwIDAQABo4IB1jCCAdIwDAYDVR0TAQH/BAIwADAO
# BgNVHQ8BAf8EBAMCB4AwPQYDVR0lBDYwNAYKKwYBBAGCN2EBAAYIKwYBBQUHAwMG
# HCsGAQQBgjdhgqndkVaCp5bkUoGRmP1vg9zbqyowHQYDVR0OBBYEFKt248ioHoiS
# 3feGtviA6Wst+cuSMB8GA1UdIwQYMBaAFJrxVHd1DIcWN0agrN55+fR/wXjpMGcG
# A1UdHwRgMF4wXKBaoFiGVmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIw
# MDQuY3JsMHQGCCsGAQUFBwEBBGgwZjBkBggrBgEFBQcwAoZYaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlm
# aWVkJTIwQ1MlMjBFT0MlMjBDQSUyMDA0LmNydDBUBgNVHSAETTBLMEkGBFUdIAAw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMA0GCSqGSIb3DQEBDAUAA4ICAQBHm7yCcqegvGQ+
# 1Lryac35zEsuLHKn90zacigYLnrwdmYQvCFBD4CgcWkh0hC5M3SQlqtF+CVHvJh9
# 2uBIgb2GMMFu915DXi+GymsDQikgpGXRufstiQ4/mukZYX9NzbekqxtU/MpfRmEN
# pSZ2ajySGo6LVNK6g3L6AR1khXLl8lyYIuh5mu1dCPIFkOIuLSGcazOxopvpwksA
# dgwksWk9GIiSn7sSJRjHghyPjDjZBK+I5pmZrJEGfIa0YDyNC3LE0n24NLVCYT3L
# 8FhXJCrK9Yea8suXFdge4XuQ7ZOWjz12QhPi0uUalnhdib4gT+VhjB0X9ZsgskCF
# yJmrdNXtcr6ctdjbdi5Ddh2pzomvupCwjw6LA6jYJvOa9IY9cSggXUAxe43IIxSJ
# CqetcHutmND4Ay8MhTvbq5YXzsruM/t8qrc8wFjbQLEZ+T2165eNQQISnzJ6JIQ1
# Qa0DSNF4vt1g81xMPUJp3HF65FycU7BOetdNgmtrVmmyqwHK62n1P8etj2/ylqvP
# 3TnrXxtO+MY4HKY2RUbJp2HeXjczjIhyLnDnfYWx3g3MT7oi3jUU9Nz7UTkal+WE
# viiKIJf+MNFWpPub9U12NqGhNm4jO3OEgtFO49s3WFyPHytxReRIGfFM1SeKcjjt
# YNVCNRd/9sy+pUXk54SIuXNhaN0mnDCCBygwggUQoAMCAQICEzMAAAAXJ0UJC4uH
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
# DT2uhJ04ji+tHD6n58vhavFIrmcxghqwMIIarAIBATBxMFoxCzAJBgNVBAYTAlVT
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jv
# c29mdCBJRCBWZXJpZmllZCBDUyBFT0MgQ0EgMDQCEzMAAJDD/rz+8lc9LE8AAAAA
# kMMwDQYJYIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQgKteBxZG6RQzQxtehpEhu
# R6e06kle28DuFGhW5wLVVQgwDQYJKoZIhvcNAQEBBQAEggGAIqSu43euCkD07yjd
# UvBk2E4Hv85/F+78bwuOauomlcSZzWcF8CbJOryhUX+cp3nZD2SYHZZH33QBg7K8
# 0rzmyOiqgx1HvlMLmC07Gtcsl2tTVfvdbvBoqqV2uxfgJ6ofeVrMFfqrgFpJH0qx
# HsQqTpfZZrxGwc0FhnlVppcDpIix+sdhPrEZdrnrTvPIv0qNNwEefiqaczExZKMv
# XVKWv1F1G0PFujX9oEKVV4v9+7MXFzK7XD2VTZjTAXoB7jbLb07Yqsj4OoleNOGr
# 1X/fnCa1iUXwSWvVz/7QfeqBOoZhoFzKm4lH1oE5mF3QlRYgbkmPg+5BYAd3zDYH
# SLd5IbZbpvCyEl1WT64SAppBY5FMOyOb6PV3PG9YvIRC1EK/3JiDBnO7t19YuJx4
# UyPHalsJm045T+LFIpKkTGOWVVjK7CwF9wYLSMSv6sXHfFWikMFJAIcg3VbyOm9r
# jchxtwwXIHIjCXt8e3gkUBlXHWFgVp/tER9pBswKOrO03lCBoYIYMDCCGCwGCisG
# AQQBgjcDAwExghgcMIIYGAYJKoZIhvcNAQcCoIIYCTCCGAUCAQMxDzANBglghkgB
# ZQMEAgIFADCCAXEGCyqGSIb3DQEJEAEEoIIBYASCAVwwggFYAgEBBgorBgEEAYRZ
# CgMBMEEwDQYJYIZIAWUDBAICBQAEMOpyTIyGajqfbAWwpZbQE3u1vVSdglXU+bnp
# gpJFGOLu+mjUUzyLtzDFLIuE3rFnGQIGaeiA+gUQGBIyMDI2MDQyODE3NDgwNy45
# OFowBIACAfSggeGkgd4wgdsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAl
# BgNVBAsTHm5TaGllbGQgVFNTIEVTTjo3RDAwLTA1RTAtRDk0NzE1MDMGA1UEAxMs
# TWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZSBTdGFtcGluZyBBdXRob3JpdHmggg8h
# MIIHgjCCBWqgAwIBAgITMwAAAAXlzw//Zi7JhwAAAAAABTANBgkqhkiG9w0BAQwF
# ADB3MQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MUgwRgYDVQQDEz9NaWNyb3NvZnQgSWRlbnRpdHkgVmVyaWZpY2F0aW9uIFJvb3Qg
# Q2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMjAwHhcNMjAxMTE5MjAzMjMxWhcNMzUx
# MTE5MjA0MjMxWjBhMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1lc3Rh
# bXBpbmcgQ0EgMjAyMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAJ58
# 51Jj/eDFnwV9Y7UGIqMcHtfnlzPREwW9ZUZHd5HBXXBvf7KrQ5cMSqFSHGqg2/qJ
# hYqOQxwuEQXG8kB41wsDJP5d0zmLYKAY8Zxv3lYkuLDsfMuIEqvGYOPURAH+Ybl4
# SJEESnt0MbPEoKdNihwM5xGv0rGofJ1qOYSTNcc55EbBT7uq3wx3mXhtVmtcCEr5
# ZKTkKKE1CxZvNPWdGWJUPC6e4uRfWHIhZcgCsJ+sozf5EeH5KrlFnxpjKKTavwfF
# P6XaGZGWUG8TZaiTogRoAlqcevbiqioUz1Yt4FRK53P6ovnUfANjIgM9JDdJ4e0q
# iDRm5sOTiEQtBLGd9Vhd1MadxoGcHrRCsS5rO9yhv2fjJHrmlQ0EIXmp4DhDBieK
# UGR+eZ4CNE3ctW4uvSDQVeSp9h1SaPV8UWEfyTxgGjOsRpeexIveR1MPTVf7gt8h
# Y64XNPO6iyUGsEgt8c2PxF87E+CO7A28TpjNq5eLiiunhKbq0XbjkNoU5JhtYUrl
# mAbpxRjb9tSreDdtACpm3rkpxp7AQndnI0Shu/fk1/rE3oWsDqMX3jjv40e8KN5Y
# sJBnczyWB4JyeeFMW3JBfdeAKhzohFe8U5w9WuvcP1E8cIxLoKSDzCCBOu0hWdjz
# KNu8Y5SwB1lt5dQhABYyzR3dxEO/T1K/BVF3rV69AgMBAAGjggIbMIICFzAOBgNV
# HQ8BAf8EBAMCAYYwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFGtpKDo1L0hj
# QM972K9J6T7ZPdshMFQGA1UdIARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNo
# dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5o
# dG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBD
# AEEwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTIftJqhSobyhmYBAcnz1AQ
# T2ioojCBhAYDVR0fBH0wezB5oHegdYZzaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSWRlbnRpdHklMjBWZXJpZmljYXRpb24l
# MjBSb290JTIwQ2VydGlmaWNhdGUlMjBBdXRob3JpdHklMjAyMDIwLmNybDCBlAYI
# KwYBBQUHAQEEgYcwgYQwgYEGCCsGAQUFBzAChnVodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElkZW50aXR5JTIwVmVyaWZp
# Y2F0aW9uJTIwUm9vdCUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5JTIwMjAyMC5j
# cnQwDQYJKoZIhvcNAQEMBQADggIBAF+Idsd+bbVaFXXnTHho+k7h2ESZJRWluLE0
# Oa/pO+4ge/XEizXvhs0Y7+KVYyb4nHlugBesnFqBGEdC2IWmtKMyS1OWIviwpnK3
# aL5JedwzbeBF7POyg6IGG/XhhJ3UqWeWTO+Czb1c2NP5zyEh89F72u9UIw+IfvM9
# lzDmc2O2END7MPnrcjWdQnrLn1Ntday7JSyrDvBdmgbNnCKNZPmhzoa8PccOiQlj
# jTW6GePe5sGFuRHzdFt8y+bN2neF7Zu8hTO1I64XNGqst8S+w+RUdie8fXC1jKu3
# m9KGIqF4aldrYBamyh3g4nJPj/LR2CBaLyD+2BuGZCVmoNR/dSpRCxlot0i79dKO
# ChmoONqbMI8m04uLaEHAv4qwKHQ1vBzbV/nG89LDKbRSSvijmwJwxRxLLpMQ/u4x
# XxFfR4f/gksSkbJp7oqLwliDm/h+w0aJ/U5ccnYhYb7vPKNMN+SZDWycU5ODIRfy
# oGl59BsXR/HpRGtiJquOYGmvA/pk5vC1lcnbeMrcWD/26ozePQ/TWfNXKBOmkFpv
# PE8CH+EeGGWzqTCjdAsno2jzTeNSxlx3glDGJgcdz5D/AAxw9Sdgq/+rY7jjgs7X
# 6fqPTXPmaCAJKVHAP19oEjJIBwD1LyHbaEgBxFCogYSOiUIr0Xqcr1nJfiWG2GwY
# e6ZoAF1bMIIHlzCCBX+gAwIBAgITMwAAAFXZ3WkmKPn44gAAAAAAVTANBgkqhkiG
# 9w0BAQwFADBhMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1lc3RhbXBp
# bmcgQ0EgMjAyMDAeFw0yNTEwMjMyMDQ2NDlaFw0yNjEwMjIyMDQ2NDlaMIHbMQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNy
# b3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBF
# U046N0QwMC0wNUUwLUQ5NDcxNTAzBgNVBAMTLE1pY3Jvc29mdCBQdWJsaWMgUlNB
# IFRpbWUgU3RhbXBpbmcgQXV0aG9yaXR5MIICIjANBgkqhkiG9w0BAQEFAAOCAg8A
# MIICCgKCAgEAvbkfkh5ZSLP0MCUWafaw/KZoVZu9iQx8r5JwhZvdrUi86UjCCFQO
# NjQanrIxGF9hRGIZLQZ50gHrLC+4fpUEJff5t04VwByWC2/bWOuk6NmaTh9JpPZD
# cGzNR95QlryjfEjtl+gxj12zNPEdADPplVfzt8cYRWFBx/Fbfch08k6P9p7jX2q1
# jFPbUxWYJ+xOyGC1aKhDGY5b+8wL39v6qC0HFIx/v3y+bep+aEXooK8VoeWK+szf
# aFjXo8YTcvQ8UL4szu9HFTuZNv6vvoJ7Ju+o5aTj51sph+0+FXW38TlL/rDBd5ia
# 79jskLtOeHbDjkbljilwzegcxv9i49F05ZrS/5ELZCCY1VaqO7EOLKVaxxdAO5oy
# 1vb0Bx0ZRVX1mxFjYzay2EC051k6yGJHm58y1oe2IKRa/SM1+BTGse6vHNi5Q2d5
# ZnoR9AOAUDDwJIIqRI4rZz2MSinh11WrXTG9urF2uoyd5Ve+8hxes9ABeP2PYQKl
# XYTAxvdaeanDTQ/vwmnM+yTcWzrVm84Z38XVFw4G7p/ZNZ2nscvv6uru2AevXcyV
# 1t8ha7iWmhhgTWBNBrViuDlc3iPvOz2SVPbPeqhyY/NXwNZCAgc2H5pOztu6MwQx
# DIjte3XM/FkKBxHofS2abNT/0HG+xZtFqUJDaxgbJa6lN1zh7spjuQ8CAwEAAaOC
# AcswggHHMB0GA1UdDgQWBBRWBF8QbdwIA/DIv6nJFsrB16xltjAfBgNVHSMEGDAW
# gBRraSg6NS9IY0DPe9ivSek+2T3bITBsBgNVHR8EZTBjMGGgX6BdhltodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNyb3NvZnQlMjBQdWJsaWMl
# MjBSU0ElMjBUaW1lc3RhbXBpbmclMjBDQSUyMDIwMjAuY3JsMHkGCCsGAQUFBwEB
# BG0wazBpBggrBgEFBQcwAoZdaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
# cy9jZXJ0cy9NaWNyb3NvZnQlMjBQdWJsaWMlMjBSU0ElMjBUaW1lc3RhbXBpbmcl
# MjBDQSUyMDIwMjAuY3J0MAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYB
# BQUHAwgwDgYDVR0PAQH/BAQDAgeAMGYGA1UdIARfMF0wUQYMKwYBBAGCN0yDfQEB
# MEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# RG9jcy9SZXBvc2l0b3J5Lmh0bTAIBgZngQwBBAIwDQYJKoZIhvcNAQEMBQADggIB
# AFIe4ZJUe9qUKcWeWypchB58fXE/ZIWv2D5XP5/k/tB7LCN9BvmNSVKZ3VeclQM9
# 78wfEvuvdMQSUv6Y20boIM8DK1K1IU9cP21MG0ExiHxaqjrikf2qbfrXIip4Ef3v
# 2bNYKQxCxN3Sczp1SX0H7uqK2L5OhfDEiXf15iou5hh+EPaaqp49czNQpJDOR/vf
# JghUc/qcslDPhoCZpZx8b2ODvywGQNXwqlbsmCS24uGmEkQ3UH5JUeN6c91yasVc
# hS78riMrm6R9ZpAiO5pfNKMGU2MLm1A3pp098DcbFTAc95Hh6Qvkh//28F/Xe2bM
# Fb6DL7Sw0ZO95v0gv0ZTyJfxS/LCxfraeEII9FSFOKAMEp1zNFSs2ue0GGjBt9yE
# EMUwvxq9ExFz0aZzYm8ivJfffpIVDnX/+rVRTYcxIkQyFYslIhYlWF9SjCw5r49q
# akjMRNh8W9O7aaoolSVZleQZjGt0K8JzMlyp6hp2lbW6XqRx2cOHbbxJDxmENzoh
# GUziI13lI2g2Bf5qibfC4bKNRpJo9lbE8HUbY0qJiE8u3SU8eDQaySPXOEhJjxRC
# QwwOvejYmBG5P7CckQNBSnnl12+FKRKgPoj0Mv+z5OMhj9z2MtpbnHLAkep0odQC
# lEyyCG/uR5tK5rW6mZH5Oq56UWS0NI6NV1JGS7Jri6jFMYIHUzCCB08CAQEweDBh
# MQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIw
# MAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1lc3RhbXBpbmcgQ0EgMjAy
# MAITMwAAAFXZ3WkmKPn44gAAAAAAVTANBglghkgBZQMEAgIFAKCCBKwwEQYLKoZI
# hvcNAQkQAg8xAgUAMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAcBgkqhkiG
# 9w0BCQUxDxcNMjYwNDI4MTc0ODA3WjA/BgkqhkiG9w0BCQQxMgQwe0s/AbvExEQA
# v1c6A//lPh+gN+qXG+Htduwm89rDomrwY3AMfMjweHpFW4jWzkhhMIG5BgsqhkiG
# 9w0BCRACLzGBqTCBpjCBozCBoAQg2Lk8l2SGYru/ff7+D2qrJnkswcYdK6pGKu7G
# GGr4/s0wfDBlpGMwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0
# YW1waW5nIENBIDIwMjACEzMAAABV2d1pJij5+OIAAAAAAFUwggNeBgsqhkiG9w0B
# CRACEjGCA00wggNJoYIDRTCCA0EwggIpAgEBMIIBCaGB4aSB3jCB2zELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0
# IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjdE
# MDAtMDVFMC1EOTQ3MTUwMwYDVQQDEyxNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1l
# IFN0YW1waW5nIEF1dGhvcml0eaIjCgEBMAcGBSsOAwIaAxUAHTtUAYJlv7bgWVeR
# Bo4X7FeHDeqgZzBlpGMwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGlt
# ZXN0YW1waW5nIENBIDIwMjAwDQYJKoZIhvcNAQELBQACBQDtmuhwMCIYDzIwMjYw
# NDI4MDgwNDAwWhgPMjAyNjA0MjkwODA0MDBaMHQwOgYKKwYBBAGEWQoEATEsMCow
# CgIFAO2a6HACAQAwBwIBAAICGOIwBwIBAAICGewwCgIFAO2cOfACAQAwNgYKKwYB
# BAGEWQoEAjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGG
# oDANBgkqhkiG9w0BAQsFAAOCAQEAfr+uJE0CuUzEAmQnRBQRe5DTafOI5xHS5MnR
# c313HBhl+CuinCN4B/KJyySeFFq12meZeAr9TmaemUhTuV658wWpgdyvI571OYnZ
# Jgw8zs/RUAyOpchun4L0fR8p5jp28ckU2NCu2aIID4rAjakwshomo6oQ5HE6pt6l
# e9Rgaet0B0td7nkbVS+N6G8kT5s2r0iUyVHAReXE0xSq3Lgb39XIzZc/m9rvf7P+
# 5SwZfLfk9GIqPSOFBkh0npGgYUEP6CV5iZrZuykvLNWm08bv4p1Mv5IER5uKvoRY
# SWPiQ4WRpKb4UrjZTDyjtMLMCQPztG1/OQlP4i/XjvwStXxTgzANBgkqhkiG9w0B
# AQEFAASCAgCneINpH+dBwbISW4VQzPBjfiyd0YB3iqV8aOqqCXcTmDk+uNIlqJu7
# RnTc4ZKFY0yEpedC4BaIJbkrMUodVKcJ9r6JzUWCYJxe8PKtK6NrSXS/rdlG9k6Y
# 2Mby9O4ltEnQutbAj0qBlXb5jHeFnGIXM2ppbw+3I4KrOhZMsqCedMbFgEEGx7Ac
# mnBx2M6iPcDU/pef7Ji/x/yvyGmESPZCdr3Y0drfWZ/4ZbveDvTF90cqooOAQE42
# rp9UlpHdjzwlkFUXMAwG9dT1Q5PY+MloEp1H1UbSXDEfxyEu4DBSJCI/Ti32s9MN
# HrMGpfIfOo44RS2uoS+uAfAakHvbagNAC0n0NBuqFx4D9reVvPg5SOVxA03U1NPp
# kTPfuMXgeWLT50wG/bXyl4/AOIoMeODfGYaIUliLeh3kFO9RDJSc/FOrWRvS3nqL
# Qo24rSlRsCFanTOK9KVr2tT7WNw8JvSFGFLJW0KdJNgiHnSeRdVzLKqIUjqi08m5
# 8Ovtp/hV503xkdcEBQzICCGlFyCHGCh/EQBfgxoPrBKLHDpfQ2sP6Jb517v84ZcQ
# WaiiKw3l/GmkJwJ1cPJA+6IusYujjqWlcXMc18VyS3uEK9+64EQUeODrJktMBbPN
# gAO9vrlqjy8JoY72JK//v7aIQ9rQPdi8s2uAwOBHh3cuuVF/uXGZ5g==
# SIG # End signature block
