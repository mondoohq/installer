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
# MII9/wYJKoZIhvcNAQcCoII98DCCPewCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCACY36FaY3eKXAk
# uD7GbQ31P7qG8iYxNjaE1+HqHjIrI6CCIqQwggXMMIIDtKADAgECAhBUmNLR1FsZ
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
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggbmMIIEzqADAgECAhMzAAdbPKux
# V+LY3kBUAAAAB1s8MA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBFT0MgQ0EgMDIwHhcNMjYwMzEwMDM0NjQ4WhcNMjYwMzEz
# MDM0NjQ4WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAiup0
# V1a1VYgyjr+DmhU2hvjaNkoGPn1oyVyOeHsb9bFSLNW99SeVHlHt4ZQ56NQeyGVs
# M2r56Y+q7ZOUQABFXehQVJOIctREvYlxTdOo4tY0IXhHCRxTULeDxxfpI0hCIm8O
# TZJjCGKdXNbZl9R2cUjXZJjvGHvBr5iCawni2nHkeMc0Jb0+75FKwW5mu+uOMqC/
# 0E86A24Nui1Ivgc2LUyBDOcOmbNkhuUHOkHO5mucyrg42offr1ybYtLIf57ZveUm
# m47JcyKxv5lCFEckDscgbCX6t5c8YW3jmutRJ7x5ArsBNGxlGRRB4arQgK8p85Fi
# 3QjUSkCDGiXZ48DU0stQCVZM0JV8PstUIj9MiNnppNK7IFYofhCSAsJjKWvPnEYO
# ykO6vsguqHBJfYGxDQ/YB7KHgTRLUGZoUkwXEhElSqPtfXv5ng0e5f/2XphYxatX
# fj2JrF4b6yEvFPA47X7fHT4i0kQIPiAuuYhJtYn8BMNiogNx1M4GRihXG0L1AgMB
# AAGjggIaMIICFjAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQUWI2wGKeqjdWeRtbjq9jW0skn/kYwHwYDVR0jBBgw
# FoAUZZ9RzoVofy+KRYiq3acxux4NAF4wZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwRU9DJTIwQ0ElMjAwMi5jcmwwgaUGCCsGAQUFBwEBBIGY
# MIGVMGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L2NlcnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENB
# JTIwMDIuY3J0MC0GCCsGAQUFBzABhiFodHRwOi8vb25lb2NzcC5taWNyb3NvZnQu
# Y29tL29jc3AwZgYDVR0gBF8wXTBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcC
# ARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRv
# cnkuaHRtMAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAQagqhhLuyYFSZVJp
# NPKNiSOnmscIXimdt8kcK7pySu6ImeJkgglKn51sYOu6Axox2hmga+Ty5D/2UtZC
# 7SdG5VsIb59T0KKQUGkYuT1gFbahHT8fw+18zHA89FINgWlvNbAARQGmHYa+O457
# bPpOIye6vUtZuhlALwCyGv+ztpoR11CVdITqouy/64p6OVZioJVi3YbKyeonVuTa
# gfazyX/N4s17Wm/yrLnr9B7atTha5xoDAzZH4hUgFGvQv+Dn5N5tQ6EaiiT8ycwk
# X3DnJ10/5VugyKo7E+aaL/qLyrnBWxjFw0Qdi2c7ckHnhp6WUxrjJlvE6LgChupr
# FCGlRsTGcBlQHQECSGLV2T9Y/ltWb0Wa8n7goEOlk7zWXLKsYU0odm1+a2c2kv18
# Muasr8nV5lw08laPQuxe9INxHWGz2O3AQUuWLR8V25YeoAPvVzT4j//jrY5hIlq8
# 9sRJQlG3AnKGGNnj2rAVSrQy+Xsv2y6YaxLCSYVwuzNGvQTIHfGapoCo380ZGKDI
# gQzItyC2gROzVcqeKnvo4UAkwJA/4byrsl+ikiHj43WzZJ3+RTCk+Tq4DJjr6Z8M
# AclYvNRuIyySs6Fv1DjOPHL0Li2ywzn/4kaC+u/rT7inYK6X4HU9m7EzAQDkHoox
# BBNIuLxAi/ybJ3C1drTlGVQMSwcwggbmMIIEzqADAgECAhMzAAdbPKuxV+LY3kBU
# AAAAB1s8MA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJp
# ZmllZCBDUyBFT0MgQ0EgMDIwHhcNMjYwMzEwMDM0NjQ4WhcNMjYwMzEzMDM0NjQ4
# WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmExDTALBgNV
# BAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMMTW9uZG9v
# LCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAiup0V1a1VYgy
# jr+DmhU2hvjaNkoGPn1oyVyOeHsb9bFSLNW99SeVHlHt4ZQ56NQeyGVsM2r56Y+q
# 7ZOUQABFXehQVJOIctREvYlxTdOo4tY0IXhHCRxTULeDxxfpI0hCIm8OTZJjCGKd
# XNbZl9R2cUjXZJjvGHvBr5iCawni2nHkeMc0Jb0+75FKwW5mu+uOMqC/0E86A24N
# ui1Ivgc2LUyBDOcOmbNkhuUHOkHO5mucyrg42offr1ybYtLIf57ZveUmm47JcyKx
# v5lCFEckDscgbCX6t5c8YW3jmutRJ7x5ArsBNGxlGRRB4arQgK8p85Fi3QjUSkCD
# GiXZ48DU0stQCVZM0JV8PstUIj9MiNnppNK7IFYofhCSAsJjKWvPnEYOykO6vsgu
# qHBJfYGxDQ/YB7KHgTRLUGZoUkwXEhElSqPtfXv5ng0e5f/2XphYxatXfj2JrF4b
# 6yEvFPA47X7fHT4i0kQIPiAuuYhJtYn8BMNiogNx1M4GRihXG0L1AgMBAAGjggIa
# MIICFjAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUENjA0Bgor
# BgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY/W+D3Nur
# KjAdBgNVHQ4EFgQUWI2wGKeqjdWeRtbjq9jW0skn/kYwHwYDVR0jBBgwFoAUZZ9R
# zoVofy+KRYiq3acxux4NAF4wZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBWZXJpZmll
# ZCUyMENTJTIwRU9DJTIwQ0ElMjAwMi5jcmwwgaUGCCsGAQUFBwEBBIGYMIGVMGQG
# CCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRz
# L01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIwMDIu
# Y3J0MC0GCCsGAQUFBzABhiFodHRwOi8vb25lb2NzcC5taWNyb3NvZnQuY29tL29j
# c3AwZgYDVR0gBF8wXTBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0
# cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRt
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAQagqhhLuyYFSZVJpNPKNiSOn
# mscIXimdt8kcK7pySu6ImeJkgglKn51sYOu6Axox2hmga+Ty5D/2UtZC7SdG5VsI
# b59T0KKQUGkYuT1gFbahHT8fw+18zHA89FINgWlvNbAARQGmHYa+O457bPpOIye6
# vUtZuhlALwCyGv+ztpoR11CVdITqouy/64p6OVZioJVi3YbKyeonVuTagfazyX/N
# 4s17Wm/yrLnr9B7atTha5xoDAzZH4hUgFGvQv+Dn5N5tQ6EaiiT8ycwkX3DnJ10/
# 5VugyKo7E+aaL/qLyrnBWxjFw0Qdi2c7ckHnhp6WUxrjJlvE6LgChuprFCGlRsTG
# cBlQHQECSGLV2T9Y/ltWb0Wa8n7goEOlk7zWXLKsYU0odm1+a2c2kv18Muasr8nV
# 5lw08laPQuxe9INxHWGz2O3AQUuWLR8V25YeoAPvVzT4j//jrY5hIlq89sRJQlG3
# AnKGGNnj2rAVSrQy+Xsv2y6YaxLCSYVwuzNGvQTIHfGapoCo380ZGKDIgQzItyC2
# gROzVcqeKnvo4UAkwJA/4byrsl+ikiHj43WzZJ3+RTCk+Tq4DJjr6Z8MAclYvNRu
# IyySs6Fv1DjOPHL0Li2ywzn/4kaC+u/rT7inYK6X4HU9m7EzAQDkHooxBBNIuLxA
# i/ybJ3C1drTlGVQMSwcwggdaMIIFQqADAgECAhMzAAAABft6XDITYd9dAAAAAAAF
# MA0GCSqGSIb3DQEBDAUAMGMxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xNDAyBgNVBAMTK01pY3Jvc29mdCBJRCBWZXJpZmllZCBD
# b2RlIFNpZ25pbmcgUENBIDIwMjEwHhcNMjEwNDEzMTczMTUzWhcNMjYwNDEzMTcz
# MTUzWjBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgRU9DIENBIDAy
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA0hqZfD8ykKTA6CDbWvsh
# mBpDoBf7Lv132RVuSqVwQO3aALLkuRnnTIoRmMGo0fIMQrtwR6UHB06xdqOkAfqB
# 6exubXTHu44+duHUCdE4ngjELBQyluMuSOnHaEdveIbt31OhMEX/4nQkph4+Ah0e
# R4H2sTRrVKmKrlOoQlhia73Qg2dHoitcX1uT1vW3Knpt9Mt76H7ZHbLNspMZLkWB
# abKMl6BdaWZXYpPGdS+qY80gDaNCvFq0d10UMu7xHesIqXpTDT3Q3AeOxSylSTc/
# 74P3og9j3OuemEFauFzL55t1MvpadEhQmD8uFMxFv/iZOjwvcdY1zhanVLLyplz1
# 3/NzSoU3QjhPdqAGhRIwh/YDzo3jCdVJgWQRrW83P3qWFFkxNiME2iO4IuYgj7Rw
# seGwv7I9cxOyaHihKMdT9NeoSjpSNzVnKKGcYMtOdMtKFqoV7Cim2m84GmIYZTBo
# rR/Po9iwlasTYKFpGZqdWKyYnJO2FV8oMmWkIK1iagLLgEt6ZaR0rk/1jUYssyTi
# RqWr84Qs3XL/V5KUBEtUEQfQ/4RtnI09uFFUIGJZV9mD/xOUksWodGrCQSem6Hy2
# 61xMJAHqTqMuDKgwi8xk/mflr7yhXPL73SOULmu1Aqu4I7Gpe6QwNW2TtQBxM3vt
# STmdPW6rK5y0gED51RjsyK0CAwEAAaOCAg4wggIKMA4GA1UdDwEB/wQEAwIBhjAQ
# BgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUZZ9RzoVofy+KRYiq3acxux4NAF4w
# VAYDVR0gBE0wSzBJBgRVHSAAMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTAZBgkrBgEEAYI3
# FAIEDB4KAFMAdQBiAEMAQTASBgNVHRMBAf8ECDAGAQH/AgEAMB8GA1UdIwQYMBaA
# FNlBKbAPD2Ns72nX9c0pnqRIajDmMHAGA1UdHwRpMGcwZaBjoGGGX2h0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMElEJTIwVmVy
# aWZpZWQlMjBDb2RlJTIwU2lnbmluZyUyMFBDQSUyMDIwMjEuY3JsMIGuBggrBgEF
# BQcBAQSBoTCBnjBtBggrBgEFBQcwAoZhaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlmaWVkJTIwQ29kZSUy
# MFNpZ25pbmclMjBQQ0ElMjAyMDIxLmNydDAtBggrBgEFBQcwAYYhaHR0cDovL29u
# ZW9jc3AubWljcm9zb2Z0LmNvbS9vY3NwMA0GCSqGSIb3DQEBDAUAA4ICAQBFSWDU
# d08X4g5HzvVfrB1SiV8pk6XPHT9jPkCmvU/uvBzmZRAjYk2gKYR3pXoStRJaJ/lh
# jC5Dq/2R7P1YRZHCDYyK0zvSRMdE6YQtgGjmsdhzD0nCS6hVVcgfmNQscPJ1WHxb
# vG5EQgYQ0ZED1FN0MOPQzWe1zbH5Va0dSxtnodBVRjnyDYEm7sNEcvJHTG3eXzAy
# d00E5KDCsEl4z5O0mvXqwaH2PS0200E6P4WqLwgs/NmUu5+Aa8Lw/2En2VkIW7Pk
# ir4Un1jG6+tj/ehuqgFyUPPCh6kbnvk48bisi/zPjAVkj7qErr7fSYICCzJ4s4YU
# NVVHgdoFn2xbW7ZfBT3QA9zfhq9u4ExXbrVD5rxXSTFEUg2gzQq9JHxsdHyMfcCK
# LFQOXODSzcYeLpCd+r6GcoDBToyPdKccjC6mAq6+/hiMDnpvKUIHpyYEzWUeatty
# KXtMf+QrJeQ+ny5jBL+xqdOOPEz3dg7qn8/oprUrUbGLBv9fWm18fWXdAv1PCtLL
# /acMLtHoyeSVMKQYqDHb3Qm0uQ+NQ0YE4kUxSQa+W/cCzYAI32uN0nb9M4Mr1pj4
# bJZidNkM4JyYqezohILxYkgHbboJQISrQWrm5RYdyhKBpptJ9JJn0Z63LjdnzlOU
# xjlsAbQir2Wmz/OJE703BbHmQZRwzPx1vu7S5zCCB54wggWGoAMCAQICEzMAAAAH
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
# RCBWZXJpZmllZCBDUyBFT0MgQ0EgMDICEzMAB1s8q7FX4tjeQFQAAAAHWzwwDQYJ
# YIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQg5qd3u9JtdBCjQ3o+82+9A8dbceWA
# xsHlk3TzOAJxceowDQYJKoZIhvcNAQEBBQAEggGAbJY+eGCKmNleBhvlqBrERUU7
# oBWgql/Ufx7zRUbPmmDYhTX+TEnhDbL8aZdQGwBtmCPkN9JzFdIMB9nz91CiKLmc
# c+r1f3lTyb/HkyLWmhP+ej/vJScMsjgIm9vY8bz5LcUt8zp0MgmTCfAhdxSRTBSP
# x0A3PsIOtNi/xL5zHSv4qlRxMtR0WdrGKsIz4LS+7f2hvXDhT2j8LYbw/jmApVzk
# XSfoq+wLHTzWM8O1cpvfSmP2AMf1XcOCWCqXJ2VIkzoHzvP9O06R/G27akBmn5NA
# 9F4jYXLkB9dDttGqzrXrzjVIVp9xqUmU4LFGDb1SDTTehZ+un9vFTQNOCL/y7gk3
# N54q5IpYzakVsoNtb185UifxtcSqpUTcpVioNaoJLH62zY1/FaQ/Dzg9+Xm1H30L
# yLKfOJ18c7m5WCCKyT9Bx02wQv2ngOP5Z5wAYa30+yQKKyUg8WYQVmBmTJQFG1sC
# bonPcSOVT58T90TMAtaYrwsPn41vuZaqeZ5eVJs/oYIYMTCCGC0GCisGAQQBgjcD
# AwExghgdMIIYGQYJKoZIhvcNAQcCoIIYCjCCGAYCAQMxDzANBglghkgBZQMEAgIF
# ADCCAXIGCyqGSIb3DQEJEAEEoIIBYQSCAV0wggFZAgEBBgorBgEEAYRZCgMBMEEw
# DQYJYIZIAWUDBAICBQAEMEuAUML5W/O06970N3aQc5SmiFpjzMs/TNVyJRyzXclw
# cTLgq7C6SvivcpJsJAjKjQIGaZRNZZ4lGBMyMDI2MDMxMDE0MzAwMC42NjVaMASA
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
# WzCCB5cwggV/oAMCAQICEzMAAABWfo+dWAiO6WAAAAAAAFYwDQYJKoZIhvcNAQEM
# BQAwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENB
# IDIwMjAwHhcNMjUxMDIzMjA0NjUxWhcNMjYxMDIyMjA0NjUxWjCB2zELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0
# IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOkE1
# MDAtMDVFMC1EOTQ3MTUwMwYDVQQDEyxNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1l
# IFN0YW1waW5nIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBALSln5v7pdNu/3fEZW/DJ/4NEFL7y6mNlbMt7SPFNrRUrKU2aJmTg9wR0/C5
# Efka4TCYG9VYwChTcrGivXC0l4nzxkiAazwoLPT+MtuJayRJq1ekOc+AZqjISD62
# YRL2Z1qQkuBzu42Enov58Zgu/9RK/peS4Nz5ksW/HdiFXAEcUsNQeJsQelyNJ5Hp
# fcGtXWG9sHxqaH62hZsWTsU/XjYbeCx9EQUlbnm2umTaY0v9ILX5u6oiIsj+qej0
# c002zJ1arB51f3f61tMx8fkPkDWecFKipk2SQfYVPOd/tqV+aw3yt9rjWPf1gTgJ
# s26oKRHUJG4jGr1DMlA0oZsnCL4B3UJ0ttO7E4/DPpCS97TnWoT7j6jMLGggoHX8
# MEMdDvUynuxUr2wBGLNQJ5XQpfyhxmQjlb1Dao8i9dCS3tP/hg/f8p6lxlhaVzo2
# rp72f3CkToYzeDOXuscdG9poqnD4ouP4otmYXimpZSRE+wipaRUobN8MoOhf36I0
# MULz521g+DcsepYY1o8JqC3MesNRUgrWrywpct9wS0UpU1OKilMWmvHe2DexKqZ/
# VztEmNLpjryhV61h+68ZfvYmonIrXZ005LAJ0Y73pHSk95YO5UTH5n2VPL1zYjdF
# GCc0/RI6o0ZtLjf4dKF8T4TXz2KnhW8j1xhsc2mFM+s8d6k3AgMBAAGjggHLMIIB
# xzAdBgNVHQ4EFgQUvrYz8rurWf4eRrMi78s9R/hTSFowHwYDVR0jBBgwFoAUa2ko
# OjUvSGNAz3vYr0npPtk92yEwbAYDVR0fBGUwYzBhoF+gXYZbaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNB
# JTIwVGltZXN0YW1waW5nJTIwQ0ElMjAyMDIwLmNybDB5BggrBgEFBQcBAQRtMGsw
# aQYIKwYBBQUHMAKGXWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0El
# MjAyMDIwLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
# MA4GA1UdDwEB/wQEAwIHgDBmBgNVHSAEXzBdMFEGDCsGAQQBgjdMg30BATBBMD8G
# CCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3Mv
# UmVwb3NpdG9yeS5odG0wCAYGZ4EMAQQCMA0GCSqGSIb3DQEBDAUAA4ICAQAOA6gF
# xLDtuo/y2uxYJ/0In4rfMbmXpKmee/mHvrB/4UU2xBIxmK2YLKsEf5VFHyghaW2R
# fJrGmT0CTkeGGFBFPF8oy65/GNYwkpqMYfZe7VokqHPyRQcN+eiQJsxhsXgQNhFk
# sUbk69QLmXup2GjfP8LRZIh3LPIDGncVwbOg8VYcruWJ4Sz0JH7pipt5RX7cBO6Y
# nle39ZbJJpYLAugHkhgsxj2VIAr3B+U7/0Hvc+2yCJkg90rs4TiMGj/nikE2H+u0
# 4n8iSpFkEnRn0wOinLuNZPCweqDyvjC5NY28cSucD6i0i+tsYytOEgVxxCUhJ7Bb
# dM8VpMT/5YHo9Q8alJ5q2BHZMb8ykhyAKhVkmbpf+YSPrycbxT4bDUARJOHErpQ5
# CUKXHVYv4Jn/5hxTmIQwY7GtebOC/trAYpd11f0/EYkeukPMWL0y0VsXdnVbKzqA
# sJ7FOFiHogtCYpwr9VixxIe0Ms6/UUq+JCiS1naTWC4YI5KI05hJAIxTu++Ld8Qe
# 3p27yBdBjrFdfcZwlM6vRBisrdIDLmqYSpTYyfmk6Y1jGQxqPhjirJ6fdx5n7Zpd
# EsqdxffjN8vsuliRlGaCGSattu4w44xJ3baVK4fQXT3VSH1SQ/wLvNUc4dOVBwIr
# 6K0NzrPDxCxyIIjnfU1s23YJhs3CC7f3XVUBETGCB1MwggdPAgEBMHgwYTELMAkG
# A1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UE
# AxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIwMjACEzMA
# AABWfo+dWAiO6WAAAAAAAFYwDQYJYIZIAWUDBAICBQCgggSsMBEGCyqGSIb3DQEJ
# EAIPMQIFADAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZIhvcNAQkF
# MQ8XDTI2MDMxMDE0MzAwMFowPwYJKoZIhvcNAQkEMTIEMNu2UJTwLTqHTvJSMcrX
# Xxn5WB9HIQuMVffaQv+DaCNQVIbrPQHt5Pw2E1LcyeKnPjCBuQYLKoZIhvcNAQkQ
# Ai8xgakwgaYwgaMwgaAEILYMMyVNpOPwlXeJODleel7gJIfrTXjdn5f2jk0GAwyo
# MHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVzdGFtcGlu
# ZyBDQSAyMDIwAhMzAAAAVn6PnVgIjulgAAAAAABWMIIDXgYLKoZIhvcNAQkQAhIx
# ggNNMIIDSaGCA0UwggNBMIICKQIBATCCAQmhgeGkgd4wgdsxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVy
# aWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpBNTAwLTA1
# RTAtRDk0NzE1MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZSBTdGFt
# cGluZyBBdXRob3JpdHmiIwoBATAHBgUrDgMCGgMVAP9z9ykVKpBZgF5eCDJEnZlu
# 9gQRoGcwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVzdGFt
# cGluZyBDQSAyMDIwMA0GCSqGSIb3DQEBCwUAAgUA7Vp7ODAiGA8yMDI2MDMxMDEx
# MTI1NloYDzIwMjYwMzExMTExMjU2WjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDt
# Wns4AgEAMAcCAQACAgN/MAcCAQACAhAsMAoCBQDtW8y4AgEAMDYGCisGAQQBhFkK
# BAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJ
# KoZIhvcNAQELBQADggEBAIXMhNsEUVrIibC1wbkF+snJuV4HsS9DpI2JPZbGpU8T
# fUQ02Yo6BjvoBpG1l0owFygaCTquJw8kDVwRuRlPsb7CJ2zK1FQvJiMAD5RPMK//
# 1FlD1JgZK1WpW5Pukvv4V2osS9zFbY8QPV1em75xz7+Ksntb4MIB9JOvlwoccdum
# cIkGo+Ch4dIY31DO0Rq6Ee0rNpb/odKL6oh3DLwsJ/B/DO1gzmdJTtT1fjKlVtwK
# dUo0j8N6+S0LbLt5RUZHPLF1B4Pe2N0opKX1jLEJWA2IvT6lQUDQceMlA466Cme5
# oRTkD+ptIt6vwv7P7ucC1R+qiVjRoUFzDr2eRyrPRzkwDQYJKoZIhvcNAQEBBQAE
# ggIARPkFEymMX+YYUkVo2WyCZWMiyeCfKP2slx+Xwi/QOZldd+59byqjpd4hFt72
# cqOhNXvNEPJBWGM7dS6XvS/UvYQTczugUb++BkodVYWa6QtagL4qwa2sY/ZZRVLh
# Y9JCawyWw91b2NXZ/QfP7000yQNarh6XvhsWh6nFNQuvoH5YREtsdIZibfcuM7Pj
# 7MzRG02/TXv5e2CaWSqSeqUPtB3cFjIErSxV1Rf2scKGNOrqmKtR/osa9HY3otOl
# C0xRfigJ+nxph0oNOaq09JNAzkLiwwvdjH3XdOSSf1rrINTqtQFsmIZwP2Pose+t
# 3zXReG8aeFXVnaQRiEuS1E8IeCoZSiozbWvF4zvmQ8/8YG75SEKTls+i218EIQDS
# x7B1P6KsBGDbI/85byPoqtYI4IB0xrXFVxRRKM07AaMNdxGOoM/uxI8CnziAB8Xg
# bKaR7qGcY33a8AaescXeClDwvVjhxQlRj4VsCPZI4UrCGQTucpZl6WdZPTZDwSi2
# SvhQvpIlfWAbwUvfrSo4rXV2zW/CDm7jinhKp+8hiLnzENvAmNu5tEVTkCHM3DAz
# RGI5RPlf6oC8HEodbZ1i6RvcZ9QQo6o2XVFDX/aFDLlwjzW0ukOl3qgX1Q/SeJ4Z
# 4wL6yryMdQJ2kLwEH+d+UZxUETRbE/7iEOM4WFcGuEb8rPs=
# SIG # End signature block
