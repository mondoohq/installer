#!/usr/bin/env pwsh
$fc = $host.UI.RawUI.ForegroundColor
$host.UI.RawUI.ForegroundColor = "red"
Write-Output "Mondoo command is deprecated. Use cnspec instead, Mondoo's cloud-native security scanner and CLI."
$host.UI.RawUI.ForegroundColor = $fc
cnspec $args
