# Check MT7921 and download latest driver
$ErrorActionPreference = 'Stop'

Write-Host "=== MT7921 Driver Updater ==="

# Find the device
$device = Get-PnpDevice -Class Net | Where-Object { $_.Name -match 'MT7921|MediaTek' }
if (-not $device) {
    Write-Host "MT7921 not found in network devices"
    exit 1
}
Write-Host ("Device: " + $device.Name)
Write-Host ("InstanceId: " + $device.InstanceId)
Write-Host ("Status: " + $device.Status)

# Get current driver version
$driver = Get-PnpDeviceProperty -InstanceId $device.InstanceId -KeyName 'DEVPKEY_Device_DriverVersion' -ErrorAction SilentlyContinue
if ($driver) {
    Write-Host ("Current driver: " + $driver.Data)
}

# Try Windows Update for newer driver
Write-Host ""
Write-Host "Checking Windows Update for newer driver..."
$updates = Get-WindowsDriver -Online | Where-Object { $_.Driver -match 'mtk|mediatek|mt7921' }
if ($updates) {
    Write-Host "Found in Windows Update:"
    $updates | ForEach-Object { Write-Host ("  " + $_.Driver + " | " + $_.Version + " | " + $_.ProviderName) }
} else {
    Write-Host "No MT7921 driver found in Windows Update cache"
}

# Check PNPUtil for driver packages
Write-Host ""
Write-Host "Installed MTK driver packages:"
pnputil /enum-drivers | Select-String -Pattern 'mtk|mediatek|mt7921' -SimpleMatch
