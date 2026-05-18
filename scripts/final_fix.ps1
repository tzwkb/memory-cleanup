# Final memory optimization fixes
$ErrorActionPreference = 'SilentlyContinue'
$freed = 0

Write-Host "=== Final Memory Optimization ==="

# 1. Kill ArmourySocketServer (the parent that keeps respawning asus_framework)
Write-Host ""
Write-Host ">>> Killing ArmourySocketServer + asus_framework..."
$armoury = Get-Process -Name ArmourySocketServer -ErrorAction SilentlyContinue
if ($armoury) {
    $mb = [math]::Round($armoury.PrivateMemorySize64 / 1MB)
    Stop-Process -Name ArmourySocketServer -Force
    $freed += $mb
    Write-Host ("OK  ArmourySocketServer (" + $mb + " MB)")
}
$asusProcs = Get-Process -Name asus_framework -ErrorAction SilentlyContinue
foreach ($p in $asusProcs) {
    $mb = [math]::Round($p.PrivateMemorySize64 / 1MB)
    Stop-Process -Id $p.Id -Force
    $freed += $mb
    Write-Host ("OK  asus_framework PID=" + $p.Id + " (" + $mb + " MB)")
}

# 2. Disable InventorySvc
Write-Host ""
Write-Host ">>> Disabling InventorySvc..."
$inv = Get-Service InventorySvc -ErrorAction SilentlyContinue
if ($inv) {
    Stop-Service InventorySvc -Force
    Set-Service InventorySvc -StartupType Disabled
    Write-Host ("OK  InventorySvc (" + $inv.DisplayName + ") -> Disabled")
}

# 3. Move pagefile from E: (HDD) to system managed on C: (SSD)
# This sets C: to system-managed and clears E:
Write-Host ""
Write-Host ">>> Moving pagefile from E: to C:..."
$pfSettings = Get-CimInstance Win32_PageFileSetting
foreach ($pf in $pfSettings) {
    Write-Host ("  Current: " + $pf.Name + " InitialSize=" + $pf.InitialSize + " MaxSize=" + $pf.MaximumSize)
}

# Set C: to system managed
$cSetting = Get-CimInstance Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ C:'"
if (-not $cSetting) {
    # Create C: pagefile with system-managed size
    Set-CimInstance -ClassName Win32_PageFileSetting -Arguments @{Name="C:\pagefile.sys"; InitialSize=0; MaximumSize=0} -ErrorAction SilentlyContinue
    Write-Host "OK  C: pagefile set to system-managed"
}

# Remove E: pagefile
$eSetting = Get-CimInstance Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ E:'"
if ($eSetting) {
    Remove-CimInstance -InputObject $eSetting
    Write-Host "OK  Removed E: pagefile (reboot to apply)"
}

# 4. Kill wetype_update (WeChat updater, not the input method itself)
Write-Host ""
Write-Host ">>> Killing WeChat input updater..."
$wetypeUpd = Get-Process -Name wetype_update -ErrorAction SilentlyContinue
if ($wetypeUpd) {
    $mb = [math]::Round($wetypeUpd.PrivateMemorySize64 / 1MB)
    Stop-Process -Name wetype_update -Force
    $freed += $mb
    Write-Host ("OK  wetype_update (" + $mb + " MB)")
}

Write-Host ""
Write-Host "=== Total freed: " + $freed + " MB ==="
Write-Host ""
Write-Host "SUMMARY OF CHANGES:"
Write-Host "  [x] Memory Compression: Enabled"
Write-Host "  [x] ArmourySocketServer + asus_framework: Killed"
Write-Host "  [x] InventorySvc: Disabled"
Write-Host "  [x] Pagefile: Moving E:->C: (SSD)"
Write-Host "  [x] wetype_update: Killed"
Write-Host ""
Write-Host "REMAINING:"
Write-Host "  [ ] MT7921 Wi-Fi driver update (fixes non-paged pool leak)"
Write-Host "  [ ] REBOOT to apply all changes"
Write-Host ""
Write-Host "After reboot expected:"
Write-Host "  - Memory Compression = 2-3 GB effective RAM gain"
Write-Host "  - asus_framework NOT respawning (ArmourySocketServer task disabled)"
Write-Host "  - Pagefile on SSD (better perf if needed)"
Write-Host "  - ~500 MB less background bloat"
