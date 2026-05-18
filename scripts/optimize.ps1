# Comprehensive optimization
$ErrorActionPreference = 'SilentlyContinue'
$freed = 0

# 1. Enable Memory Compression
Write-Host ">>> Enabling Memory Compression..."
$mm = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -ErrorAction SilentlyContinue
if ($mm.EnableCompression -ne 1) {
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "EnableCompression" -Value 1 -Type DWord
    Write-Host "OK  Memory Compression -> Enabled (reboot required)"
} else {
    Write-Host "OK  Memory Compression already enabled"
}

# 2. Kill heavy non-essential processes
Write-Host ""
Write-Host ">>> Killing bloat processes..."

$killTargets = @('RadeonSoftware','AMDRSSrcExt','asus_framework','MicrosoftEdgeUpdate')
foreach ($target in $killTargets) {
    $procs = Get-Process -Name $target -ErrorAction SilentlyContinue
    foreach ($p in $procs) {
        $mb = [math]::Round($p.PrivateMemorySize64 / 1MB)
        Stop-Process -Id $p.Id -Force
        $freed += $mb
        $msg = "OK  " + $target + " PID=" + $p.Id + " (" + $mb + " MB)"
        Write-Host $msg
    }
}

# Kill idle powershell (>50MB, no window title)
$psProcs = Get-Process -Name powershell -ErrorAction SilentlyContinue
foreach ($p in $psProcs) {
    if ($p.MainWindowTitle -eq '' -and $p.PrivateMemorySize64 -gt 50MB) {
        $mb = [math]::Round($p.PrivateMemorySize64 / 1MB)
        Stop-Process -Id $p.Id -Force
        $freed += $mb
        Write-Host ("OK  idle powershell PID=" + $p.Id + " (" + $mb + " MB)")
    }
}

# 3. msedgewebview2 parent investigation
Write-Host ""
Write-Host ">>> msedgewebview2 parents:"
$webviews = Get-Process -Name msedgewebview2 -ErrorAction SilentlyContinue
foreach ($wv in $webviews) {
    $ci = Get-CimInstance Win32_Process -Filter "ProcessId=$($wv.Id)"
    if ($ci -and $ci.ParentProcessId) {
        $pp = Get-Process -Id $ci.ParentProcessId -ErrorAction SilentlyContinue
        if ($pp) {
            $wmb = [math]::Round($wv.PrivateMemorySize64 / 1MB)
            Write-Host ("  msedgewebview2 PID=" + $wv.Id + " (" + $wmb + " MB) <- parent: " + $pp.Name + " PID=" + $pp.Id)
        }
    }
}

# 4. ASUS services
Write-Host ""
Write-Host ">>> ASUS-related services:"
$asusSvcs = Get-Service | Where-Object { ($_.DisplayName -match 'asus|armoury|crate|rog') -or ($_.Name -match 'asus|armoury|crate|rog') }
$asusSvcs | ForEach-Object {
    Write-Host ("  Service: " + $_.Name + " | " + $_.DisplayName + " | " + $_.StartType + " | " + $_.Status)
}

# 5. InventorySvc
Write-Host ""
Write-Host ">>> InventorySvc:"
$inv = Get-Service InventorySvc -ErrorAction SilentlyContinue
if ($inv) {
    $invCi = Get-CimInstance Win32_Service -Filter "Name='InventorySvc'"
    Write-Host ("  Name: " + $inv.Name + " | " + $inv.DisplayName)
    Write-Host ("  StartType: " + $inv.StartType + " | Status: " + $inv.Status)
    Write-Host ("  PathName: " + $invCi.PathName)
}

# 6. Pagefile location and drive type
Write-Host ""
Write-Host ">>> Pagefile:"
$pf = Get-CimInstance Win32_PageFileUsage
foreach ($p in $pf) {
    $drive = $p.Name.Substring(0, 1)
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='${drive}:'"
    Write-Host ("  " + $p.Name + " | drive " + $drive + ": | type=" + $disk.DriveType)
}

# 7. SysMain status
Write-Host ""
Write-Host ">>> System services status:"
$checks = @('SysMain','WSearch','DoSvc','MapsBroker')
foreach ($name in $checks) {
    $s = Get-Service -Name $name -ErrorAction SilentlyContinue
    if ($s) {
        Write-Host ("  " + $s.Name + ": StartType=" + $s.StartType + " Status=" + $s.Status)
    } else {
        Write-Host ("  " + $name + ": not found")
    }
}

Write-Host ""
Write-Host "=== Total freed: " + $freed + " MB ==="
Write-Host "*** REBOOT required for Memory Compression to take effect ***"
