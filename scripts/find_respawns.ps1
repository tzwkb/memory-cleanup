# Find what restarts each killed process
$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Respawning mechanisms ==="

# 1. RadeonSoftware — Run key + scheduled task + service
Write-Host ""
Write-Host "--- RadeonSoftware restart sources ---"
$runPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
)
foreach ($rp in $runPaths) {
    $entries = Get-ItemProperty $rp -ErrorAction SilentlyContinue
    if ($entries) {
        $entries.PSObject.Properties | Where-Object { $_.Name -notmatch '^(PSPath|PSParentPath|PSChildName|PSDrive|PSProvider)$' } | ForEach-Object {
            if ($_.Value -match 'radeon|amd|adrenalin|cnext') {
                Write-Host ("  Run key [" + $rp + "] " + $_.Name + " -> " + $_.Value)
            }
        }
    }
}
$amdTasks = Get-ScheduledTask | Where-Object { $_.TaskName -match 'radeon|amd|adrenalin' -or $_.TaskPath -match 'radeon|amd|adrenalin' }
if ($amdTasks) {
    $amdTasks | ForEach-Object { Write-Host ("  Task: " + $_.TaskPath + $_.TaskName + " | State: " + $_.State) }
}
$amdSvc = Get-Service | Where-Object { $_.DisplayName -match 'amd|radeon' -and $_.StartType -ne 'Disabled' }
if ($amdSvc) {
    $amdSvc | ForEach-Object { Write-Host ("  Service: " + $_.Name + " | " + $_.DisplayName + " | " + $_.StartType + " | " + $_.Status) }
}

# 2. Widgets — service + task
Write-Host ""
Write-Host "--- Widgets restart sources ---"
$widgetTasks = Get-ScheduledTask | Where-Object { $_.TaskName -match 'widget' -or $_.TaskPath -match 'widget' }
if ($widgetTasks) {
    $widgetTasks | ForEach-Object { Write-Host ("  Task: " + $_.TaskPath + $_.TaskName + " | State: " + $_.State) }
}
$widgetSvc = Get-Service | Where-Object { $_.DisplayName -match 'widget' -and $_.StartType -ne 'Disabled' }
if ($widgetSvc) {
    $widgetSvc | ForEach-Object { Write-Host ("  Service: " + $_.Name + " | " + $_.DisplayName + " | " + $_.StartType) }
}

# 3. PhoneExperienceHost — background app
Write-Host ""
Write-Host "--- Phone Link restart sources ---"
$phoneSvc = Get-Service | Where-Object { $_.DisplayName -match 'phone' -and $_.StartType -ne 'Disabled' }
if ($phoneSvc) {
    $phoneSvc | ForEach-Object { Write-Host ("  Service: " + $_.Name + " | " + $_.DisplayName + " | " + $_.StartType) }
}
$phoneTasks = Get-ScheduledTask | Where-Object { $_.TaskName -match 'Phone' }
if ($phoneTasks) {
    $phoneTasks | ForEach-Object { Write-Host ("  Task: " + $_.TaskPath + $_.TaskName + " | State: " + $_.State) }
}

# 4. SearchHost — Windows search, can't really disable
Write-Host ""
Write-Host "--- Search restart sources ---"
Write-Host "  (Windows Shell - restarts on user interaction, cannot fully disable)"

# 5. Widgets registry disable
Write-Host ""
Write-Host "--- Widgets registry override ---"
$widgetReg = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -ErrorAction SilentlyContinue
if ($widgetReg) {
    Write-Host ("  AllowNewsAndInterests: " + $widgetReg.AllowNewsAndInterests)
} else {
    Write-Host "  No Dsh policy set (Widgets fully enabled)"
}
