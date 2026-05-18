# Memory Cleanup Master — Cleanup Executor
# Disables services/tasks/Run keys identified as bloat
# Always generates a restore script before making changes

param(
    [string[]]$Services = @(),
    [string[]]$Tasks = @(),
    [string[]]$RunKeyNames = @(),
    [switch]$DisableNdu,
    [switch]$DryRun,
    [string]$RestoreScriptPath = "$env:USERPROFILE\Desktop\memory_restore.ps1"
)

$actions = @()

# --- NDU Fix ---
if ($DisableNdu) {
    $actions += @{type="ndu"; detail="Disable Ndu.sys (Start=4)"}
    if (-not $DryRun) {
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndu" /v Start /t REG_DWORD /d 4 /f | Out-Null
    }
}

# --- Services ---
$bloatCategories = @{
    'ASUS' = @('ArmouryCrateControlInterface','ArmouryCrateService','AsusAppService','AsusCertService','ASUSOptimization','ASUSSoftwareManager','ASUSSwitch','ASUSSystemAnalysis','ASUSSystemDiagnosis','LightingService','ROG Live Service','GameSDK Service')
    'QQ' = @('QQPCRTP')
    'WPS' = @('wpscloudsvr','WpsUpdateService')
    'Logitech' = @('LGHUBUpdaterService','logi_lamparray_service')
    'NVIDIA' = @('NvContainerLocalSystem','NVDisplay.ContainerLocalSystem')
    'Other' = @('DiagTrack','DoSvc','PnkBstrA','WpnService','WSearch','SysMain','XLServicePlatform','WSAIFabricSvc','AMD Crash Defender Service','qmbsrv','whesvc','DolbyDAXAPI','C-MediaAudioService','RzThxSrv','0store-service','AMD External Events Utility','RvControlSvc','PCManager Service Store')
}

$allKnownBloat = @{}
foreach ($cat in $bloatCategories.Keys) {
    foreach ($s in $bloatCategories[$cat]) {
        $allKnownBloat[$s] = $cat
    }
}

foreach ($svcName in $Services) {
    $actual = $svcName
    # If user passes category name, expand
    if ($bloatCategories.ContainsKey($svcName)) {
        foreach ($s in $bloatCategories[$svcName]) {
            if (-not ($Services -contains $s)) {
                $actual = $s  # will be added in outer loop via array
            }
        }
        continue
    }

    $s = Get-Service -Name $actual -ErrorAction SilentlyContinue
    if (-not $s) {
        Write-Host "NOT FOUND: $actual"
        continue
    }

    $actions += @{type="service"; name=$actual; action="Disable"; from=$s.StartType}

    if (-not $DryRun) {
        Stop-Service -Name $actual -Force -ErrorAction SilentlyContinue
        Set-Service -Name $actual -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "OK  $actual -> Disabled"
    } else {
        Write-Host "DRY $actual -> would disable (currently $($s.StartType))"
    }
}

# --- Scheduled Tasks ---
foreach ($taskName in $Tasks) {
    $actions += @{type="task"; name=$taskName; action="Disable"}
    if (-not $DryRun) {
        Disable-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        Write-Host "OK  $taskName -> Disabled"
    } else {
        Write-Host "DRY $taskName -> would disable"
    }
}

# --- Run Keys ---
$runPaths = @{
    "HKLM" = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
    "HKLM32" = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"
    "HKCU" = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
}

foreach ($keyName in $RunKeyNames) {
    foreach ($hive in $runPaths.Keys) {
        $val = Get-ItemProperty $runPaths[$hive] -Name $keyName -ErrorAction SilentlyContinue
        if ($val) {
            $actions += @{type="runkey"; name=$keyName; hive=$hive; action="Remove"; value=$val.$keyName}
            if (-not $DryRun) {
                Remove-ItemProperty $runPaths[$hive] -Name $keyName -Force -ErrorAction SilentlyContinue
                Write-Host "OK  $keyName -> Removed from $hive Run"
            } else {
                Write-Host "DRY $keyName -> would remove from $hive Run"
            }
        }
    }
}

# --- Generate Restore Script ---
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("# Memory Cleanup Master - Auto-generated Restore Script")
[void]$sb.AppendLine("# Generated: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')")
[void]$sb.AppendLine("# Run as Administrator to revert all changes")
[void]$sb.AppendLine("")
[void]$sb.AppendLine('$restoreAuto = @(')
foreach ($a in ($actions | Where-Object { $_.type -eq 'service' })) {
    [void]$sb.AppendLine("    '$($a.name)'")
}
[void]$sb.AppendLine(")")
[void]$sb.AppendLine("")
[void]$sb.AppendLine('Write-Host "=== Restoring services ==="')
[void]$sb.AppendLine('foreach ($svc in $restoreAuto) {')
[void]$sb.AppendLine('    Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue')
[void]$sb.AppendLine('    Write-Host "OK  $svc -> Automatic"')
[void]$sb.AppendLine("}")
[void]$sb.AppendLine("")
foreach ($a in ($actions | Where-Object { $_.type -eq 'task' })) {
    [void]$sb.AppendLine("Enable-ScheduledTask -TaskName '$($a.name)' -ErrorAction SilentlyContinue")
}
[void]$sb.AppendLine("")
foreach ($a in ($actions | Where-Object { $_.type -eq 'runkey' })) {
    $rp = $runPaths[$a.hive]
    $val = $a.value -replace "'", "''"
    [void]$sb.AppendLine("Set-ItemProperty '$rp' -Name '$($a.name)' -Value '$val' -ErrorAction SilentlyContinue")
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine('Write-Host "Done. Reboot to apply all restores."')
$restoreContent = $sb.ToString()

if (-not $DryRun -and $actions.Count -gt 0) {
    $restoreContent | Out-File -FilePath $RestoreScriptPath -Encoding UTF8
    Write-Host "`nRestore script saved to: $RestoreScriptPath"
}

# --- Summary ---
Write-Host ("`n=== Summary: {0} actions {1} ===" -f $actions.Count, $(if($DryRun){"(DRY RUN)"}else{"executed"}))
$actions | Group-Object type | ForEach-Object {
    Write-Host ("  {0}: {1}" -f $_.Name, $_.Count)
}
if (-not $DryRun -and $actions.Count -gt 0) {
    Write-Host "`n*** REBOOT required for all changes to take effect ***"
}