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

  # Start building the command string
  $command = @(
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

  # Wrap command in quotes for -Command argument
  "-NoProfile -WindowStyle Hidden -ExecutionPolicy RemoteSigned -Command `"&{ $($command -join ' ') }`""
}

# SIG # Begin signature block
# MII9RQYJKoZIhvcNAQcCoII9NjCCPTICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDO598nDoVY5zgU
# qceUnyMiC/n+Z2JC5SBnzL9bTl8Rc6CCIeowggXMMIIDtKADAgECAhBUmNLR1FsZ
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
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggaiMIIEiqADAgECAhMzAAHClhSJ
# bgKckmuWAAAAAcKWMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBFT0MgQ0EgMDMwHhcNMjYwNjA3MDMzNzQzWhcNMjYwNjEw
# MDMzNzQzWjBjMQswCQYDVQQGEwJVUzEXMBUGA1UECBMOTm9ydGggQ2Fyb2xpbmEx
# DTALBgNVBAcTBENhcnkxFTATBgNVBAoTDE1vbmRvbywgSW5jLjEVMBMGA1UEAxMM
# TW9uZG9vLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA2Gs0
# 97BccDS/NQoXovM+z1lWd2PbDGQFxk6Awj+cb8d2cZTPNk5XYX4QnycyclOdNbe9
# 4JA//7dv8pfEyshyNatH7IDWqHT6aOjNKOR2yK2LGnK4jrdwaROTX5m13WLckb5B
# Ioi+vUc5vfGRln8IjYnHbwrxfAhglQly/VRQmyZG3Y2ysUHpQtP3cRsBNFGmV6CP
# py6K/GuBdskiBM9Ow1O6YKEaWNY3zNxhfto824UiexTGf/+VQJe9fT7ZwatkeLOU
# d+Qjjh2j6G5UVzd+pS615hYKS1Ok+1OSy6D+SKHZYxTpZqMKWKwFAXaxG7nJnPu1
# UYPdKmWc8Eni9+em5r3VRQ9qhJ+7pQ+L8LY/OA/L88s1vtWKEANDbyv11wZvvhi9
# Gf9z9vl7wCKkwibmIUmS8iHXUqWk/SgaFry1fzzeOCeJH8VGATllLxni2wrdNKnE
# mXff2HfWdY3eXU2Qn359bJ+edRwlvPS/hsrXJLHh1eWkHKs7C5KKpJl7UjePAgMB
# AAGjggHWMIIB0jAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUE
# NjA0BgorBgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GCqd2RVoKnluRSgZGY
# /W+D3NurKjAdBgNVHQ4EFgQU6ESUu54mNe26vzKBZmubwAgpIgYwHwYDVR0jBBgw
# FoAUa16lNMMFxWJKIVqOq3NgYtSsY4UwZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBW
# ZXJpZmllZCUyMENTJTIwRU9DJTIwQ0ElMjAwMy5jcmwwdAYIKwYBBQUHAQEEaDBm
# MGQGCCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Nl
# cnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIw
# MDMuY3J0MFQGA1UdIARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wDQYJ
# KoZIhvcNAQEMBQADggIBAKmYDMzAf6XqqdKlzl+VO6zXVIdtp+obskAuKkptiwUR
# 6HMtoRKO0ETL64nyl+o5B8vySqzHtS+2Oj26mUB9rinwJEo86CplBu425XRyiG4u
# xF4dxmlcHV4HhlgTT6t7DUWZZxCVe4nmwJdXUTBv81PWJbqecV0TrFhvDk2RLd79
# oBLh3QyhFHL+duOl60OtsU9Jq4oG/trzRfcqEM+94FhG87tfV4kJxPAIbO4kyyn0
# 5dCw3BUwmXb/GCU0D1GBtB/HRp0uUagLLfjq0txDO69fUPx3L3puZFIGndd9pJmn
# PYXRYhsOUXqS2W33LYskSp7vt46dtB4GAzCy0b7nWwmvInbI1Dm0R8BN2msyfrPZ
# WCndHj5IAt7KCfIgE+6wR4tUBVn0DIU0RXQ4pHX9qbDcOyG38FP9mtNoQP3rFWdH
# xIQYrj/pP2Um7k5v6P3PBEKkWk5H7N7d/Nksogi6I8Y26YI233CKOox4U+QdTMQt
# wVrSQuwwBTUSLwuicsj/jWlmEvpsbsT9xJxNezatJyBriLpEc9DDOHTt4HOFvO1T
# MucrAr+D8bEKp8ocdMHChrgsVFphU0+h6Nadetc31ZDxktcIgqZ5YzZVBoZMMs7y
# JpTTbWGl4Z5dyNLkmPEcrQpsoV2jwf1GkNu87QEPOX4xmMm2iSpYtHvtT9q3p4bn
# MIIGojCCBIqgAwIBAgITMwABwpYUiW4CnJJrlgAAAAHCljANBgkqhkiG9w0BAQwF
# ADBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgRU9DIENBIDAzMB4X
# DTI2MDYwNzAzMzc0M1oXDTI2MDYxMDAzMzc0M1owYzELMAkGA1UEBhMCVVMxFzAV
# BgNVBAgTDk5vcnRoIENhcm9saW5hMQ0wCwYDVQQHEwRDYXJ5MRUwEwYDVQQKEwxN
# b25kb28sIEluYy4xFTATBgNVBAMTDE1vbmRvbywgSW5jLjCCAaIwDQYJKoZIhvcN
# AQEBBQADggGPADCCAYoCggGBANhrNPewXHA0vzUKF6LzPs9ZVndj2wxkBcZOgMI/
# nG/HdnGUzzZOV2F+EJ8nMnJTnTW3veCQP/+3b/KXxMrIcjWrR+yA1qh0+mjozSjk
# dsitixpyuI63cGkTk1+Ztd1i3JG+QSKIvr1HOb3xkZZ/CI2Jx28K8XwIYJUJcv1U
# UJsmRt2NsrFB6ULT93EbATRRplegj6cuivxrgXbJIgTPTsNTumChGljWN8zcYX7a
# PNuFInsUxn//lUCXvX0+2cGrZHizlHfkI44do+huVFc3fqUuteYWCktTpPtTksug
# /kih2WMU6WajClisBQF2sRu5yZz7tVGD3SplnPBJ4vfnpua91UUPaoSfu6UPi/C2
# PzgPy/PLNb7VihADQ28r9dcGb74YvRn/c/b5e8AipMIm5iFJkvIh11KlpP0oGha8
# tX883jgniR/FRgE5ZS8Z4tsK3TSpxJl339h31nWN3l1NkJ9+fWyfnnUcJbz0v4bK
# 1ySx4dXlpByrOwuSiqSZe1I3jwIDAQABo4IB1jCCAdIwDAYDVR0TAQH/BAIwADAO
# BgNVHQ8BAf8EBAMCB4AwPQYDVR0lBDYwNAYKKwYBBAGCN2EBAAYIKwYBBQUHAwMG
# HCsGAQQBgjdhgqndkVaCp5bkUoGRmP1vg9zbqyowHQYDVR0OBBYEFOhElLueJjXt
# ur8ygWZrm8AIKSIGMB8GA1UdIwQYMBaAFGtepTTDBcViSiFajqtzYGLUrGOFMGcG
# A1UdHwRgMF4wXKBaoFiGVmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEVPQyUyMENBJTIw
# MDMuY3JsMHQGCCsGAQUFBwEBBGgwZjBkBggrBgEFBQcwAoZYaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlm
# aWVkJTIwQ1MlMjBFT0MlMjBDQSUyMDAzLmNydDBUBgNVHSAETTBLMEkGBFUdIAAw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMA0GCSqGSIb3DQEBDAUAA4ICAQCpmAzMwH+l6qnS
# pc5flTus11SHbafqG7JALipKbYsFEehzLaESjtBEy+uJ8pfqOQfL8kqsx7Uvtjo9
# uplAfa4p8CRKPOgqZQbuNuV0cohuLsReHcZpXB1eB4ZYE0+rew1FmWcQlXuJ5sCX
# V1Ewb/NT1iW6nnFdE6xYbw5NkS3e/aAS4d0MoRRy/nbjpetDrbFPSauKBv7a80X3
# KhDPveBYRvO7X1eJCcTwCGzuJMsp9OXQsNwVMJl2/xglNA9RgbQfx0adLlGoCy34
# 6tLcQzuvX1D8dy96bmRSBp3XfaSZpz2F0WIbDlF6ktlt9y2LJEqe77eOnbQeBgMw
# stG+51sJryJ2yNQ5tEfATdprMn6z2Vgp3R4+SALeygnyIBPusEeLVAVZ9AyFNEV0
# OKR1/amw3Dsht/BT/ZrTaED96xVnR8SEGK4/6T9lJu5Ob+j9zwRCpFpOR+ze3fzZ
# LKIIuiPGNumCNt9wijqMeFPkHUzELcFa0kLsMAU1Ei8LonLI/41pZhL6bG7E/cSc
# TXs2rScga4i6RHPQwzh07eBzhbztUzLnKwK/g/GxCqfKHHTBwoa4LFRaYVNPoejW
# nXrXN9WQ8ZLXCIKmeWM2VQaGTDLO8iaU021hpeGeXcjS5JjxHK0KbKFdo8H9RpDb
# vO0BDzl+MZjJtokqWLR77U/at6eG5zCCBygwggUQoAMCAQICEzMAAAAVBT5uGY6T
# KdkAAAAAABUwDQYJKoZIhvcNAQEMBQAwYzELMAkGA1UEBhMCVVMxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjE0MDIGA1UEAxMrTWljcm9zb2Z0IElEIFZl
# cmlmaWVkIENvZGUgU2lnbmluZyBQQ0EgMjAyMTAeFw0yNjAzMjYxODExMjhaFw0z
# MTAzMjYxODExMjhaMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJpZmllZCBDUyBF
# T0MgQ0EgMDMwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDg9Ms9Aqov
# DnMePvMOe+KybhCd8+lokzYORlS3kBVXseecbyGwBcsenlm5bLtMGPjiIFLzBQF+
# ghlVV/U29q5GcdeEEBCHTTGhL2koIrLc4UrliMRcbv9mOMtR/l7/xAmv0Fx4BJHn
# 1dHt37fvrBqXmKjKfGf5DpyO/+hnV7TEreMtS19iO+bjZ/9Hnpg3PCk0e7YSbRTF
# kx97FZwRWpC4s3NepRfRXQh/WMAj7JmsYeVZohi4TF5yW2JMrJZqwHcyzJZYtD2H
# lno5ZEJkdiZcEaxHOobmwO06Z1J9c23ps9PGIhGaq1sKLEAz9Doc5rLkYWGteDrs
# cKhAp2kIc/oYlH9Ij6BkOqqgWINEkEtC8ZNG1Mak+h3o65aj0iQKmdxW7IZaHO5c
# uyoMi+KtYfXeIIg3sVIbS2EL8kUtsDGdEqNqAq/isqTi1jXqLe6iKp1ni1SPdvPW
# 9G03CTsYF68b/yuIQRwbdoBCXemMNJCS0dorCRY4b2WAAy4ng7SANcEgrBgZf535
# +QfLU5hGzrKjIpbMabauWb5FKWUKkMsPcXFkXRWO4noKPm4KWlFypqOpbJ/KONVR
# eIlxHQRegAOBzIhRB7gr9IDQ1sc2MgOgQ+xVGW4oq4HD0mfAiwiyLskZrkaQ7Joa
# nYjBNcR9RS26YxAVbcBtLitFTzCIEg5ZdQIDAQABo4IB3DCCAdgwDgYDVR0PAQH/
# BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRrXqU0wwXFYkohWo6r
# c2Bi1KxjhTBUBgNVHSAETTBLMEkGBFUdIAAwQTA/BggrBgEFBQcCARYzaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBkG
# CSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMBIGA1UdEwEB/wQIMAYBAf8CAQAwHwYD
# VR0jBBgwFoAU2UEpsA8PY2zvadf1zSmepEhqMOYwcAYDVR0fBGkwZzBloGOgYYZf
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIw
# SUQlMjBWZXJpZmllZCUyMENvZGUlMjBTaWduaW5nJTIwUENBJTIwMjAyMS5jcmww
# fQYIKwYBBQUHAQEEcTBvMG0GCCsGAQUFBzAChmFodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBD
# b2RlJTIwU2lnbmluZyUyMFBDQSUyMDIwMjEuY3J0MA0GCSqGSIb3DQEBDAUAA4IC
# AQBdbiI8zwXLX8glJEh/8Q22UMCUhWBO46Z9FPhwOR3mdlqRVLkYOon/MczUwrjD
# hx3X99SPH5PSflkGoTvnO9ZWHM5YFVYpO7NYuB+mfVSGAGZwiGOASWk0i2B7vn9n
# ElJJmoiXxugfH5YdBsrUgTt0AFNXkzmqTgk+S1Hxb1u/0HCqEHVZPk2A/6eJXYbt
# pRM5Fcz00jisUl9BRZgSebODV85bBzOveqyC3f0PnHCxRJNhMb8xP/sB/VI7pf2r
# heSV7zqUSv8vn/fIMblXeaVIlpqoq8SP9BJMjE/CoVXJxnkZQRM1Fa7kN9yztvRe
# OhxSgPgpZx/Xl/jkwyEFVJTBfBp3sTgfIc/pmqv2ehtakL2AEj78EmOPQohxJT3w
# yX+P78GA25tLpAvzj3RMMHd8z18ZuuVi+60MAzGpOASH1L8Nlr3fZRZnQO+pyye2
# DCvYmHaIfdUgYJqn7noxxGVv89+RaETh1tgCDvwNpFCSG7vl5A4ako+2fx409r9T
# WjXC7Oif1IQ5ZJzB4Rf8GvBiHYjvMmHpledp1FGRLdSRFVpC3/OKpZY6avIqZp7+
# 8pP/WQP903DdgrvAT6W4xPOBxXPa4tGksN3SuqJaiFYHSNyeBufn8iseujW4IbBS
# bHD4BPqbF3qZ+7nG9d/d/G2/Lx4kH9cCmBfmsZdSkHmukDCCB54wggWGoAMCAQIC
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
# c29mdCBJRCBWZXJpZmllZCBDUyBFT0MgQ0EgMDMCEzMAAcKWFIluApySa5YAAAAB
# wpYwDQYJYIZIAWUDBAIBBQCgXjAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAvBgkqhkiG9w0BCQQxIgQgW+wo6iJG1IXe8D4YDRWF
# DM23opmZKjf6XWmR0UvAPnIwDQYJKoZIhvcNAQEBBQAEggGANOyb/kptCOpG26q8
# Ylu8dDIj0iikJTga5dDeyZzxrpTXyJ8uN7y8iMFVB1ZOOwmf0NjR8nO5E1phWAwh
# HzUeggmmE6ctKuM6oa0KSWG//4gLj4eFsBAffYSpS3GHw/GKJeySLp0sgnIBDKNf
# qonYnp2vrpAugC4khu+IiP1/diSg47H/xtw70IhxhHQirDwntIZa6r84qNDPZ0Dy
# pEcZMS2ISnIlSo7lb/CTNUZWcHwEQBnavczKuzRCeEsfGYwN0ytHOFiifr5fqp9t
# Vyy9qho8gQ/+nOLPEB5XsX0eeRK1w8BnNzHDlg344W+L4Ry017a7Vp1DOnHwyHei
# zTvyPrlf++PywZ7FkNEudDPuJa/al0XUGLHT6stXnk4/HG57S/gIAQCPci7e0XpZ
# VqNg4TTKmHi1AdY7cL7oqniRwoIKtn9Ru3p8z0QsMUpl3eIOiGG8Hgei/buroQ9I
# CbxVIKD74K6Zm+/V0FgHIwqGAb19Ygp1iiePA4z98gx4SeFEoYIYMTCCGC0GCisG
# AQQBgjcDAwExghgdMIIYGQYJKoZIhvcNAQcCoIIYCjCCGAYCAQMxDzANBglghkgB
# ZQMEAgIFADCCAXIGCyqGSIb3DQEJEAEEoIIBYQSCAV0wggFZAgEBBgorBgEEAYRZ
# CgMBMEEwDQYJYIZIAWUDBAICBQAEMB+Ahjm6luC55567musKIvwocsL6XfcGYIJO
# iP13n7w+uoTHgORwsmeKh0+q+CxCfwIGahxW4SBTGBMyMDI2MDYwODExMzkwNC4w
# MDFaMASAAgH0oIHhpIHeMIHbMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScw
# JQYDVQQLEx5uU2hpZWxkIFRTUyBFU046QTUwMC0wNUUwLUQ5NDcxNTAzBgNVBAMT
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
# GHumaABdWzCCB5cwggV/oAMCAQICEzMAAABWfo+dWAiO6WAAAAAAAFYwDQYJKoZI
# hvcNAQEMBQAwYTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1w
# aW5nIENBIDIwMjAwHhcNMjUxMDIzMjA0NjUxWhcNMjYxMDIyMjA0NjUxWjCB2zEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWlj
# cm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1Mg
# RVNOOkE1MDAtMDVFMC1EOTQ3MTUwMwYDVQQDEyxNaWNyb3NvZnQgUHVibGljIFJT
# QSBUaW1lIFN0YW1waW5nIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBALSln5v7pdNu/3fEZW/DJ/4NEFL7y6mNlbMt7SPFNrRUrKU2aJmT
# g9wR0/C5Efka4TCYG9VYwChTcrGivXC0l4nzxkiAazwoLPT+MtuJayRJq1ekOc+A
# ZqjISD62YRL2Z1qQkuBzu42Enov58Zgu/9RK/peS4Nz5ksW/HdiFXAEcUsNQeJsQ
# elyNJ5HpfcGtXWG9sHxqaH62hZsWTsU/XjYbeCx9EQUlbnm2umTaY0v9ILX5u6oi
# Isj+qej0c002zJ1arB51f3f61tMx8fkPkDWecFKipk2SQfYVPOd/tqV+aw3yt9rj
# WPf1gTgJs26oKRHUJG4jGr1DMlA0oZsnCL4B3UJ0ttO7E4/DPpCS97TnWoT7j6jM
# LGggoHX8MEMdDvUynuxUr2wBGLNQJ5XQpfyhxmQjlb1Dao8i9dCS3tP/hg/f8p6l
# xlhaVzo2rp72f3CkToYzeDOXuscdG9poqnD4ouP4otmYXimpZSRE+wipaRUobN8M
# oOhf36I0MULz521g+DcsepYY1o8JqC3MesNRUgrWrywpct9wS0UpU1OKilMWmvHe
# 2DexKqZ/VztEmNLpjryhV61h+68ZfvYmonIrXZ005LAJ0Y73pHSk95YO5UTH5n2V
# PL1zYjdFGCc0/RI6o0ZtLjf4dKF8T4TXz2KnhW8j1xhsc2mFM+s8d6k3AgMBAAGj
# ggHLMIIBxzAdBgNVHQ4EFgQUvrYz8rurWf4eRrMi78s9R/hTSFowHwYDVR0jBBgw
# FoAUa2koOjUvSGNAz3vYr0npPtk92yEwbAYDVR0fBGUwYzBhoF+gXYZbaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwUHVibGlj
# JTIwUlNBJTIwVGltZXN0YW1waW5nJTIwQ0ElMjAyMDIwLmNybDB5BggrBgEFBQcB
# AQRtMGswaQYIKwYBBQUHMAKGXWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY2VydHMvTWljcm9zb2Z0JTIwUHVibGljJTIwUlNBJTIwVGltZXN0YW1waW5n
# JTIwQ0ElMjAyMDIwLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMA4GA1UdDwEB/wQEAwIHgDBmBgNVHSAEXzBdMFEGDCsGAQQBgjdMg30B
# ATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L0RvY3MvUmVwb3NpdG9yeS5odG0wCAYGZ4EMAQQCMA0GCSqGSIb3DQEBDAUAA4IC
# AQAOA6gFxLDtuo/y2uxYJ/0In4rfMbmXpKmee/mHvrB/4UU2xBIxmK2YLKsEf5VF
# HyghaW2RfJrGmT0CTkeGGFBFPF8oy65/GNYwkpqMYfZe7VokqHPyRQcN+eiQJsxh
# sXgQNhFksUbk69QLmXup2GjfP8LRZIh3LPIDGncVwbOg8VYcruWJ4Sz0JH7pipt5
# RX7cBO6Ynle39ZbJJpYLAugHkhgsxj2VIAr3B+U7/0Hvc+2yCJkg90rs4TiMGj/n
# ikE2H+u04n8iSpFkEnRn0wOinLuNZPCweqDyvjC5NY28cSucD6i0i+tsYytOEgVx
# xCUhJ7BbdM8VpMT/5YHo9Q8alJ5q2BHZMb8ykhyAKhVkmbpf+YSPrycbxT4bDUAR
# JOHErpQ5CUKXHVYv4Jn/5hxTmIQwY7GtebOC/trAYpd11f0/EYkeukPMWL0y0VsX
# dnVbKzqAsJ7FOFiHogtCYpwr9VixxIe0Ms6/UUq+JCiS1naTWC4YI5KI05hJAIxT
# u++Ld8Qe3p27yBdBjrFdfcZwlM6vRBisrdIDLmqYSpTYyfmk6Y1jGQxqPhjirJ6f
# dx5n7ZpdEsqdxffjN8vsuliRlGaCGSattu4w44xJ3baVK4fQXT3VSH1SQ/wLvNUc
# 4dOVBwIr6K0NzrPDxCxyIIjnfU1s23YJhs3CC7f3XVUBETGCB1MwggdPAgEBMHgw
# YTELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEy
# MDAGA1UEAxMpTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIw
# MjACEzMAAABWfo+dWAiO6WAAAAAAAFYwDQYJYIZIAWUDBAICBQCgggSsMBEGCyqG
# SIb3DQEJEAIPMQIFADAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZI
# hvcNAQkFMQ8XDTI2MDYwODExMzkwNFowPwYJKoZIhvcNAQkEMTIEMLYV9xIGWXrJ
# kMjNqnpu43ZPHY+Z1DMqxqjf+JIwlc6QyTGrkWOspqvLkG+fFn9qAjCBuQYLKoZI
# hvcNAQkQAi8xgakwgaYwgaMwgaAEILYMMyVNpOPwlXeJODleel7gJIfrTXjdn5f2
# jk0GAwyoMHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVz
# dGFtcGluZyBDQSAyMDIwAhMzAAAAVn6PnVgIjulgAAAAAABWMIIDXgYLKoZIhvcN
# AQkQAhIxggNNMIIDSaGCA0UwggNBMIICKQIBATCCAQmhgeGkgd4wgdsxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29m
# dCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpB
# NTAwLTA1RTAtRDk0NzE1MDMGA1UEAxMsTWljcm9zb2Z0IFB1YmxpYyBSU0EgVGlt
# ZSBTdGFtcGluZyBBdXRob3JpdHmiIwoBATAHBgUrDgMCGgMVAP9z9ykVKpBZgF5e
# CDJEnZlu9gQRoGcwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRp
# bWVzdGFtcGluZyBDQSAyMDIwMA0GCSqGSIb3DQEBCwUAAgUA7dC4mjAiGA8yMDI2
# MDYwODAzNDIxOFoYDzIwMjYwNjA5MDM0MjE4WjB0MDoGCisGAQQBhFkKBAExLDAq
# MAoCBQDt0LiaAgEAMAcCAQACAhtAMAcCAQACAhKMMAoCBQDt0goaAgEAMDYGCisG
# AQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMB
# hqAwDQYJKoZIhvcNAQELBQADggEBAJK/zngFuI+8YxmIwXvEHpt4ffNERKNMASLK
# lrbK5hkoAZ0DBEi/S5MRQv2xP4rpcoGlyNehjGx3zYPXU6o+7yrf8AJfvkjSjM7M
# axAFxlNlXm1VCDjtCCWoVgYjmBKdyybEQqBXkZ2Kok55VKwJs4LSPA546giRoQvv
# 2kz22WohJMsO/NGZuSD8SUn130PpB+eIfCsU8APoweHHCsl1a921ZOmwQYew5C0l
# 8JGMHHS1mOpZJ39ZYLFuMMtiMndBIK5zAkozA/HidSYSPVgG+yiYDU4814I/3TdL
# jCtlyoGq6fOljiG4dZPZn5gzdy9Iyg1bSlOnM0TOhpV4yOzWhZEwDQYJKoZIhvcN
# AQEBBQAEggIAoeUmn4fzSnpmMZ2LdVMItflIHiIx8/3Asd0iadcuR0bN8SX7euRb
# P+tn18dpoWBRbyhqFuEGZ4QZFQwHCxHMR3JRxGoo1oI3q6WGTk84YPova+ByeaD5
# bfHW7EervMg9wezc4UOAgVwBqhJLoFOW92/d8JQchcLB2IccvMIXJGTQN3H7w2i/
# IepeXepcf+ThDqVFKJuOuC+ahbh4dZCRpvAJuvLOIZO8Lky7r3KtnMLkjm7qpuaR
# nMnr+ZHgYpP1CPNY/vMHWoxR9Z79Uw+qmSZFljePf2Lw+nJPRmlnBH5w3EaWtMmA
# lwIUOo2LFiWcx74u05mSItTKeKV3oQgx+tDl1sLYGO2sj9HXi4CVq67DG9sInyMK
# dt6yixPq3fwEiCMiSOwPjicFAiWpFCHNPa+j/RIi0UnQ1yjmCUr4oWSbzIJBmzlL
# 4vX/GjTMfYKirLBW/y1o7CTEJRRrBR9xS7myf5Eh3nsqAi/QDfJUDXyVcEyJSDSm
# El8iGLancOAnJU4A5Rh47T0yvh4wyePhRjvCg/1wG423hVC6upQ+piHwChohecZH
# TiGCEfLTHMqyyxNa4Oc5170dSi3B9xAw01lhcWtD1HuMPjvGwOtk2F8fTLC+CchV
# N6lgNfjZ42tazhH5DQAaxyqTRPYPbHA7aduunRaCqPqk0bjf8FXq2pA=
# SIG # End signature block
