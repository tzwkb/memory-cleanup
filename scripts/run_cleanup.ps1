# Auto-generated wrapper to batch cleanup with proper arrays
param([switch]$DryRun)

$svcList = @('DoSvc','MapsBroker','qmbsrv','WeType Management Service')
$taskList = @(
    '\WpsUpdateLogonTask_ASUS',
    '\WpsUpdateTask_ASUS',
    '\ASUS\ArmourySocketServer',
    '\ASUS\ASUSUpdateTaskMachineCore',
    '\ASUS\ASUSUpdateTaskMachineUA',
    '\ASUS\P508PowerAgent_sdk',
    '\GoogleSystem\GoogleUpdater\GoogleUpdaterTaskSystem149.0.7814.0{61860B19-E4F5-4F31-8279-ED109C688CA7}',
    '\Mozilla\Firefox Background Update 308046B0AF4A39CB',
    '\Mozilla\Firefox Default Browser Agent 308046B0AF4A39CB',
    '\SoftLanding\S-1-5-21-276919526-624293650-3572913875-1001\SoftLandingCreativeManagementTask',
    '\SoftLanding\S-1-5-21-276919526-624293650-3572913875-1001\SoftLandingDeferralTask-{61fbe40f-f472-48c3-81a3-4eb1980898e4}',
    '\Zero Install\Self update',
    '\Zero Install\Update apps'
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$cleanupScript = Join-Path $scriptDir 'cleanup_memory.ps1'

if ($DryRun) {
    & $cleanupScript -DryRun -Services $svcList -Tasks $taskList
} else {
    & $cleanupScript -Services $svcList -Tasks $taskList
}
