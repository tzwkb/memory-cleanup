# Find remaining optimization targets
$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Remaining Memory Consumers ==="

# 1. All processes > 20MB not yet optimized
Write-Host ""
Write-Host "--- Processes > 20MB ---"
$skip = @('Idle','System','Registry','Memory Compression','csrss','wininit','services','lsass','svchost','fontdrvhost','WUDFHost','dllhost','smss','winlogon','spoolsv','sihost','taskhostw','ctfmon','RuntimeBroker','ShellExperienceHost','ApplicationFrameHost','SystemSettings','LockApp')
Get-Process | Where-Object {
    $_.PrivateMemorySize64 -gt 20MB -and
    $_.Name -notin $skip -and
    $_.Name -notmatch '^claude$|^System$'
} | Sort-Object PrivateMemorySize64 -Descending |
    Select-Object -First 25 Name,Id,@{N='MB';E={[math]::Round($_.PrivateMemorySize64/1MB)}} |
    ForEach-Object { Write-Host ("  " + $_.Name + " (PID=" + $_.Id + "): " + $_.MB + " MB") }

# 2. Shell extensions (explorer addons)
Write-Host ""
Write-Host "--- Explorer Shell Extensions ---"
$shellEx = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved" -ErrorAction SilentlyContinue
$shellExCount = ($shellEx.PSObject.Properties | Where-Object { $_.Name -notmatch 'PSPath|PSParentPath|PSChildName|PSDrive|PSProvider' }).Count
Write-Host ("Approved shell extensions: " + $shellExCount)

# 3. Transparency/Acrylic effects
Write-Host ""
Write-Host "--- UI Transparency ---"
$trans = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -ErrorAction SilentlyContinue
Write-Host ("EnableTransparency: " + $trans.EnableTransparency)
Write-Host ("ColorPrevalence: " + $trans.ColorPrevalence)

# 4. Windows Defender MsMpEng.exe
Write-Host ""
Write-Host "--- Windows Defender ---"
$defender = Get-Process -Name MsMpEng -ErrorAction SilentlyContinue
if ($defender) {
    $mb = [math]::Round($defender.PrivateMemorySize64 / 1MB)
    Write-Host ("MsMpEng: " + $mb + " MB")
}

# 5. Font cache service
Write-Host ""
Write-Host "--- Font Cache ---"
$fc = Get-Service FontCache -ErrorAction SilentlyContinue
if ($fc) { Write-Host ("FontCache: " + $fc.StartType + " / " + $fc.Status) }

# 6. Connected Devices / device platform
Write-Host ""
Write-Host "--- CDP User Service ---"
$cdp = Get-Service CDPUserSvc_80581 -ErrorAction SilentlyContinue
if ($cdp) { Write-Host ("CDPUserSvc: " + $cdp.StartType + " / " + $cdp.Status) }

# 7. msedgewebview2 parents
Write-Host ""
Write-Host "--- msedgewebview2 Parents ---"
$wvs = Get-Process -Name msedgewebview2 -ErrorAction SilentlyContinue
foreach ($wv in $wvs) {
    $ci = Get-CimInstance Win32_Process -Filter "ProcessId=$($wv.Id)"
    if ($ci -and $ci.ParentProcessId) {
        $pp = Get-Process -Id $ci.ParentProcessId -ErrorAction SilentlyContinue
        $wmb = [math]::Round($wv.PrivateMemorySize64 / 1MB)
        if ($pp) {
            Write-Host ("  msedgewebview2 (" + $wmb + " MB) <- parent: " + $pp.Name + " (" + $pp.Id + ")")
        }
    }
}

# 8. Check asus_framework (did it come back?)
Write-Host ""
Write-Host "--- asus_framework alive? ---"
$af = Get-Process -Name asus_framework -ErrorAction SilentlyContinue
if ($af) {
    $total = 0
    $af | ForEach-Object { $total += [math]::Round($_.PrivateMemorySize64 / 1MB) }
    Write-Host ("YES, " + $af.Count + " instances, " + $total + " MB total")
} else {
    Write-Host "NO (clean)"
}
