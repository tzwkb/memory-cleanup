$killed = @()
$targets = @('SearchHost','SearchApp','SecurityHealthSystray','TextInputHost','StartMenuExperienceHost')
foreach ($t in $targets) {
    $p = Get-Process -Name $t -ErrorAction SilentlyContinue
    if ($p) {
        $mb = [math]::Round($p.PrivateMemorySize64 / 1MB)
        Stop-Process -Name $t -Force
        $killed += "$t ($mb MB)"
    }
}
if ($killed.Count -gt 0) {
    Write-Host "Killed:"
    $killed | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "None found"
}
