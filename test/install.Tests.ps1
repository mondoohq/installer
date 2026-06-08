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
