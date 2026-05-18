# Final squeeze — kill remaining bloat
$ErrorActionPreference = 'SilentlyContinue'
$freed = 0

# 1. Kill all msedgewebview2 instances (459MB!)
Write-Host ">>> Killing all msedgewebview2..."
$wvs = Get-Process -Name msedgewebview2 -ErrorAction SilentlyContinue
foreach ($p in $wvs) {
    $mb = [math]::Round($p.PrivateMemorySize64 / 1MB)
    Stop-Process -Id $p.Id -Force
    $freed += $mb
}
Write-Host ("OK  msedgewebview2 x" + $wvs.Count + " (" + $freed + " MB)")

# 2. Kill Widgets (parent of webview chain)
$w = Get-Process -Name Widgets -ErrorAction SilentlyContinue
if ($w) {
    $mb = [math]::Round($w.PrivateMemorySize64 / 1MB)
    Stop-Process -Name Widgets -Force
    $freed += $mb
    Write-Host ("OK  Widgets (" + $mb + " MB)")
}

# 3. Kill RadeonSoftware (came back, 245MB)
$r = Get-Process -Name RadeonSoftware -ErrorAction SilentlyContinue
if ($r) {
    $mb = [math]::Round($r.PrivateMemorySize64 / 1MB)
    Stop-Process -Name RadeonSoftware -Force
    $freed += $mb
    Write-Host ("OK  RadeonSoftware (" + $mb + " MB)")
}

# 4. Kill remaining ASUS bits
$asusBits = @('AcPowerNotification')
foreach ($name in $asusBits) {
    $p = Get-Process -Name $name -ErrorAction SilentlyContinue
    if ($p) {
        $mb = [math]::Round($p.PrivateMemorySize64 / 1MB)
        Stop-Process -Name $name -Force
        $freed += $mb
        Write-Host ("OK  " + $name + " (" + $mb + " MB)")
    }
}

# 5. Kill PhoneExperienceHost, SearchHost, TextInputHost
$uiBits = @('PhoneExperienceHost','SearchHost','TextInputHost','StartMenuExperienceHost')
foreach ($name in $uiBits) {
    $p = Get-Process -Name $name -ErrorAction SilentlyContinue
    if ($p) {
        $mb = [math]::Round($p.PrivateMemorySize64 / 1MB)
        Stop-Process -Name $name -Force
        $freed += $mb
        Write-Host ("OK  " + $name + " (" + $mb + " MB)")
    }
}

# 6. FontCache -> Manual + stop
Write-Host ""
Write-Host ">>> FontCache -> Manual..."
$fc = Get-Service FontCache -ErrorAction SilentlyContinue
if ($fc -and $fc.StartType -ne 'Manual') {
    Stop-Service FontCache -Force
    Set-Service FontCache -StartupType Manual
    Write-Host "OK  FontCache -> Manual"
}

# 7. Disable transparency effects
Write-Host ">>> Disabling transparency..."
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Type DWord -ErrorAction SilentlyContinue
Write-Host "OK  Transparency -> Off"

# 8. CDPUserSvc -> Manual (connected devices platform)
Write-Host ">>> CDPUserSvc -> Manual..."
$cdp = Get-Service CDPUserSvc_80581 -ErrorAction SilentlyContinue
if ($cdp -and $cdp.StartType -ne 'Manual') {
    Stop-Service CDPUserSvc_80581 -Force
    Set-Service CDPUserSvc_80581 -StartupType Manual
    Write-Host "OK  CDPUserSvc -> Manual"
}

Write-Host ""
Write-Host ("=== Total freed: " + $freed + " MB ===")
