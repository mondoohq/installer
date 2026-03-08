#!/usr/bin/env pwsh
# Copyright Mondoo, Inc. 2026, 2025, 0
# SPDX-License-Identifier: BUSL-1.1

$fc = $host.UI.RawUI.ForegroundColor
$host.UI.RawUI.ForegroundColor = "red"
Write-Output "The mondoo command is now cnspec, the cloud-native specification & security scanner. Please call the cnspec binary directly. Support for invoking cnspec by calling mondoo will be removed in a future version."
$host.UI.RawUI.ForegroundColor = $fc
cnspec $args

