# Comprehensive System Memory Optimization
$ErrorActionPreference = 'SilentlyContinue'

Write-Host "============================================"
Write-Host "  Memory Optimization Audit"
Write-Host "============================================"

# --- 1. Current State ---
$os = Get-CimInstance Win32_OperatingSystem
$totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
$usagePct = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize * 100, 1)
Write-Host "`n--- Memory ---"
Write-Host "Total: ${totalGB}GB | Free: ${freeGB}GB | Usage: ${usagePct}%"

# --- 2. Non-Paged Pool ---
$npp = (Get-Counter '\Memory\Pool Nonpaged Bytes').CounterSamples.CookedValue
$nppMB = [math]::Round($npp / 1MB)
$nppStatus = if ($nppMB -gt 500) { "WARNING: ${nppMB}MB (>500MB)" } else { "OK: ${nppMB}MB" }
Write-Host "Non-Paged Pool: $nppStatus"

# --- 3. Memory Compression ---
$mmAgent = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -ErrorAction SilentlyContinue
Write-Host "`n--- Memory Management ---"
Write-Host "Memory Compression: $($mmAgent.EnableCompression -eq 1)"
Write-Host "ClearPageFileAtShutdown: $($mmAgent.ClearPageFileAtShutdown -eq 1)"
Write-Host "Ndu Enabled: $((Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Ndu' -ErrorAction SilentlyContinue).Start -ne 4)"

# --- 4. Superfetch/SysMain ---
$sysmain = Get-Service SysMain -ErrorAction SilentlyContinue
if ($sysmain) {
    Write-Host "SysMain (Superfetch): $($sysmain.StartType) / $($sysmain.Status)"
}

# --- 5. Windows Search ---
$wsearch = Get-Service WSearch -ErrorAction SilentlyContinue
if ($wsearch) {
    Write-Host "WSearch (Indexer): $($wsearch.StartType) / $($wsearch.Status)"
}

# --- 6. Virtual Memory / Pagefile ---
$pf = Get-CimInstance Win32_PageFileUsage
Write-Host "`n--- Pagefile ---"
foreach ($p in $pf) {
    Write-Host "  $($p.Name): $([math]::Round($p.CurrentUsage/1MB))MB used / $([math]::Round($p.AllocatedBaseSize/1MB))MB allocated"
}

# --- 7. Non-MS Auto-Running Services ---
Write-Host "`n--- Non-MS Auto-Running Services ---"
$msServices = @(
    'AarSvc','AJRouter','ALG','AppIDSvc','Appinfo','AppMgmt','AppReadiness','AppVClient','AppXSvc',
    'AssignedAccessManagerSvc','AudioEndpointBuilder','Audiosrv','autotimesvc','AxInstSV','BcastDVRUserService',
    'BDESVC','BFE','BITS','BluetoothUserService','BrokerInfrastructure','BTAGService','BthAvctpSvc',
    'bthserv','camsvc','CaptureService','cbdhsvc','CDPSvc','CDPUserSvc','CertPropSvc','ClipSVC',
    'CloudFilesDiagnosticSvc','COMSysApp','ConsentUxUserSvc','CoreMessagingRegistrar','CredentialEnrollmentManager',
    'CryptSvc','CscService','DcomLaunch','dcsvc','defragsvc','DeviceAssociationService','DeviceInstall',
    'DevicePickerUserSvc','DevicesFlowUserSvc','DevQueryBroker','Dhcp','diagnosticshub.standardcollector.service',
    'diagsvc','DiagTrack','DispBrokerDesktopSvc','DisplayEnhancementService','DmEnrollmentSvc','dmwappushservice',
    'Dnscache','DoSvc','DPS','DsmSvc','DsSvc','DusmSvc','Eaphost','EFS','embeddedmode','EntAppSvc',
    'EventLog','EventSystem','Fax','fdPHost','FDResPub','fhsvc','FontCache','FontCache3.0.0.0','FrameServer',
    'GameInputSvc','gpsvc','GraphicsPerfSvc','HomeGroupListener','HomeGroupProvider','HvHost','hidserv',
    'IKEEXT','InstallService','iphlpsvc','IpxlatCfgSvc','KeyIso','KtmRm','LanmanServer','LanmanWorkstation',
    'lfsvc','LicenseManager','lltdsvc','lmhosts','LSM','LxssManager','MapsBroker','MessagingService',
    'MicrosoftEdgeElevationService','MixedRealityOpenXRSvc','mpssvc','MpsSvc','MSDTC','MSiSCSI','MsKeyboardFilter',
    'MSMQ','NaturalAuthentication','NcaSvc','NcbService','NcdAutoSetup','Netlogon','Netman','netprofm','NetSetupSvc',
    'NetTcpPortSharing','NlaSvc','nsi','p2pimsvc','p2psvc','PcaSvc','PeerDistSvc','perceptionsimulation',
    'PerfHost','PhoneSvc','pla','PlugPlay','PNRPAutoReg','PNRPsvc','PolicyAgent','Power','PrintNotify',
    'ProfSvc','PushToInstall','QWAVE','RasAuto','RasMan','RemoteAccess','RemoteRegistry','RetailDemo',
    'RmSvc','RpcEptMapper','RpcLocator','RpcSs','SamSs','SCardSvr','ScDeviceEnum','Schedule','SCPolicySvc',
    'SDRSVC','seclogon','SecurityHealthService','SEMgrSvc','SENS','Sense','SensorDataService','SensorService',
    'SensrSvc','SessionEnv','SgrmBroker','SharedAccess','SharedRealitySvc','ShellHWDetection','shpamsvc',
    'smphost','SMSRouter','SNMPTRAP','SpecialAdministrationConsoleHelper','Spectrum','Spooler','sppsvc',
    'SSDPSRV','ssh-agent','SstpSvc','StateRepository','StiSvc','StorSvc','svsvc','swprv','SysMain',
    'SystemEventsBroker','TabletInputService','TapiSrv','TermService','TextInputManagementService','Themes',
    'TieringEngineService','TimeBrokerSvc','TokenBroker','TrkWks','TroubleshootingSvc','TrustedInstaller',
    'tzautoupdate','UdkUserSvc','UevAgentService','UI0Detect','UmRdpService','upnphost','UserManager',
    'UsoSvc','VacSvc','VaultSvc','vds','VGAuthService','vmictimesync','VMTools','vm3dservice','VSS',
    'W32Time','W3SVC','WalletService','WarpJITSvc','Was','wbengine','WbioSrvc','Wcmsvc','wcncsvc',
    'WdiServiceHost','WdiSystemHost','Wecsvc','WEPHOSTSVC','wercplsupport','WerSvc','WiaRpc','WIASvc',
    'WinDefend','WinHttpAutoProxySvc','Winmgmt','WinRM','wisvc','WlanSvc','wlidsvc','wlpasvc','WManSvc',
    'wmiApSrv','WMPNetworkSvc','workfolderssvc','WpcMonSvc','WPDBusEnum','WpnService','WpnUserService',
    'wscsvc','WSearch','WSService','wuauserv','WwanSvc','XblAuthManager','XblGameSave','XboxGipSvc',
    'XboxNetApiSvc'
)
$allRunning = Get-Service | Where-Object { $_.Status -eq 'Running' -and $_.StartType -eq 'Automatic' }
$nonMS = $allRunning | Where-Object { $_.Name -notin $msServices }
$nonMS | ForEach-Object {
    $mem = (Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue).PrivateMemorySize64
    $memMB = if ($mem) { "$([math]::Round($mem/1MB))MB" } else { "N/A" }
    Write-Host "  $($_.Name) | $($_.DisplayName) | ${memMB}"
}

# --- 8. Processes > 30MB ranked ---
Write-Host "`n--- Processes > 30MB Private Memory ---"
Get-Process | Where-Object { $_.PrivateMemorySize64 -gt 30MB } |
    Select-Object Name,Id,@{N='MB';E={[math]::Round($_.PrivateMemorySize64/1MB)}} |
    Sort-Object MB -Descending |
    ForEach-Object { Write-Host "  $($_.Name) (PID=$($_.Id)): $($_.MB)MB" }

# --- 9. Startup Impact ---
Write-Host "`n--- Startup Programs (from Registry) ---"
$runPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
)
foreach ($rp in $runPaths) {
    $entries = Get-ItemProperty $rp -ErrorAction SilentlyContinue
    if ($entries) {
        $entries.PSObject.Properties | Where-Object { $_.Name -notin @('PSPath','PSParentPath','PSChildName','PSDrive','PSProvider') } | ForEach-Object {
            Write-Host "  [$rp] $($_.Name) -> $($_.Value)"
        }
    }
}

# --- 10. Visual Effects ---
Write-Host "`n--- Visual Effects ---"
$vf = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -ErrorAction SilentlyContinue
if ($vf) { Write-Host "VisualFXSetting: $($vf.VisualFXSetting)" }

# --- 11. Background Apps ---
Write-Host "`n--- Background Apps ---"
$bgApps = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -ErrorAction SilentlyContinue
if ($bgApps) {
    $bgApps.PSObject.Properties | Where-Object { $_.Name -notin @('PSPath','PSParentPath','PSChildName','PSDrive','PSProvider') } | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Value)"
    }
}
$globalBg = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -ErrorAction SilentlyContinue
Write-Host "  LetAppsRunInBackground: $($globalBg.LetAppsRunInBackground)"

# --- 12. Reserved Storage ---
Write-Host "`n--- Reserved Storage ---"
$rs = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" -ErrorAction SilentlyContinue
if ($rs) { Write-Host "  ShippedWithReserves: $($rs.ShippedWithReserves)" }

Write-Host "`n============================================"
Write-Host "  Audit Complete"
Write-Host "============================================"
