# Install AMD driver-only from C:\AMD extracted files
$ErrorActionPreference = 'Stop'
$amdDir = "C:\AMD"

Write-Host "=== Installing Pure AMD Driver (no Adrenalin) ==="

# Find display driver INF
Write-Host "Searching for display driver INF..."
$infFiles = Get-ChildItem $amdDir -Recurse -Filter "*.inf" -ErrorAction SilentlyContinue
Write-Host ("  Found " + $infFiles.Count + " INF files")

# AMD display driver INF typically starts with "u" followed by digits
$displayInf = $infFiles | Where-Object { $_.Name -match "^[uc]\d{7,}" -and $_.FullName -match "Display|WT6A_INF" } | Select-Object -First 1

if (-not $displayInf) {
    # Fallback: find any INF with AMD in content
    $displayInf = $infFiles | Where-Object {
        (Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue) -match "AMD.*Graphics|Radeon.*Graphics|ATI.*Technologies"
    } | Select-Object -First 1
}

if (-not $displayInf) {
    Write-Host "ERROR: Cannot find AMD display INF"
    Write-Host "Listing all INF files:"
    $infFiles | Select-Object -First 20 | ForEach-Object { Write-Host ("  " + $_.FullName) }

    Write-Host ""
    Write-Host "Fallback: Opening manual installer..."
    $installer = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "whql-amd-*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($installer) {
        Write-Host ("Running: " + $installer.FullName)
        Write-Host "Select 'Driver Only' during installation"
        Start-Process -FilePath $installer.FullName
    }
    exit 1
}

Write-Host ("INF: " + $displayInf.FullName)

# Install driver
Write-Host ""
Write-Host "Installing driver via pnputil..."
$result = pnputil /add-driver $displayInf.FullName /install 2>&1
Write-Host $result

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== SUCCESS ==="
    Write-Host "Pure AMD 26.5.2 driver installed to Driver Store"
    Write-Host ""
    Write-Host "After reboot:"
    Write-Host "  - New driver auto-activates"
    Write-Host "  - No Adrenalin control panel"
    Write-Host "  - RadeonSoftware.exe will NOT auto-start"
} else {
    Write-Host ""
    Write-Host "=== pnputil may have failed ==="
    Write-Host "Alternative: run the installer manually and select 'Driver Only'"
    $installer = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "whql-amd-*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($installer) {
        Start-Process -FilePath $installer.FullName
    }
}
