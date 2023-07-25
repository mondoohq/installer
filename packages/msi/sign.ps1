param (
    [string]$Certificate = $(throw "-Certificate is required."),
    [string]$Executable = $(throw "-Executable is required."),
    [string]$Password = $(throw "-Password is required."),
    [string]$ProgramName = $(throw "-ProgramName is required.")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

& 'C:\Program Files (x86)\Windows Kits\10\bin\10.0.20348.0\x64\signtool.exe' sign /d $ProgramName /f $Certificate /p $Password `
    /fd sha256 /tr http://timestamp.digicert.com /td sha256 /v `
    $Executable
