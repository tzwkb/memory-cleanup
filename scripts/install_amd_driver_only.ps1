# Install AMD driver WITHOUT Adrenalin control panel
# Plan A: extract + pnputil + reboot
# Plan B: manual installer with "Driver Only" option
param(
    [string]$InstallerPath = "$env:USERPROFILE\Downloads\amd-driver-26.2.2.exe",
    [switch]$Manual
)

$ErrorActionPreference = 'Stop'

Write-Host "=== AMD Driver-Only Install ==="
Write-Host "Goal: pure driver, no Adrenalin, RadeonSoftware will NOT auto-start"
Write-Host ""

if (-not (Test-Path $InstallerPath)) {
    Write-Host "ERROR: $InstallerPath not found"
    exit 1
}

# Create restore point
Write-Host "[1/3] Creating restore point..."
try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "Before AMD driver 26.2.2 install" -RestorePointType "MODIFY_SETTINGS"
    Write-Host "  OK"
} catch {
    Write-Host "  WARN: could not create restore point ($($_.Exception.Message))"
}

# Extract files
Write-Host "[2/3] Extracting driver files..."
$amdDir = "C:\AMD"
if (Test-Path $amdDir) { Remove-Item -Recurse -Force $amdDir -ErrorAction SilentlyContinue }

# AMD installer extracts to C:\AMD when you run it and cancel
# We run it hidden, wait for extraction, then kill it
$proc = Start-Process -FilePath $InstallerPath -PassThru
Start-Sleep -Seconds 5

# Wait for extraction (up to 120s)
$timeout = 120
while ($timeout -gt 0 -and -not (Test-Path "$amdDir\Packages\Drivers\Display")) {
    Start-Sleep -Seconds 2
    $timeout -= 2
}

if (Test-Path "$amdDir\Packages\Drivers\Display") {
    Write-Host "  Extracted to C:\AMD"
    # Kill the installer process (we don't want to actually install)
    $proc.Kill() | Out-Null
} else {
    Write-Host "  WARN: auto-extract failed, falling back to manual mode"
    $proc.Kill() | Out-Null
    $Manual = $true
}

if (-not $Manual) {
    # Find display driver INF
    Write-Host "[3/3] Installing driver via pnputil..."
    $infPath = Get-ChildItem "$amdDir\Packages\Drivers\Display" -Recurse -Filter "*.inf" |
        Where-Object { $_.Name -match "u039" } |
        Select-Object -First 1

    if (-not $infPath) {
        $infPath = Get-ChildItem "$amdDir\Packages\Drivers\Display" -Recurse -Filter "*.inf" |
            Select-Object -First 1
    }

    if ($infPath) {
        Write-Host "  INF: $($infPath.FullName)"
        pnputil /add-driver $infPath.FullName /install
        Write-Host ""
        Write-Host "=== Driver added to Windows Driver Store ==="
        Write-Host "After reboot: new driver auto-activates, no Adrenalin"
        Write-Host "RadeonSoftware.exe will NOT auto-start"
        Write-Host ""
        Write-Host "Reboot now to complete."
    } else {
        Write-Host "  WARN: INF not found, falling back to manual"
        $Manual = $true
    }
}

if ($Manual) {
    Write-Host ""
    Write-Host "=== Manual Install Instructions ==="
    Write-Host "1. Run: $InstallerPath"
    Write-Host "2. In installer: select 'Driver Only' (NOT Full Install)"
    Write-Host "3. Finish and reboot"
    Write-Host ""
    Write-Host "This will:"
    Write-Host "  - Install updated AMD 26.2.2 driver"
    Write-Host "  - Skip Adrenalin control panel"
    Write-Host "  - RadeonSoftware.exe will NOT run at startup"
}
