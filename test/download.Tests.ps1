# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# Pester v5 tests for the param blocks of download.ps1 and install.ps1.
#
# Focus: a parameter whose default is not a member of its own ValidateSet.
#
# Run as a script, PowerShell skips validation on a default the caller never
# bound, so such a parameter looks fine in CI and to anyone running the file.
# Callers that pipe the script through Invoke-Expression get the other
# behaviour: the param block becomes variable assignments in the caller's
# scope, the attribute is applied to the default, and an out-of-set default
# throws ValidationMetadataException before the body runs. Nothing downloads
# and nothing says why.
#
# That is not hypothetical: download.ps1 gained
# [ValidateSet('stable','preview')] $Channel = '' on 2026-09-14 (#796), and
# every Azure run-command cnspec scan -- which installs through
# `iex (DownloadString(...))` -- stopped downloading cnspec from that moment,
# while the scan job kept reporting success.

BeforeAll {
    $script:Scripts = @(
        (Resolve-Path (Join-Path $PSScriptRoot '..' 'download.ps1')).Path
        (Resolve-Path (Join-Path $PSScriptRoot '..' 'install.ps1')).Path
    )

    # Every (script, parameter) pair that carries a ValidateSet and a constant
    # default, flattened so each one is its own assertion.
    function Get-ValidateSetDefault {
        param([string]$Path)

        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)

        $ast.FindAll({
                param($n) $n -is [System.Management.Automation.Language.ParameterAst]
            }, $true) | ForEach-Object {
            $p = $_
            $set = $p.Attributes |
                Where-Object { $_ -is [System.Management.Automation.Language.AttributeAst] -and $_.TypeName.Name -eq 'ValidateSet' }
            if (-not $set) { return }
            if ($null -eq $p.DefaultValue) { return }
            if ($p.DefaultValue -isnot [System.Management.Automation.Language.ConstantExpressionAst] -and
                $p.DefaultValue -isnot [System.Management.Automation.Language.StringConstantExpressionAst]) { return }

            [pscustomobject]@{
                Script  = Split-Path -Leaf $Path
                Name    = $p.Name.VariablePath.UserPath
                Default = [string]$p.DefaultValue.Value
                Allowed = @($set.PositionalArguments | ForEach-Object { [string]$_.Value })
            }
        }
    }
}

Describe 'param defaults are members of their own ValidateSet' {

    It 'covers at least one parameter (the AST walk still finds them)' {
        $found = @($script:Scripts | ForEach-Object { Get-ValidateSetDefault -Path $_ })
        $found.Count | Should -BeGreaterThan 0 -Because 'a walk that silently finds nothing would pass forever'
    }

    It 'holds for every ValidateSet parameter with a constant default' {
        $bad = @(
            $script:Scripts | ForEach-Object { Get-ValidateSetDefault -Path $_ } |
                Where-Object { $_.Allowed -notcontains $_.Default }
        )

        $detail = ($bad | ForEach-Object { "$($_.Script): -$($_.Name) default '$($_.Default)' not in ($($_.Allowed -join ', '))" }) -join '; '

        $bad.Count | Should -Be 0 -Because "an out-of-set default throws under Invoke-Expression before the body runs: $detail"
    }
}

Describe 'the param block survives Invoke-Expression' {

    It 'does not throw for <_>' -ForEach @('download.ps1', 'install.ps1') {
        $path = (Resolve-Path (Join-Path $PSScriptRoot '..' $_)).Path
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$null)

        # install.ps1 wraps its params in a function; download.ps1 has a
        # top-level param block. Take whichever this file has -- the top-level
        # one is what Invoke-Expression evaluates in the caller's scope.
        $paramBlock = $ast.ParamBlock
        if (-not $paramBlock) {
            $fn = $ast.Find({
                    param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $true)
            $paramBlock = $fn.Body.ParamBlock
        }
        $paramBlock | Should -Not -BeNullOrEmpty

        # Invoke-Expression on the param block alone reproduces the failure
        # without running the body or touching the network.
        { Invoke-Expression $paramBlock.Extent.Text } | Should -Not -Throw
    }
}

Describe 'download.ps1 -Channel still gates its input' {

    BeforeAll {
        $script:DownloadPs1 = (Resolve-Path (Join-Path $PSScriptRoot '..' 'download.ps1')).Path
        $script:ChannelParam = Get-ValidateSetDefault -Path $script:DownloadPs1 |
            Where-Object { $_.Name -eq 'Channel' }
    }

    It 'still rejects a channel that is not a real release line' {
        $script:ChannelParam | Should -Not -BeNullOrEmpty
        $script:ChannelParam.Allowed | Should -Not -Contain 'bogus'
    }

    It 'still offers both real release lines' {
        $script:ChannelParam.Allowed | Should -Contain 'stable'
        $script:ChannelParam.Allowed | Should -Contain 'preview'
    }
}
