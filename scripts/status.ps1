$ErrorActionPreference = 'SilentlyContinue'
Write-Host "=== Post-optimization state ==="
$os = Get-CimInstance Win32_OperatingSystem
$free = [math]::Round($os.FreePhysicalMemory / 1MB)
$usage = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize * 100, 1)
Write-Host ("Free: " + $free + " MB | Usage: " + $usage + "%")

Write-Host ""
Write-Host "--- ASUS-related services ---"
$asusSvcs = Get-Service | Where-Object { ($_.DisplayName -match 'asus|armoury|crate|rog') -or ($_.Name -match 'asus|armoury|crate|rog') }
if ($asusSvcs) {
    $asusSvcs | ForEach-Object { Write-Host ($_.Name + " | " + $_.DisplayName + " | " + $_.StartType + " | " + $_.Status) }
} else { Write-Host "None found" }

Write-Host ""
Write-Host "--- InventorySvc ---"
$inv = Get-Service InventorySvc -ErrorAction SilentlyContinue
if ($inv) {
    $ic = Get-CimInstance Win32_Service -Filter "Name='InventorySvc'"
    Write-Host ($inv.Name + " | " + $inv.DisplayName)
    Write-Host ("StartType: " + $inv.StartType + " | Status: " + $inv.Status)
    Write-Host ("Path: " + $ic.PathName)
} else { Write-Host "Not found" }

Write-Host ""
Write-Host "--- Pagefile ---"
Get-CimInstance Win32_PageFileUsage | ForEach-Object { Write-Host $_.Name }

Write-Host ""
Write-Host "--- asus_framework still running? ---"
$af = Get-Process -Name asus_framework -ErrorAction SilentlyContinue
if ($af) { Write-Host ("YES, " + $af.Count + " instances") } else { Write-Host "NO (clean)" }

Write-Host ""
Write-Host "--- SysMain / WSearch / DoSvc ---"
foreach ($n in @('SysMain','WSearch','DoSvc','MapsBroker')) {
    $s = Get-Service -Name $n -ErrorAction SilentlyContinue
    if ($s) { Write-Host ($s.Name + ": " + $s.StartType + " / " + $s.Status) }
}
