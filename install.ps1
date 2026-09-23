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
    .PARAMETER IdDetector
    (Optional) Comma-separated list of platform ID detectors to use for the local
    asset (e.g. 'hostname', 'hostname,machine-id'). Writes inventory.yml so that
    cnspec serve scans the local host with the given detectors instead of the
    default. Useful when multiple hosts share the same SMBIOS UUID (e.g. VMs
    cloned from a template that was not sysprepped /generalize).

    Each detector produces its own platform ID; all of them are sent to Mondoo
    and the asset matches on any one. Listing multiple gives belt-and-suspenders
    dedup (e.g. survive a hostname rename if machine-id is still stable).

    Valid detectors (Windows behavior shown):

      hostname      Uses the OS hostname.
                    Platform ID: //platformid.api.mondoo.app/hostname/<HOSTNAME>
                    Pros: trivially unique across cloned VMs (assuming hosts are
                          renamed after clone, which is normal).
                    Cons: changes if the host is renamed (domain join, DHCP-set
                          name, etc.) -> asset is re-created.

      machine-id    Reads SMBIOS UUID via WMI:
                      SELECT UUID FROM Win32_ComputerSystemProduct
                    Platform ID: //platformid.api.mondoo.app/machineid/<UUID>
                    Pros: stable across OS reinstalls, renames, IP changes.
                    Cons: identical across VMs cloned from a template that was
                          not sysprepped /generalize (the root cause this flag
                          works around). Does NOT filter sentinel values like
                          'Not Settable' / all-zeros.

      bios-uuid     Reads the SMBIOS System UUID (same hardware source as
                    machine-id on Windows, but filtered for sentinel values
                    such as 'Not Settable', 'To Be Filled By O.E.M.', and
                    the nil UUID 00000000-0000-0000-0000-000000000000).
                    Platform ID: //platformid.api.mondoo.app/bios-uuid/<uuid>
                    Pros: stable; safer than machine-id when firmware vendors
                          ship placeholder UUIDs.
                    Cons: same collision risk as machine-id for cloned VMs.

      windows-ad-sid Reads the AD computer object's SID for domain-joined
                    Windows hosts. Runs (under the hood):
                      (New-Object System.Security.Principal.NTAccount(
                        "$($sys.Domain)\$($env:COMPUTERNAME)$"
                      )).Translate(
                        [System.Security.Principal.SecurityIdentifier]
                      ).Value
                    where $sys = Get-CimInstance Win32_ComputerSystem.
                    Platform ID: //platformid.api.mondoo.app/windows-ad-sid/<SID>
                    Pros: unique per VM by construction -- each domain-join
                          mints a fresh AD computer object with its own SID,
                          so this works even when SMBIOS UUIDs collide across
                          VMs cloned from a non-sysprepped template.
                    Cons: only emits a platform ID on domain-joined Windows
                          hosts (returns empty on workgroup/standalone hosts
                          and on non-Windows). Re-joining the domain mints a
                          new SID -> Mondoo would create a new asset.

      serialnumber  Reads the hardware serial number from SMBIOS.
                    Platform ID: //platformid.api.mondoo.app/serialnumber/<sn>
                    Pros: unique per chassis on real hardware.
                    Cons: VMs often inherit the hypervisor host's serial (e.g.
                          OpenStack) or report a generic vendor string -> may
                          collide across guests on the same host.

      cloud-detect  Probes cloud metadata services (AWS IMDS, Azure IMDS, GCP
                    metadata, etc.) and uses the cloud-native instance ID.
                    Platform ID: cloud-specific, e.g.
                      //platformid.api.mondoo.app/runtime/aws/ec2/v1/accounts/<acct>/regions/<r>/instances/<i>
                    Pros: globally unique, ties the asset to its cloud record.
                    Cons: only works on supported cloud VMs; no effect on
                          on-prem or non-cloud Hyper-V/VMware hosts.

      aws-ecs       AWS ECS task/container identifier. Only relevant when cnspec
                    is running inside an ECS container -- not applicable to a
                    Windows Server install.

    Recommended for the duplicate-SMBIOS-UUID case:
      -IdDetector 'hostname,machine-id'
    (hostname disambiguates clones; machine-id keeps the asset stable if the
    host is later renamed.)

    For fleets of domain-joined Windows hosts cloned from a non-sysprepped
    template (the canonical SMBIOS-UUID-collision scenario), prefer:
      -IdDetector 'windows-ad-sid,hostname'
    (the AD computer SID is unique per VM by construction; hostname is a
    fallback for any host that briefly leaves the domain.)
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
    Import-Module ./install.ps1; Install-Mondoo -RegistrationToken 'INSERTKEYHERE' -IdDetector 'hostname'
#>
function Install-Mondoo {
  [CmdletBinding()]
  Param(
    [string]   $Product = 'mondoo',
    [string]   $DownloadType = 'msi',
    [string]   $Path = 'C:\Program Files\Mondoo\',
    [string]   $Version = '',
    [ValidateSet('stable', 'preview')]
    [string]   $Channel = 'stable',
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
    [string]   $IdDetector = '',
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
        [string[]]$product,
        [ValidateSet('stable', 'preview')]
        [string]$channel = 'stable'
      )
      # latest.json is the stable channel; preview.json is the pre-release
      # track. Both carry exactly one version and are the same documents the
      # install service and the self-updater resolve through.
      #
      # Passed in rather than read from the enclosing scope: this function is
      # nested inside Install-Mondoo, so $Channel would resolve at runtime, but
      # an argument makes the dependency visible -- to a reader, and to
      # PSScriptAnalyzer, which reports an enclosing parameter used only from
      # inside a nested function as unused.
      $channel_doc = 'latest.json'
      If ($channel -eq 'preview') {
        $channel_doc = 'preview.json'
      }
      $url_version = "https://releases.mondoo.com/${product}/${channel_doc}"
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

      # Build the task argument via the pure helper so the (fragile) quoting is
      # unit-tested off-Windows. See Get-MondooUpdaterTaskArgument and test/install.Tests.ps1.
      $taskArgs = @{
        Product    = $Product
        Path       = $Path
        Service    = $Service
        Annotation = $Annotation
        Name       = $Name
        IdDetector = $script:NormalizedIdDetectors
        Proxy      = $Proxy
        UpdateTask = $UpdateTask
        Time       = $Time
        Interval   = $Interval
      }
      $taskArgument = Get-MondooUpdaterTaskArgument @taskArgs
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

    # Validate -IdDetector against an allowlist before any consumer (the
    # scheduled-task command assembly in CreateAndRegisterMondooUpdaterTask
    # and the inventory.yml writer further down) can read
    # $script:NormalizedIdDetectors. Defined here, immediately after the
    # function declarations and before any other top-level statement, so a
    # reader scanning the file does not have to reason about whether the
    # variable is populated by the time those consumers run.
    #
    # Unknown detector names would either be silently ignored by cnspec or,
    # worse, enable YAML injection if the value embedded newlines / nested
    # keys. The list mirrors ids/ids.go in the mql repo; keep them in sync.
    $script:ValidIdDetectors = @(
      'hostname',
      'machine-id',
      'bios-uuid',
      'serialnumber',
      'cloud-detect',
      'aws-ecs',
      'windows-ad-sid'
    )
    $script:NormalizedIdDetectors = @()
    If (![string]::IsNullOrEmpty($IdDetector)) {
      $script:NormalizedIdDetectors = $IdDetector.Split(',') |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ }
      foreach ($d in $script:NormalizedIdDetectors) {
        if ($script:ValidIdDetectors -notcontains $d) {
          fail "Invalid -IdDetector value '$d'. Valid detectors: $($script:ValidIdDetectors -join ', ')"
        }
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
    info ("  IdDetector:        {0}" -f ($script:NormalizedIdDetectors -join ', '))
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
      $version = determine_latest -product $Product -channel $Channel
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
        }
        elseif ($output) {
          info "$output"
        }
        else {
          info "No output"
        }
      }

      # Write inventory.yml whenever -IdDetector was passed, independent of
      # whether we just ran cnspec login. Existing installs reconfigure their
      # local-scan detectors by running this script again with -IdDetector
      # alone (no -RegistrationToken); nesting this inside the login block
      # would silently skip those runs.
      If ($script:NormalizedIdDetectors.Count -gt 0) {
        # Inventory.yml lives next to mondoo.yml because cnspec serve loads
        # inventory.yml from the same directory as its --config path. The MSI
        # install path always points cnspec at C:\ProgramData\Mondoo\mondoo.yml
        # (see $login_params above), so the inventory must live in the same
        # fixed directory regardless of the binary install path ($Path).
        $inventoryPath = "C:\ProgramData\Mondoo\inventory.yml"
        # Detector names were validated against $script:ValidIdDetectors
        # earlier — safe to splice into YAML without re-escaping. Indent
        # to match the list under id_detector: in the heredoc below.
        $detectorYaml = ($script:NormalizedIdDetectors | ForEach-Object { "        - $_" }) -join "`n"
        # Deliberately omit the asset `name:` here. Setting it would override
        # the asset name in Mondoo; the asset name is instead supplied at
        # registration via --name (see $login_params above) when -Name is set.
        $inventoryYaml = @"
apiVersion: v1
kind: Inventory
metadata:
  name: mondoo-local-scan
spec:
  assets:
    - connections:
        - type: local
      id_detector:
$detectorYaml
"@
        info " * Writing $inventoryPath with id_detector: $($script:NormalizedIdDetectors -join ', ')"
        Set-Content -Path $inventoryPath -Value $inventoryYaml -Encoding ASCII -Force
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

    # Clean up stale cnspec.exe / cnquery.exe / mql.exe in C:\Windows\System32
    # left behind by historical misinstalls. Runs after the supported install
    # at C:\Program Files\Mondoo\ is in place, so the new binary is always the
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

function Get-MondooUpdaterTaskArgument {
  # Build the powershell.exe argument string for the Mondoo updater scheduled task.
  #
  # This is intentionally a pure, string-only function (no side effects, no Windows-only
  # cmdlets) so the quoting can be unit-tested off-Windows. See test/install.Tests.ps1.
  #
  # IMPORTANT: the whole payload is wrapped in -Command "...". Every value spliced into
  # that payload MUST use single quotes (or no quotes) and never an embedded double quote.
  # An unescaped double quote inside the payload terminates the outer -Command string when
  # powershell.exe parses the task argument, truncating the &{ ... } block and silently
  # breaking the updater. A double-quoted -IdDetector did exactly that.
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [string]   $Product = 'mondoo',
    [string]   $Path = 'C:\Program Files\Mondoo\',
    [string]   $Service = '',
    [string]   $Annotation = '',
    [string]   $Name = '',
    [string[]] $IdDetector = @(),
    [string]   $Proxy = '',
    [string]   $UpdateTask = '',
    [string]   $Time = '',
    [string]   $Interval = ''
  )

  # v14 can update itself: `cnspec update` stages the new release, verifies it,
  # swaps the binary in place and corrects the version Windows reports. Fetching
  # the MSI again does work the binary now does for itself, so try that first and
  # keep the installer as the fallback.
  #
  # Gated on what the installed binary reports, not on what was current when the
  # task was written. A machine installed on v13 and since upgraded starts
  # self-updating on the next run, without anyone rewriting the task.
  #
  # Below 14 the fallback is not an optimisation, it is required: v13's `cnspec
  # update` is a different command that re-runs install.ps1 with no arguments,
  # dropping -Service, -Proxy, -Annotation, -Name and -IdDetector on the way.
  #
  # Path is concatenated rather than Join-Path'd because this function is
  # unit-tested off-Windows, where Join-Path would produce a '/' separator.
  $cnspecExe = $Path.TrimEnd('\') + '\cnspec.exe'

  $command = @(
    '$cnspec = ' + "'$cnspecExe'" + ';'
    '$updated = $false;'
    'if (Test-Path $cnspec) {'
    'try {'
    '$v = & $cnspec version 2>$null | Select-Object -First 1;'
    'if ($v -match ' + "'cnspec (\d+)\.'" + ' -and [int]$Matches[1] -ge 14) {'
    '& $cnspec update 2>$null;'
    'if ($LASTEXITCODE -eq 0) { $updated = $true }'
    '}'
    '} catch { $updated = $false }'
    '}'
    'if (-not $updated) {'
    '[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;'
    '$wc = New-Object Net.Webclient;'
  )

  if (![string]::IsNullOrEmpty($Proxy)) {
    $command += '$wc.proxy = New-Object System.Net.WebProxy(' + "'$Proxy'" + ');'
  }

  $command += 'iex ($wc.DownloadString(' + "'https://install.mondoo.com/ps1'" + '));'

  # Start building the Install-Mondoo command. Quote spliced values with single quotes only.
  $installCmd = @('Install-Mondoo')
  $installCmd += "-Product $Product"
  $installCmd += "-Path '$Path'"

  if ($Service.ToLower() -eq 'enable' -and $Product.ToLower() -eq 'mondoo') {
    $installCmd += '-Service enable'
  }
  if (![string]::IsNullOrEmpty($Annotation)) {
    $installCmd += "-Annotation '$Annotation'"
  }
  if (![string]::IsNullOrEmpty($Name)) {
    $installCmd += "-Name $Name"
  }
  if ($IdDetector.Count -gt 0) {
    # Single quotes, NOT double — a double quote here terminates the outer -Command
    # string and breaks the whole task (the original bug). Values are validated against
    # an allowlist (alphanumerics/dashes) upstream, so single quotes are safe.
    $joined = $IdDetector -join ','
    $installCmd += "-IdDetector '$joined'"
  }
  if (![string]::IsNullOrEmpty($Proxy)) {
    $installCmd += "-Proxy $Proxy"
  }
  if ($UpdateTask.ToLower() -eq 'enable') {
    $installCmd += "-UpdateTask enable -Time $Time -Interval $Interval;"
  }

  $command += ($installCmd -join ' ')
  # close `if (-not $updated) {`
  $command += '}'

  # Wrap command in quotes for -Command argument
  "-NoProfile -WindowStyle Hidden -ExecutionPolicy RemoteSigned -Command `"&{ $($command -join ' ') }`""
}

# SIG # Begin signature block
# MII9RQYJKoZIhvcNAQcCoII9NjCCPTICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBGAIqUz1yWRHQy
# wBwe3zaOhbG1Zvx/3kLH2kmF+76zwqCCIeowggXMMIIDtKADAgECAhBUmNLR1FsZ
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
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggaiMIIEiqADAgECAhMzAAayq65S
# NPkDTYyqAAAABrKrMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBFT0MgQ0EgMDQwHhcNMjYwOTIyMDU1NTM2WhcNMjYwOTI1
# MDU1NTM2WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAr2YC
# UHAxoHbqBllRK4WOEHygT4M+DSAM4t64np968ILwOGwlZ0n8Lv724y6AtlNOantP
# Su1Izk9qn9TTZYYdL3oRXlMkGckA1JgD6BJLMhRYmEr5kqGageXiCOABEl0R8DPx
# GK4r6kMPFw18nQKHCJCKwI1nGKBK062g1a8cu4z/vKOPllJHZA4cIhQyZm6xzPc0
# n7TR9+3Y7if2MF5bwMW0VhD2W4NQL0WP1WVi5mpfbdloIAsVjmLoeor+f5xxfids
# CAo6ZRpDlhAAeJzIpdJC66upcuoIeL+zR4YStPl8nJITajLVU8upwu+2jg+WJV3b
# r8dfxe6rjYcPxDZrrhdK9g3qxfDN9hDURisx5uj90pn7pUyow7q3WyR5PmI/dMv1
# dgjrsa7bPtE7kx6JUmoNYvQajKFhke435EIh3oEcfqF0QNGPUYceaZN2SzUsL8JC
# S5wttBZxsf5omF1AAKcG8PFD3e9wtdzAha2+37/3cfajb98vVffQp2mxDrmBAgMB
# AAGjggHWMIIB0jAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQUSeYazyZCjFMlGgg8n6rda+ajRAUwHwYDVR0jBBgw
# FoAUmvFUd3UMhxY3RqCs3nn59H/BeOkwZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwRU9DJTIwQ0ElMjAwNC5jcmwwdAYIKwYBBQUHAQEEaDBm
# MGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Nl
# cnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIw
# MDQuY3J0MFQGA1UdIARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wDQYJ
# KoZIhvcNAQEMBQADggIBAHEYqWrJ75v2eJNCAciayU1gdnIlM11hasjKKdPOmoCY
# NOvViDDPxkuqFS2Og2HjxQ4T0r6XUgDHCaYWWvCuyhMu16wE7H0GTlLq9Ksk15o0
# NlJy6+Er0w//JJRkBKVN0d7r10Zcbb5mMbEw6V3y6DKs+9tfLuT8eFuQg4UJtsbU
# lB3HzuA1vO5h5F/cIghiuv0KMvgLMR/uKBJksbAhAMdLdh/+VBugrbyj1doKA4vZ
# naosTC/lZbBIJ6h4PUqe/EsoMMJdTFIIKxGMlcAXM2P+0QiWk5cHXc/SJk/B822+
# knKVBoyNeyfnINDqM/K0wrGDaQwx23xEaCvy3TdCgY98ZihMP3a3hOPfrA0Obwiv
# RCoGIq0tOllD9vFa95C49CSZPhb3VaBRNe+KcvamNQq91b/945CUgV9ainiYUOC+
# xwo0sYFXYxqmmeH0fpzAmWZ9nGPqckKStQS1HNHfYOyY73Gxk+HvXzGYyHZcabow
# +r4XQkNRMb63ddOzsWcebfogfO7uFu7mpXXa+CPZZpzrnCvhnnt8rL7a60FTKxPe
# P6hhq17+Fea/fr1gNm9IeYmkIEimmN6C840KZwy4UMc5g6NNcp9GORxwyVKOXYC1
# eKKkdwHP5tdhlBIck/69EdpaJgR9gK64LmopPGKyej5vdGdWPKbDZHaJjUV8mMSS
# MIIGojCCBIqgAwIBAgITMwAGsquuUjT5A02MqgAAAAayqzANBgkqhkiG9w0BAQwF
# ADBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgRU9DIENBIDA0MB4X
# DTI2MDkyMjA1NTUzNloXDTI2MDkyNTA1NTUzNlowYzELMAkGA1UEBhMCVVMxFzAV
# BgNVBAgTDk5vcnRoIENhcm9saW5hMQ0wCwYDVQQHEwRDYXJ5MRUwEwYDVQQKEwxN
# b25kb28sIEluYy4xFTATBgNVBAMTDE1vbmRvbywgSW5jLjCCAaIwDQYJKoZIhvcN
# AQEBBQADggGPADCCAYoCggGBAK9mAlBwMaB26gZZUSuFjhB8oE+DPg0gDOLeuJ6f
# evCC8DhsJWdJ/C7+9uMugLZTTmp7T0rtSM5Pap/U02WGHS96EV5TJBnJANSYA+gS
# SzIUWJhK+ZKhmoHl4gjgARJdEfAz8RiuK+pDDxcNfJ0ChwiQisCNZxigStOtoNWv
# HLuM/7yjj5ZSR2QOHCIUMmZuscz3NJ+00fft2O4n9jBeW8DFtFYQ9luDUC9Fj9Vl
# YuZqX23ZaCALFY5i6HqK/n+ccX4nbAgKOmUaQ5YQAHicyKXSQuurqXLqCHi/s0eG
# ErT5fJySE2oy1VPLqcLvto4PliVd26/HX8Xuq42HD8Q2a64XSvYN6sXwzfYQ1EYr
# Mebo/dKZ+6VMqMO6t1skeT5iP3TL9XYI67Gu2z7RO5MeiVJqDWL0GoyhYZHuN+RC
# Id6BHH6hdEDRj1GHHmmTdks1LC/CQkucLbQWcbH+aJhdQACnBvDxQ93vcLXcwIWt
# vt+/93H2o2/fL1X30KdpsQ65gQIDAQABo4IB1jCCAdIwDAYDVR0TAQH/BAIwADAO
# BgNVHQ8BAf8EBAMCB4AwPQYDVR0lBDYwNAYKKwYBBAGCN2EBAAYIKwYBBQUHAwMG
# HCsGAQQBgjdhgqndkVaCp5bkUoGRmP1vg9zbqyowHQYDVR0OBBYEFEnmGs8mQoxT
# JRoIPJ+q3Wvmo0QFMB8GA1UdIwQYMBaAFJrxVHd1DIcWN0agrN55+fR/wXjpMGcG
# A1UdHwRgMF4wXKBaoFiGVmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIw
# MDQuY3JsMHQGCCsGAQUFBwEBBGgwZjBkBggrBgEFBQcwAoZYaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlm
# aWVkJTIwQ1MlMjBFT0MlMjBDQSUyMDA0LmNydDBUBgNVHSAETTBLMEkGBFUdIAAw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMA0GCSqGSIb3DQEBDAUAA4ICAQBxGKlqye+b9niT
# QgHImslNYHZyJTNdYWrIyinTzpqAmDTr1Ygwz8ZLqhUtjoNh48UOE9K+l1IAxwmm
# FlrwrsoTLtesBOx9Bk5S6vSrJNeaNDZScuvhK9MP/ySUZASlTdHe69dGXG2+ZjGx
# MOld8ugyrPvbXy7k/HhbkIOFCbbG1JQdx87gNbzuYeRf3CIIYrr9CjL4CzEf7igS
# ZLGwIQDHS3Yf/lQboK28o9XaCgOL2Z2qLEwv5WWwSCeoeD1KnvxLKDDCXUxSCCsR
# jJXAFzNj/tEIlpOXB13P0iZPwfNtvpJylQaMjXsn5yDQ6jPytMKxg2kMMdt8RGgr
# 8t03QoGPfGYoTD92t4Tj36wNDm8Ir0QqBiKtLTpZQ/bxWveQuPQkmT4W91WgUTXv
# inL2pjUKvdW//eOQlIFfWop4mFDgvscKNLGBV2Mappnh9H6cwJlmfZxj6nJCkrUE
# tRzR32DsmO9xsZPh718xmMh2XGm6MPq+F0JDUTG+t3XTs7FnHm36IHzu7hbu5qV1
# 2vgj2Wac65wr4Z57fKy+2utBUysT3j+oYate/hXmv369YDZvSHmJpCBIppjegvON
# CmcMuFDHOYOjTXKfRjkccMlSjl2AtXiipHcBz+bXYZQSHJP+vRHaWiYEfYCuuC5q
# KTxisno+b3RnVjymw2R2iY1FfJjEkjCCBygwggUQoAMCAQICEzMAAAAXJ0UJC4uH
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
# DT2uhJ04ji+tHD6n58vhavFIrmcxghqxMIIarQIBATBxMFoxCzAJBgNVBAYTAlVT
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jv
# c29mdCBJRCBWZXJpZmllZCBDUyBFT0MgQ0EgMDQCEzMABrKrrlI0+QNNjKoAAAAG
# sqswDQYJYIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQgK0xZJGo9zvNZllpmAhk/
# qKXTZw39WQrU/eIMQkYyYRUwDQYJKoZIhvcNAQEBBQAEggGAh+BtASqc9K7mlkjl
# BQykMAbVcU/SGx+U4MS0fO2EQNEBzmNk3emJz2TivTDe51sx2iU4SiVBIxJxOmSm
# F0zb7GAFsZTySp+0ms5p0p/kW8xZeU+ixGc/O6WPGDjpinXtduZtGwF5v/XteOCY
# nec6EG31ojmdKSg78SV8TbqJa+wftLVdstHVWaMv98fbmPidiZO7f5MQ/h0rgdn0
# tdFEkJbecYY1uQuPujJ5d9zP2Ykei9tkcZXw7SJlb9DTJusaBrpcVlrX8lj5HQDI
# nA6Im/oyopLysQipQ2IFeTimMvu2QtX2BtGyFOp6W4sxHE1XwBTvls37T3IX1D3f
# DcPP6N3vKdlJZag5swLhgr0k8gTNTvpFlv6iVUr76JEgLJFE+KLY7FAciRWJYGTQ
# Mgw8YjLa7wEmD9r2/Q6IsWuAJEGztU7JIfEj1Mx+W55wjXp/uzNfPzK1bUzasKwm
# +FvHDZ4tLSPCoYd1apwAXW8xOGyu7oXGJTtrnt7poz4HWVkEoYIYMTCCGC0GCisG
# AQQBgjcDAwExghgdMIIYGQYJKoZIhvcNAQcCoIIYCjCCGAYCAQMxDzANBglghkgB
# ZQMEAgIFADCCAXIGCyqGSIb3DQEJEAEEoIIBYQSCAV0wggFZAgEBBgorBgEEAYRZ
# CgMBMEEwDQYJYIZIAWUDBAICBQAEMA4T9HdHoiNBHZZ4tgdqjxw23JJQjDyNGyvx
# tMI20T7WDWjwl1cZKgqiMB9jhezREAIGaqlLHQjbGBMyMDI2MDkyMzA5MjUyMi4y
# MjNaMASAAgH0oIHhpIHeMIHbMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
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
# GHumaABdWzCCB5cwggV/oAMCAQICEzMAAABYZc3rP6HX/NIAAAAAAFgwDQYJKoZI
# hvcNAQEMBQAwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1w
# aW5nIENBIDIwMjAwHhcNMjUxMDIzMjA0NjU1WhcNMjYxMDIyMjA0NjU1WjCB2zEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWlj
# cm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1Mg
# RVNOOjdBMDAtMDVFMC1EOTQ3MTUwMwYDVQQDEyxNaWNyb3NvZnQgUHVibGljIFJT
# QSBUaW1lIFN0YW1waW5nIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAJ14NKR2kOz1QJZZ/h2WayRXC6Cm3pIVtci/kDQVIBRVLI2SCmqq
# jeKCCbCTN6bNKyTUju53QjUbmQ19loLq9wJO+3l65aAV6mZjumVV3gzUQi5XVuAN
# PzX48ye115HRIY6/NYIVxKUe8wvsG2jTfrD0scywGQXomwxT+18LOcF9GbSLDdWt
# vl6uW71qd5ETMrcLJE47p0YHi2S/7Qadt+yVXUTxQEPY2ESqQqlAaP79cYwS0Qld
# z2pSo5xn29zDeFO41cqonxR0oXJ1uQhEUaAZlGurMoA8xUq/Ht4Pd0zzSxVIr1BN
# Bpi321+XHg9RrdRXGesfyS1QE85OfgVh2zMcCSFZFT06kkjI0OikynXJ6t6R9HOA
# BSaf4Jb3KatFPX82SIyRhr3aYrIZUZe+0ULVIUo8R7wp9ywv8akEMDh0kA7BoejV
# 9g9EX7EshLUwAcgGnvtsNRwckw03JpUzSxLkC3go9YDQXSFo9FjmMg7Y40P/Ik1m
# Onstb2/ah5YyI+R4CJ3U+T/TGJNlYNnu4SlGTQTWwP4bIAbLqGfiF/PVr4xDfWmx
# fdUuDiVbop5irCzvzC255e4pLg9HTeqANGHsMg0J3LNdrDPRzrbu9kAP02ZXn71v
# K/cbTFwGKEJXBo7JPFuFHO3H6lamyD43aHPGcQcy3F3Fcj+KeXMi8L5DAgMBAAGj
# ggHLMIIBxzAdBgNVHQ4EFgQUco1NxXq+FcVyfoYz3ESZ8Z0SCbAwHwYDVR0jBBgw
# FoAUa2koOjUvSGNAz3vYr0npPtk92yEwbAYDVR0fBGUwYzBhoF+gXYZbaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwUHVibGlj
# JTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0ElMjAyMDIwLmNybDB5BggrBgEFBQcB
# AQRtMGswaQYIKwYBBQUHMAKGXWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY2VydHMvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNBJTIwVGltZXN0YW1waW5n
# JTIwQ0ElMjAyMDIwLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMA4GA1UdDwEB/wQEAwIHgDBmBgNVHSAEXzBdMFEGDCsGAQQBgjdMg30B
# ATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L0RvY3MvUmVwb3NpdG9yeS5odG0wCAYGZ4EMAQQCMA0GCSqGSIb3DQEBDAUAA4IC
# AQB768SIlRdYh3F78ayUwg/HjrWz1Gyvcfi8+9ImHoYfhtFKDjHDH9OEA+rUD03m
# eR4RhE5HJ9K2gyeTaX20QbihB99a8W2Sve6NdikQzSdzbuHj2lCKR/03Fs/Dy1Tg
# hAssEsWxIBBttJMsnRnOOnOfdbV86X5CQ3JI6GK8qWnq3XkC0UB/S2qE2GX3QMzK
# Pg8tDtQ8xSZBeWJ7JgDPJbfa9TbV3RY3WxTAm1eXWruuJldtrNfOgPFJovpdt/fl
# HtHGyUCMpFoSJYYVocUIKJLKh8+5KdhhWQAHskk5iDkDlslzgPCQPEyEicp9yQzo
# Erb+fNz91dEEgC0+iVwwltuhVdtPFRiTM5L9Ettojk2Sf6Gpk6ZPEcw/KFk/KX23
# tav5P28T4l2EW86bPemuWDpKO59FXaOtQziYS/5oZNNWN+PIKur4Rv1U3HRh4daw
# pMDjNOQd+QGWavQLT6X0cyYp6x88xkcfq+nw93HGDDzDF/zcHdoq866Yde9n0HEn
# 9XzML8CIZnx+BliSfpn9RwOrl6ADlQcnJILl75Y/ID4u09hEukVPPkLLH6kzUySo
# 7AYXlilr9luBElXp9i+5Qs+4u/RYQPtJKdMlyZ2MHc1ktKL0yDVCyDZs1cjHElJu
# VrlX/GGd93ALndjqa+jdfkbi2Q2rw744noZSOXR/hhMuejGCB1MwggdPAgEBMHgw
# YTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEy
# MDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIw
# MjACEzMAAABYZc3rP6HX/NIAAAAAAFgwDQYJYIZIAWUDBAICBQCgggSsMBEGCyqG
# SIb3DQEJEAIPMQIFADAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZI
# hvcNAQkFMQ8XDTI2MDkyMzA5MjUyMlowPwYJKoZIhvcNAQkEMTIEMLKdEgS/gADd
# nwpx8Oh1uzD2XOLrbVmWqORY+u9TMjNz0KNB36ZIzC/6vtGXlO3PEzCBuQYLKoZI
# hvcNAQkQAi8xgakwgaYwgaMwgaAEIMUiVLuyB9D7ACjVxZtbP5Y3r1UF2znyFutq
# f3X1ouhxMHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVz
# dGFtcGluZyBDQSAyMDIwAhMzAAAAWGXN6z+h1/zSAAAAAABYMIIDXgYLKoZIhvcN
# AQkQAhIxggNNMIIDSaGCA0UwggNBMIICKQIBATCCAQmhgeGkgd4wgdsxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29m
# dCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo3
# QTAwLTA1RTAtRDk0NzE1MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGlt
# ZSBTdGFtcGluZyBBdXRob3JpdHmiIwoBATAHBgUrDgMCGgMVAJ1keRvbp6twXY7r
# a8J1lR9RK8RcoGcwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRp
# bWVzdGFtcGluZyBDQSAyMDIwMA0GCSqGSIb3DQEBCwUAAgUA7l2s0DAiGA8yMDI2
# MDkyMzAxNDEzNloYDzIwMjYwOTI0MDE0MTM2WjB0MDoGCisGAQQBhFkKBAExLDAq
# MAoCBQDuXazQAgEAMAcCAQACAixLMAcCAQACAhOKMAoCBQDuXv5QAgEAMDYGCisG
# AQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMB
# hqAwDQYJKoZIhvcNAQELBQADggEBADkl+t4YsMhXSmQJ19Icvy9fcdhm4rhMTGsP
# FycRRpmg9LSxPIW2hPGyNjialrIyrn23IBR5vUgsS1GpoRbo0cxsNmOZjHlYrxjq
# AaLjnPbvlnVXQuBdNHKXm8ILvoQhfUliQtuI7l8nsOiTZFdmPmTSM/PeR64iMGMD
# rke34NrFZcoLD0yup8rxSkMp7yt0v68geaZWEWfIcCjemQINrWKsYgQsfCf6FkWk
# H213OyUZRECq6DUpgtlpmjQoB02l0OY8XFJ4kKyy+H//ZzAmpw3zHFBDjOm/6k4h
# u2WAZW75GJNatZ7+b6AzRrfLGwu9BZYUyxKrFZn5rDuFtYepHjwwDQYJKoZIhvcN
# AQEBBQAEggIAGZjAsvuSh29ZfByndMefka4gu2BFUY3ltcjcncVa5ZZgZaQCoL7q
# hLrZlZV271CNscIwMk/PBAoQJiCu9LfODe51YSOX/lx/M0wS4LsCH0HyagT95xJN
# qnBEQ6Ejsnl6NTIz833V8eTFRGTZVisPbDirEPGo+U+GKbVV0sE9j3I630bNQtjK
# vtKedr3kq7Upy2K4QyrzFY+6Z0R4JH8TRFZ1puLJxoFs6/sQCYoq6Dd69cnkpEyv
# lK53OPJaGxG6EX4BaZxZY5QQO8KW12B7HyGWdFOfI9RQLp63jDCxjIfe9IST8+uA
# cEGYNIABiZF+F5wxz0RBTueX7KJvaoAI2tpE/CxaqgfoR4ZCwHyvrORUPv0RH7si
# zBPFBcyUYz6S9gzI1+X6xut1FaA+SyfgdGl/RCw13YMj6Y8Svl/3+ccOf9poc5WB
# t83oh5fWy4Qt1BYRbjXi82kAPAss1xmrqyhcQD1HA6d+Qj/mvwfaJQbubzkv1Dyg
# ThgSorAeGr61a44TcvK7PBK5/9n3CtrTqmI5/MD6IPQXUfhCPzSNxb/N9ezZ07ov
# UKJINVEEaKOBnkXYnpSbNGJ/WiHX37JQZVstPGKDGpvMx+83Tvh51SDsnFYKXycs
# s5DOi1LnjWpVcektOt1A4Mg9Uon4XBNju3A5Eos4scmd4eDmjoJPoIM=
# SIG # End signature block
