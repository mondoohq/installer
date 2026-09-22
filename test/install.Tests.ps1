# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# Pester v5 tests for install.ps1.
#
# Focus: the Mondoo updater scheduled-task argument builder. The whole command is
# wrapped in `powershell.exe ... -Command "&{ ... }"`, so any value spliced into the
# payload must use single quotes (or none). A single unescaped double quote inside the
# payload terminates the outer -Command string when the scheduled task is parsed,
# truncating the &{ ... } block and silently breaking the updater. That is exactly what
# a double-quoted -IdDetector value did, so these tests guard the whole class of bug.

BeforeAll {
    $installPs1 = (Resolve-Path (Join-Path $PSScriptRoot '..' 'install.ps1')).Path
    $src = Get-Content -Raw -LiteralPath $installPs1

    # install.ps1 has '#Requires -RunAsAdministrator', so it cannot be dot-sourced on a
    # CI runner. Instead, locate the builder via the AST and define only that function.
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($src, [ref]$null, [ref]$null)
    $fnAst = $ast.Find(
        {
            param($node)
            ($node -is [System.Management.Automation.Language.FunctionDefinitionAst]) -and
            ($node.Name -eq 'Get-MondooUpdaterTaskArgument')
        }, $true)

    if (-not $fnAst) {
        throw "Get-MondooUpdaterTaskArgument was not found in install.ps1. The updater-task " +
        "argument must be built by a standalone, testable function so its quoting stays covered."
    }

    . ([scriptblock]::Create($fnAst.Extent.Text))
}

Describe 'Get-MondooUpdaterTaskArgument' {

    It 'wraps the -Command payload in exactly one pair of double quotes when -IdDetector is set' {
        $arg = Get-MondooUpdaterTaskArgument -Product 'mondoo' -Path 'C:\Program Files\Mondoo\' `
            -Service 'enable' -IdDetector @('windows-ad-sid', 'hostname') `
            -UpdateTask 'enable' -Time '12:00' -Interval '3'

        # The only double quotes in the whole argument are the pair that wraps -Command "...".
        # The original bug double-quoted the -IdDetector value, adding interior quotes that
        # truncated the -Command string and broke the task.
        ($arg.ToCharArray() | Where-Object { $_ -eq '"' }).Count |
            Should -Be 2 -Because 'a double quote inside the -Command payload silently breaks the scheduled task'

        $arg | Should -Match "-IdDetector 'windows-ad-sid,hostname'"
        $arg | Should -Not -Match '-IdDetector "'
    }

    It 'produces a -Command payload that parses as valid PowerShell' {
        $arg = Get-MondooUpdaterTaskArgument -Product 'mondoo' -Path 'C:\Program Files\Mondoo\' `
            -Service 'enable' -IdDetector @('windows-ad-sid', 'hostname') `
            -UpdateTask 'enable' -Time '12:00' -Interval '3'

        ($arg -match '-Command "(.*)"\s*$') | Should -BeTrue
        $payload = $Matches[1]

        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseInput($payload, [ref]$null, [ref]$errors) | Out-Null
        $errors | Should -BeNullOrEmpty -Because "the task's -Command payload must be valid PowerShell: $payload"
    }

    It 'never emits interior double quotes for any combination of spliced parameters' {
        $cases = @(
            @{ IdDetector = @('windows-ad-sid', 'hostname'); Annotation = 'env=prod,role=db'; Name = 'host-01'; Proxy = 'http://proxy.local:3128' }
            @{ IdDetector = @('hostname'); Annotation = ''; Name = ''; Proxy = '' }
            @{ IdDetector = @(); Annotation = 'team=sec'; Name = 'host-02'; Proxy = '' }
            @{ IdDetector = @('machine-id', 'hostname'); Annotation = ''; Name = ''; Proxy = '' }
        )
        foreach ($c in $cases) {
            $arg = Get-MondooUpdaterTaskArgument -Product 'mondoo' -Path 'C:\Program Files\Mondoo\' `
                -Service 'enable' -IdDetector $c.IdDetector -Annotation $c.Annotation -Name $c.Name `
                -Proxy $c.Proxy -UpdateTask 'enable' -Time '12:00' -Interval '3'

            ($arg.ToCharArray() | Where-Object { $_ -eq '"' }).Count |
                Should -Be 2 -Because "interior double quotes break the task (case: $($c | ConvertTo-Json -Compress))"
        }
    }

    It 'omits -IdDetector entirely when no detectors are supplied' {
        $arg = Get-MondooUpdaterTaskArgument -Product 'mondoo' -Path 'C:\Program Files\Mondoo\' `
            -Service 'enable' -UpdateTask 'enable' -Time '12:00' -Interval '3'

        $arg | Should -Not -Match '-IdDetector'
        ($arg.ToCharArray() | Where-Object { $_ -eq '"' }).Count | Should -Be 2
    }
}

Describe 'Get-MondooUpdaterTaskArgument self-update gate' {

    # The task tries `cnspec update` first and keeps the installer as the fallback.
    # These run the decision itself rather than grepping the string: the payload is
    # cut at the fallback and executed against a stub binary, so what is asserted is
    # which branch the task would actually take.
    BeforeAll {
        # Pester 5 runs It blocks in their own scope, so the helper has to be
        # defined here rather than in the Describe body to be visible to them.
        function Invoke-UpdaterGate {
        param([string] $VersionLine, [int] $UpdateExit, [switch] $NoBinary)

        $dir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $dir | Out-Null
        try {
            if (-not $NoBinary) {
                $stub = Join-Path $dir 'cnspec.exe'
                # A stub, not the real binary: the gate only reads `version` and the
                # exit status of `update`, which is exactly what is under test.
                Set-Content -Path $stub -Value @"
#!/bin/sh
if [ "`$1" = "version" ]; then echo "$VersionLine"; exit 0; fi
if [ "`$1" = "update" ]; then exit $UpdateExit; fi
"@
                if ($IsLinux -or $IsMacOS) { chmod +x $stub }
            }

            $arg = Get-MondooUpdaterTaskArgument -Product 'mondoo' `
                -Path ($dir + [IO.Path]::DirectorySeparatorChar) `
                -UpdateTask 'enable' -Time '12:00' -Interval '3'

            $payload = $arg.Substring($arg.IndexOf('&{') + 2)
            $payload = $payload.Substring(0, $payload.LastIndexOf('}"'))

            # Stop before the installer fallback: running it would hit the network.
            $gate = $payload.Substring(0, $payload.IndexOf('if (-not $updated) {'))
            return & ([scriptblock]::Create($gate + '; $updated'))
        }
            finally {
                Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
            }
        }
    }

    It 'uses cnspec update on 14 and above' {
        Invoke-UpdaterGate -VersionLine 'cnspec 14.0.0 (abc, x)' -UpdateExit 0 |
            Should -BeTrue -Because 'v14 replaces the MSI download with an in-place self-update'
    }

    It 'uses cnspec update on a 14 pre-release' {
        Invoke-UpdaterGate -VersionLine 'cnspec 14.0.0-rc.10 (abc, x)' -UpdateExit 0 |
            Should -BeTrue -Because 'the gate reads the major, so a pre-release of 14 still qualifies'
    }

    It 'falls back to the installer when cnspec update fails' {
        Invoke-UpdaterGate -VersionLine 'cnspec 14.0.0 (abc, x)' -UpdateExit 1 |
            Should -BeFalse -Because 'a failed self-update must not leave the machine un-updated'
    }

    It 'falls back to the installer on 13' {
        Invoke-UpdaterGate -VersionLine 'cnspec 13.39.0 (abc, x)' -UpdateExit 0 |
            Should -BeFalse -Because "v13's update re-runs install.ps1 with no arguments, dropping -Service and -Proxy"
    }

    It 'falls back to the installer on an older major' {
        Invoke-UpdaterGate -VersionLine 'cnspec 9.1.0 (abc, x)' -UpdateExit 0 |
            Should -BeFalse
    }

    It 'falls back to the installer when cnspec is not present' {
        Invoke-UpdaterGate -NoBinary |
            Should -BeFalse -Because 'a task that assumed the binary exists would silently do nothing'
    }

    It 'keeps the installer fallback in the payload' {
        $arg = Get-MondooUpdaterTaskArgument -Product 'mondoo' -Path 'C:\Program Files\Mondoo\' `
            -Service 'enable' -UpdateTask 'enable' -Time '12:00' -Interval '3'

        $arg | Should -Match 'install\.mondoo\.com/ps1'
        $arg | Should -Match 'Install-Mondoo'
        $arg | Should -Match '-Service enable'
    }

    It 'still wraps the payload in exactly one pair of double quotes' {
        $arg = Get-MondooUpdaterTaskArgument -Product 'mondoo' -Path 'C:\Program Files\Mondoo\' `
            -Service 'enable' -IdDetector @('hostname') `
            -UpdateTask 'enable' -Time '12:00' -Interval '3'

        ($arg.ToCharArray() | Where-Object { $_ -eq '"' }).Count |
            Should -Be 2 -Because 'the self-update gate must not introduce an interior double quote'
    }

    It 'produces a payload that parses as PowerShell' {
        $arg = Get-MondooUpdaterTaskArgument -Product 'mondoo' -Path 'C:\Program Files\Mondoo\' `
            -Service 'enable' -UpdateTask 'enable' -Time '12:00' -Interval '3'

        $payload = $arg.Substring($arg.IndexOf('&{') + 2)
        $payload = $payload.Substring(0, $payload.LastIndexOf('}"'))

        $errs = $null
        [System.Management.Automation.Language.Parser]::ParseInput($payload, [ref]$null, [ref]$errs) | Out-Null
        $errs.Count | Should -Be 0 -Because 'an unbalanced brace in the gate would break the task silently'
    }
}
