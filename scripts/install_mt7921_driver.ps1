# Install MT7921 Wi-Fi driver from CAB
param(
    [string]$CabPath = "$env:USERPROFILE\Downloads\03bdc436-daf1-497c-a744-0234ea26d14c_efad6bc8da599107040f2d17419cef69350cde11.cab"
)

$ErrorActionPreference = 'Stop'
$destDir = "C:\MT7921_Driver"

Write-Host "=== MT7921 Driver Install ==="

# Step 1: Extract CAB
Write-Host "[1/3] Extracting CAB..."
if (Test-Path $destDir) { Remove-Item -Recurse -Force $destDir }
New-Item -ItemType Directory -Path $destDir -Force | Out-Null

# Use expand.exe (Windows native, handles CAB)
$expandResult = & C:\Windows\System32\expand.exe $CabPath -F:* $destDir 2>&1
Write-Host ($expandResult -join "`n")

# Step 2: Find INF
Write-Host ""
Write-Host "[2/3] Finding driver INF..."
$infFiles = Get-ChildItem $destDir -Recurse -Filter "*.inf" | Where-Object { $_.Name -match "net|wlan|mtk|mt7921|media" }
if (-not $infFiles) {
    $infFiles = Get-ChildItem $destDir -Recurse -Filter "*.inf"
}

if (-not $infFiles) {
    Write-Host "ERROR: No INF found"
    Write-Host "Contents of $destDir :"
    Get-ChildItem $destDir -Recurse | Select-Object -First 30 | ForEach-Object { Write-Host ("  " + $_.Name) }
    exit 1
}

Write-Host "Found INF files:"
$infFiles | ForEach-Object { Write-Host ("  " + $_.Name) }

# Use the first valid INF
$useInf = $infFiles | Select-Object -First 1
Write-Host ("Using: " + $useInf.FullName)

# Step 3: Install via pnputil
Write-Host ""
Write-Host "[3/3] Installing driver..."
pnputil /add-driver $useInf.FullName /install

Write-Host ""
Write-Host "=== Done ==="
Write-Host "Driver added. Reboot to activate."
Write-Host "After reboot, check: Get-NetAdapter -> DriverVersion should be updated"
