# Copyright (c) Mondoo, Inc.
# SPDX-License-Identifier: BUSL-1.1

# This script verifies the cnspec version installed on the system
# against an expected version provided as a parameter.

param(
    [string]$ExpectedVersion,
    [string]$BinaryBaseName = "cnspec" # Default to "cnspec" if not provided
)

# Manual check to validate parameter, this is instead of setting the parameter as mandatory.
# otherwise the script will hang waiting for input in GitHub Actions.
# The GitHub Actions workflow will pass this value.
# $expectedVersion is now from the param() block, not ${{ steps.version.outputs.version }} directly.

if ([string]::IsNullOrWhiteSpace($ExpectedVersion)) {
    Write-Host "Error: The -ExpectedVersion parameter is mandatory and was not provided or was empty." -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    exit 1
}

# --- Construct cnspecPath using the BinaryBaseName parameter ---
# Define the base path to the Mondoo installation
$mondooBasePath = "C:\Program Files\Mondoo"

# Append .exe to the binary base name to get the full executable name
$executableName = "$BinaryBaseName.exe"

# Construct the full path to the executable
$cnspecPath = Join-Path -Path $mondooBasePath -ChildPath $executableName -ErrorAction SilentlyContinue

# --- Check if $executableName exists BEFORE execution ---
if (-not (Test-Path $cnspecPath -PathType Leaf)) {
    Write-Host "Error: '$executableName' not found at '$cnspecPath'. Please ensure Mondoo is installed correctly." -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    exit 1
}

# --- Execute $executableName with explicit error handling and capture full output ---
$cnspecFullOutput = ""
$exitCode = -1 # Initialize with a non-zero value

try {
    # Capture all output (stdout + stderr) into $cnspecRawLines (array of lines).
    $cnspecRawLines = & $cnspecPath version --auto-update=false 2>&1
    $cnspecFullOutput = ($cnspecRawLines | Out-String).Trim() # For displaying full output in error messages

    $exitCode = $LASTEXITCODE

    # Check the exit code of $executableName immediately
    if ($exitCode -ne 0) {
        Write-Host "'$executableName' execution failed with exit code: $exitCode" -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
        Write-Host "'$executableName' full output (stdout + stderr):`n$cnspecFullOutput" -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
        exit 1 # Exit with error immediately
    }

} catch {
    # For unexpected PowerShell errors
    Write-Host "An unexpected PowerShell error occurred during '$executableName' execution:" -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    Write-Host $_.Exception.Message -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    Write-Host $_.ScriptStackTrace -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    Write-Host "$executableName output captured so far: $cnspecFullOutput" -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    exit 1
}

# --- Extract the actual version line by processing lines individually ---
# We need to escape $BinaryBaseName as it might contain characters that have special meaning in regex.
$escapedBinaryBaseName = [regex]::Escape($BinaryBaseName)
$versionPattern = "^\s*$escapedBinaryBaseName\s+\d+\.\d+\.\d+.*$"
$versionMatch = $cnspecRawLines | Select-String -Pattern $versionPattern 

# Get the matched line
if ($versionMatch) {
    $versionLine = $versionMatch[0].Line.Trim()
} else {
    $versionLine = "" # Set to empty if no match found
}

# --- Validate that a version line was actually found ---
if ([string]::IsNullOrWhiteSpace($versionLine)) {
    Write-Host "Error: Could not extract a valid '$executableName' X.Y.Z' version line from the output." -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    Write-Host "Full $executableName output was:`n$cnspecFullOutput" -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    Write-Host "$executableName exited with code: $exitCode" -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    exit 1
}

# --- More precise version matching and detailed logging ---
if ($versionLine -notlike "*$ExpectedVersion*") {
    # Combine error messages into a single output for less redundancy
    Write-Host "Version Mismatch: Expected '$ExpectedVersion' but found '$($versionLine)'.`n" `
               "Full $executableName output (for context):`n$cnspecFullOutput`n" `
               "$executableName exit code: $exitCode" -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    exit 1
} else {
    Write-Host "$executableName version check successful."
    Write-Host "Expected: '$ExpectedVersion', Found: '$versionLine'"
    Write-Host "$executableName exited with code: $exitCode"
}

# If we reached here, everything is successful. Script will naturally exit with 0.