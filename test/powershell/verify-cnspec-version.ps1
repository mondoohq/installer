# This script verifies the cnspec version installed on the system
# against an expected version provided as a parameter.

param(
    [string]$ExpectedVersion
)

# Manual check to validate parameter, this is instead of setting the parameter as mandatory.
# otherwise the script will hang waiting for input in GitHub Actions.
# The GitHub Actions workflow will pass this value.
# $expectedVersion is now from the param() block, not ${{ steps.version.outputs.version }} directly.

if ([string]::IsNullOrWhiteSpace($ExpectedVersion)) {
    Write-Host "Error: The -ExpectedVersion parameter is mandatory and was not provided or was empty." -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    exit 1
}

# Define the path to cnspec.exe
$cnspecPath = "C:\Program Files\Mondoo\cnspec.exe"

# --- Check if cnspec.exe exists BEFORE execution ---
if (-not (Test-Path $cnspecPath -PathType Leaf)) {
    Write-Host "Error: cnspec.exe not found at '$cnspecPath'. Please ensure Mondoo is installed correctly." -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    exit 1
}

# --- Execute cnspec.exe with explicit error handling and capture full output ---
$cnspecFullOutput = ""
$exitCode = -1 # Initialize with a non-zero value

try {
    # Capture all output (stdout + stderr) into $cnspecRawLines (array of lines).
    $cnspecRawLines = Invoke-Expression "& `"$cnspecPath`" version 2>&1" 
    $cnspecFullOutput = ($cnspecRawLines | Out-String).Trim() # For displaying full output in error messages

    $exitCode = $LASTEXITCODE

    # Check the exit code of cnspec.exe immediately
    if ($exitCode -ne 0) {
        Write-Host "cnspec.exe execution failed with exit code: $exitCode" -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
        Write-Host "cnspec.exe full output (stdout + stderr):`n$cnspecFullOutput" -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
        exit 1 # Exit with error immediately
    }

} catch {
    # For unexpected PowerShell errors
    Write-Host "An unexpected PowerShell error occurred during cnspec.exe execution:" -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    Write-Host $_.Exception.Message -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    Write-Host $_.ScriptStackTrace -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    Write-Host "cnspec.exe output captured so far: $cnspecFullOutput" -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    exit 1
}

# --- Extract the actual version line by processing lines individually ---
$versionMatch = $cnspecRawLines | Select-String -Pattern '^\s*cnspec\s+\d+\.\d+\.\d+.*$' 

# Get the matched line
if ($versionMatch) {
    $versionLine = $versionMatch[0].Line.Trim()
} else {
    $versionLine = "" # Set to empty if no match found
}

# --- Validate that a version line was actually found ---
if ([string]::IsNullOrWhiteSpace($versionLine)) {
    Write-Host "Error: Could not extract a valid 'cnspec X.Y.Z' version line from the output." -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    Write-Host "Full cnspec.exe output was:`n$cnspecFullOutput" -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    Write-Host "cnspec.exe exited with code: $exitCode" -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    exit 1
}

# --- More precise version matching and detailed logging ---
if ($versionLine -notlike "*$ExpectedVersion*") {
    # Combine error messages into a single output for less redundancy
    Write-Host "Version Mismatch: Expected '$ExpectedVersion' but found '$($versionLine)'.`n" `
               "Full cnspec.exe output (for context):`n$cnspecFullOutput`n" `
               "cnspec.exe exit code: $exitCode" -ForegroundColor Red -ErrorAction SilentlyContinue 2>&1
    exit 1
} else {
    Write-Host "cnspec version check successful."
    Write-Host "Expected: '$ExpectedVersion', Found: '$versionLine'"
    Write-Host "cnspec.exe exited with code: $exitCode"
}

# If we reached here, everything is successful. Script will naturally exit with 0.