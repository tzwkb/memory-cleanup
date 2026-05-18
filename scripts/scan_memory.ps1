# Memory Cleanup Master - Full System Scan
# Part of memory-cleanup-master skill
# Outputs structured report for analysis

param(
    [switch]$Json,
    [switch]$NoCleanup
)

$report = @{
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    totalRamGB = 0
    availableGB = 0
    nonPagedPoolMB = 0
    pagedPoolMB = 0
    topProcesses = @()
    nonPagedPoolWarning = $false
    nduStatus = ""
    wslMemoryMB = 0
    autoServices = @()
    scheduledTasks = @()
    runKeys = @()
    knownBloat = @()
    unknownAutoServices = @()
}

# RAM Overview
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$report.totalRamGB = [math]::Round($cs.TotalPhysicalMemory/1GB, 1)
$report.availableGB = [math]::Round($os.FreePhysicalMemory/1MB, 1)
$pool = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
$report.nonPagedPoolMB = [math]::Round($pool.PoolNonpagedBytes/1MB, 0)
$report.pagedPoolMB = [math]::Round($pool.PoolPagedBytes/1MB, 0)
if ($report.nonPagedPoolMB -gt 500) {
    $report.nonPagedPoolWarning = $true
}

# NDU Status
$nduStart = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Ndu" -Name Start -ErrorAction SilentlyContinue).Start
$report.nduStatus = if ($nduStart -eq 4) { "disabled" } elseif ($nduStart -eq 3) { "manual" } elseif ($nduStart -eq 2) { "auto" } else { "unknown($nduStart)" }

# WSL Memory
$wslProcs = Get-Process -Name "vmmemWSL", "vmmem" -ErrorAction SilentlyContinue
$report.wslMemoryMB = [math]::Round(($wslProcs | Measure-Object WorkingSet64 -Sum).Sum/1MB, 0)

# Top 25 Processes by Private Memory
$topProcs = Get-Process | Sort-Object PrivateMemorySize64 -Descending | Select-Object -First 25
foreach ($p in $topProcs) {
    $report.topProcesses += @{
        name = $p.ProcessName
        privateMB = [math]::Round($p.PrivateMemorySize64/1MB, 0)
        wsMB = [math]::Round($p.WorkingSet64/1MB, 0)
    }
}

# MS core services pattern (safe, skip)
$msCore = '^(AudioSrv|AudioEndpoint|AudioEndpointBuilder|AppXSvc|BFE|BITS|BrokerInfra|CDP|CoreMessaging|CryptSvc|DcomLaunch|DeviceAssoc|Dhcp|Dnscache|DPS|EventLog|EventSystem|FontCache|gpsvc|iphlpsvc|Lanman|LSM|mpssvc|nsi|PcaSvc|Power|ProfSvc|Rpc|SamSs|Schedule|SENS|ShellHW|Spooler|StateRepo|StorSvc|SystemEvents|TextInput|Themes|TrkWks|UserManager|UsoSvc|Wcmsvc|Winmgmt|WlanSvc|wscsvc|DispBroker|DusmSvc|InventorySvc|SecurityHealth|camsvc|Clipboard|webthreat|OneSync|cbdhvc|Clipbrd|WpnUser|IKEEXT|WpnService|WSearch|SysMain|whesvc)$'

# Known bloatware patterns -> category mapping
$bloatPatterns = @{
    '^(ArmouryCrate|ASUS|ROG|LightingService|GameSDK)' = 'ASUS'
    'QQPCRTP|qqpc|QQPCMgr' = 'QQ/Tencent PC Manager'
    'wpscloud|WpsUpdate|kingsoft' = 'WPS Office'
    'LGHUB|logi_lamparray|Logitech' = 'Logitech G Hub'
    'NvContainer|NVDisplay|NVIDIA' = 'NVIDIA Overlay'
    'RvControlSvc|Radmin' = 'Radmin VPN'
    'XLServicePlatform|Thunder' = 'Xunlei'
    'WeType' = 'WeChat Input'
    'DolbyDAXAPI|C-MediaAudio|RzThxSrv' = 'Audio/Vendor'
    'AMD Crash Defender' = 'AMD Crash'
    'WSAIFabricSvc' = 'WSA'
    '0store-service|Zero Install' = 'Zero Install'
    'PnkBstrA' = 'PunkBuster'
    'qmbsrv' = 'Unknown QQ'
    'Everything' = 'Everything'
    'CoworkVMService' = 'Claude'
    'WSLService' = 'WSL'
    'PCManager' = 'MS PC Manager'
}

# Auto+Running services scan
$autoRunning = Get-CimInstance Win32_Service | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -eq 'Running' }
foreach ($svc in $autoRunning) {
    $entry = @{
        name = $svc.Name
        display = $svc.DisplayName
        isMsCore = $false
        isKnownBloat = $false
        bloatCategory = ""
        risk = "unknown"
    }
    if ($svc.Name -match $msCore) {
        $entry.isMsCore = $true
        $entry.risk = "safe"
    }
    foreach ($pattern in $bloatPatterns.Keys) {
        if ($svc.Name -match $pattern) {
            $entry.isKnownBloat = $true
            $entry.bloatCategory = $bloatPatterns[$pattern]
            $entry.risk = if ($svc.Name -match 'WSLService|CoworkVM|Everything') { "in-use" } else { "candidate" }
            break
        }
    }
    if (-not $entry.isMsCore -and -not $entry.isKnownBloat) {
        $report.unknownAutoServices += $entry
    } elseif ($entry.isKnownBloat) {
        $report.knownBloat += $entry
    }
}

# Run Keys
$runPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
)
foreach ($path in $runPaths) {
    $props = Get-ItemProperty $path -ErrorAction SilentlyContinue
    if ($props) {
        $props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
            $report.runKeys += @{
                hive = $path
                name = $_.Name
                value = $_.Value
            }
        }
    }
}

# Non-MS Scheduled Tasks
$tasks = Get-ScheduledTask | Where-Object { $_.State -eq 'Ready' -and $_.TaskPath -notlike '*\Microsoft\*' }
foreach ($t in $tasks) {
    $report.scheduledTasks += @{
        name = $t.TaskName
        path = $t.TaskPath
    }
}

# Output
if ($Json) {
    $report | ConvertTo-Json -Depth 4
} else {
    Write-Host "========== Memory Scan Report =========="
    Write-Host ("Total RAM: {0} GB | Available: {1} GB | Usage: {2}%" -f $report.totalRamGB, $report.availableGB, [math]::Round((1 - $report.availableGB/$report.totalRamGB)*100))
    Write-Host ("Non-Paged Pool: {0} MB {1}" -f $report.nonPagedPoolMB, $(if($report.nonPagedPoolWarning){"*** WARNING: >500MB, probable driver leak ***"}else{"OK"}))
    Write-Host ("NDU: {0}" -f $report.nduStatus)
    Write-Host ("WSL VM Memory: {0} MB" -f $report.wslMemoryMB)
    Write-Host "`n--- Top 10 Processes (Private MB) ---"
    foreach ($p in $report.topProcesses[0..9]) {
        Write-Host ("  {0,-35} Private={1,8}MB  WS={2,8}MB" -f $p.name, $p.privateMB, $p.wsMB)
    }
    Write-Host "`n--- Known Bloatware Services ---"
    foreach ($b in $report.knownBloat) {
        Write-Host ("  [{0}] {1,-35} {2}" -f $b.bloatCategory, $b.name, $b.display)
    }
    Write-Host "`n--- Unknown Non-MS Auto Services ---"
    foreach ($u in $report.unknownAutoServices) {
        Write-Host ("  {0,-35} {1}" -f $u.name, $u.display)
    }
    Write-Host "`n--- Run Keys ---"
    foreach ($r in $report.runKeys) {
        Write-Host ("  [{0}] {1} -> {2}" -f $r.hive, $r.name, $r.value)
    }
    Write-Host "`n--- Non-MS Scheduled Tasks (Ready) ---"
    foreach ($t in $report.scheduledTasks) {
        Write-Host ("  {0,-45} {1}" -f $t.name, $t.path)
    }
    Write-Host "`n========== End Report =========="
}
