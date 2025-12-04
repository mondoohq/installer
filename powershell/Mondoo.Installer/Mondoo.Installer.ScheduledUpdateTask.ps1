# Copyright (c) Mondoo, Inc.
# SPDX-License-Identifier: BUSL-1.1
#Requires -RunAsAdministrator
param(
    [string] $Product    = 'mondoo',
    [string] $Path       = 'C:\Program Files\Mondoo\',
    [string] $Time       = '12:00',    # Time of day the task runs
    [int]    $Interval   = 1,          # Run every N days
    [string] $Proxy      = '',         # Optional: http://1.1.1.1:3128
    [string] $Service    = 'enable',   # Whether to pass -Service enable
    [string] $Annotation = '',         # Optional mondoo annotations
    [string] $Name       = '',         # Optional asset name
    [string] $TaskName   = $null,      # Optional override
    [string] $TaskPath   = $null       # Optional override (folder under \)
)

if (-not $TaskName) {
    $TaskName = "${Product}Updater"    # e.g. mondooUpdater
}
if (-not $TaskPath) {
    $TaskPath = $Product               # e.g. \mondoo
}

function NewScheduledTaskFolder {
    param(
        [string] $TaskPath
    )

    $ErrorActionPreference = "Stop"
    $scheduleObject = New-Object -ComObject schedule.service
    $scheduleObject.Connect()
    $rootFolder = $scheduleObject.GetFolder("\")
    try {
        $null = $scheduleObject.GetFolder($TaskPath)
    }
    catch {
        $null = $rootFolder.CreateFolder($TaskPath)
    }
    finally {
        $ErrorActionPreference = "Continue"
    }
}

function Create-MondooUpdateScheduledTask {
    param(
        [string] $TaskName,
        [string] $TaskPath
    )

    Write-Host " * Creating Mondoo update task '$TaskName' in '\$TaskPath'"

    NewScheduledTaskFolder -TaskPath $TaskPath

    # Build the command that the scheduled task will execute
    $command = @(
        '[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;'
        '$wc = New-Object Net.Webclient;'
    )

    if (-not [string]::IsNullOrEmpty($Proxy)) {
        $command += '$wc.proxy = New-Object System.Net.WebProxy(' + "'$Proxy'" + ');'
    }

    $command += 'iex ($wc.DownloadString(' + "'https://install.mondoo.com/ps1'" + '));'

    # Build the Install-Mondoo command (same logic as in the original script)
    $installCmd = @("Install-Mondoo")
    $installCmd += "-Product $Product"
    $installCmd += "-Path '$Path'"

    if ($Service.ToLower() -eq 'enable' -and $Product.ToLower() -eq 'mondoo') {
        $installCmd += "-Service enable"
    }
    if (-not [string]::IsNullOrEmpty($Annotation)) {
        $installCmd += "-Annotation '$Annotation'"
    }
    if (-not [string]::IsNullOrEmpty($Name)) {
        $installCmd += "-Name $Name"
    }
    if (-not [string]::IsNullOrEmpty($Proxy)) {
        $installCmd += "-Proxy $Proxy"
    }

    # Always create the task as an update task
    $installCmd += "-UpdateTask enable -Time $Time -Interval $Interval;"

    $command += ($installCmd -join ' ')

    # Wrap everything into a single -Command argument for PowerShell.exe
    $taskArgument = "-NoProfile -WindowStyle Hidden -ExecutionPolicy RemoteSigned -Command `"&{ $($command -join ' ') }`""

    Write-Host " * Scheduled Task argument:"
    Write-Host "   $taskArgument"
    Write-Host ""

    # Define the scheduled task pieces
    $action    = New-ScheduledTaskAction  -Execute 'Powershell.exe' -Argument $taskArgument
    $trigger   = New-ScheduledTaskTrigger -Daily -DaysInterval $Interval -At $Time
    $principal = New-ScheduledTaskPrincipal -GroupId "NT AUTHORITY\SYSTEM" -RunLevel Highest
    $settings  = New-ScheduledTaskSettingsSet -Compatibility Win8

    Register-ScheduledTask -Action $action -Settings $settings -Trigger $trigger `
        -TaskName $TaskName -Description "$Product Updater Task" -TaskPath $TaskPath `
        -Principal $principal

    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Write-Host "* $Product Updater Task '$TaskName' installed successfully." -ForegroundColor DarkGreen
    }
    else {
        Write-Error "Installation of $Product Updater Task '$TaskName' failed."
    }
}

# Remove an existing task with the same name (if present)
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host " * Existing task '$TaskName' found. Removing it first..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

Create-MondooUpdateScheduledTask -TaskName $TaskName -TaskPath $TaskPath
