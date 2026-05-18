# Permanently disable Widgets, Phone Link, and other stubborn processes
$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Permanent Disable ==="

# 1. Widgets - disable via registry policy
Write-Host ""
Write-Host ">>> Disabling Widgets permanently..."
If (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Force | Out-Null
}
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0 -Type DWord
Write-Host "OK  Widgets -> Permanently disabled via Policy"

# 2. Phone Link - try to disable via app
Write-Host ""
Write-Host ">>> Checking Phone Link..."
$phonePkg = Get-AppxPackage -Name "*YourPhone*" -ErrorAction SilentlyContinue
if ($phonePkg) {
    Write-Host ("  Found: " + $phonePkg.Name)
    Write-Host "  To remove: Get-AppxPackage *YourPhone* | Remove-AppxPackage"
}

# 3. RadeonSoftware - check if AMD Adrenalin is installed
Write-Host ""
Write-Host ">>> RadeonSoftware analysis..."
$radeonPath = Get-Item "C:\Program Files\AMD\CNext\CNext\RadeonSoftware.exe" -ErrorAction SilentlyContinue
if ($radeonPath) {
    Write-Host "  Installed: " + $radeonPath.FullName
    Write-Host "  Started by: AMD GPU driver at user login"
    Write-Host "  Options:"
    Write-Host "    1. Remove AMD Adrenalin, install driver-only"
    Write-Host "    2. Disable AMD External Events Utility service"
    Write-Host "    3. Keep killing manually (safe, just inconvenient)"
}

# 4. Check AMD External Events service
Write-Host ""
Write-Host "--- AMD External Events Utility ---"
$amdExtSvc = Get-Service "AMD External Events Utility" -ErrorAction SilentlyContinue
if ($amdExtSvc) {
    Write-Host ("  Service: " + $amdExtSvc.Name + " | StartType: " + $amdExtSvc.StartType + " | Status: " + $amdExtSvc.Status)
    Write-Host "  This service provides AMD user-mode driver features"
    Write-Host "  Disabling prevents RadeonSoftware from auto-starting"
}

# 5. Restart explorer to clear shell extension memory
Write-Host ""
Write-Host ">>> Restarting explorer to clear leak..."
$explorer = Get-Process -Name explorer -ErrorAction SilentlyContinue
if ($explorer) {
    $mb = [math]::Round($explorer.PrivateMemorySize64 / 1MB)
    Stop-Process -Name explorer -Force
    Write-Host ("OK  Explorer restarted (was " + $mb + " MB)")
}

Write-Host ""
Write-Host "=== Done ==="
Write-Host "Recommendations:"
Write-Host "  [x] Widgets: Permanently disabled"
Write-Host "  [ ] RadeonSoftware: Disable 'AMD External Events Utility' service"
Write-Host "  [ ] Phone Link: Uninstall via AppxPackage"
Write-Host "  [ ] AMD driver-only: Reinstall without Adrenalin (saves ~250MB)"
