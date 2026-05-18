# Kill useless bloat processes to free memory
$ErrorActionPreference = 'SilentlyContinue'

$bloat = @(
    'asus_framework',        # ASUS bloatware
    # 'wetype_server',     # SKIP: user may be using WeChat input right now
    'ArmouryCrate',          # ASUS Armoury Crate
    'ASUSOptimization',      # ASUS optimization
    'AsusAppService',        # ASUS app service
    'LightingService',       # ASUS AURA lighting
    'ROGLiveService',        # ROG Live Service
    'GameSDK',               # ASUS Game SDK
    'nvcontainer',           # NVIDIA container (background)
    'nvsphelper',            # NVIDIA shadowplay helper
    'NVIDIA Share',          # NVIDIA share/overlay
    'GoogleUpdate',          # Google updater
    'FirefoxUpdate',         # Firefox updater
    'OneDrive',              # OneDrive sync
    'ZeroInstall',           # Zero Install store
    'SoftLanding',           # SoftLanding
    'wpscloudsvr',           # WPS cloud
    'Creative',              # Sound Blaster / Creative
    'AdobeIPCBroker',        # Adobe IPC broker
    'AdobeUpdateService',    # Adobe updater
    'MicrosoftEdgeUpdate',   # Edge update
    'Widgets',               # Windows widgets
    'GameBar',               # Xbox Game Bar
    'YourPhone',             # Phone Link
    'PhoneExperienceHost',   # Phone Experience
    'Skype',                 # Skype
    'Teams'                  # Microsoft Teams
)

$killed = @()
$freed = 0

foreach ($p in Get-Process) {
    if ($p.Name -in $bloat) {
        $mb = [math]::Round($p.PrivateMemorySize64 / 1MB)
        $freed += $mb
        $killed += "$($p.Name) (PID=$($p.Id), ${mb}MB)"
        Stop-Process -Id $p.Id -Force
    }
}

Write-Host "=== Killed processes ==="
$killed | ForEach-Object { Write-Host "  $_" }
Write-Host "Total memory freed: ${freed}MB"
Write-Host "Done."
