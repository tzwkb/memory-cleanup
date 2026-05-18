# Known Windows Bloatware Patterns

## Services

### ASUS Laptop Bloat
All ASUS services are safe to disable. They control RGB lighting, system "optimization" (placebo), diagnostics (useless), and update checks.
- `ArmouryCrateControlInterface`
- `ArmouryCrateService`  
- `AsusAppService`, `AsusCertService`
- `ASUSOptimization`, `ASUSSoftwareManager`, `ASUSSwitch`
- `ASUSSystemAnalysis`, `ASUSSystemDiagnosis`
- `LightingService` — RGB control. Disabling reverts to hardware default mode.
- `ROG Live Service`, `GameSDK Service`
- Run key: `ASUS Smart Display Control`
- Tasks: `ASUS Optimization`, `ASUS Update Checker`, `AsusSystemAnalysis`, `ASUSUpdateTaskMachineCore/UA`, `P508PowerAgent_sdk`, `ArmourySocketServer`

### QQ / Tencent PC Manager
- `QQPCRTP` — Real-time protection. Windows Defender is sufficient.
- `qmbsrv` — Unknown QQ background service.

### WPS Office
- `wpscloudsvr` — Cloud sync service, 200+ MB private. Not needed for local use.
- Tasks: `WpsUpdateLogonTask_ASUS`, `WpsUpdateTask_ASUS`, `WpsWakeWnsLogonTask`

### Logitech G Hub
- `LGHUBUpdaterService` — Auto-updater.
- `logi_lamparray_service` — Lamp array (speaker lighting) service.
- Run key: `LGHUB`

### NVIDIA
- `NvContainerLocalSystem`, `NVDisplay.ContainerLocalSystem` — Overlay, ShadowPlay, telemetry containers. GPU driver works without these.
- Tasks: `NvTmRep_CrashReport*`, `NvProfileUpdater*`, `NVIDIA GeForce Experience SelfUpdate`, `NVIDIA App SelfUpdate`

### AMD
- `AMD Crash Defender Service` — Crash reporting, no functional impact.
- `AMD External Events Utility` — Needed for FreeSync, display detection on AMD laptops. Disabling loses FreeSync but GPU still works.

### Radmin VPN
- `RvControlSvc` — VPN control service.
- Run key: `RadminVPN` (GUI auto-start)

### Other Common Bloat
- `XLServicePlatform` — Xunlei download manager service.
- `WSAIFabricSvc` — Windows Subsystem for Android.
- `PnkBstrA` — PunkBuster anti-cheat (ancient games).
- `0store-service` — Zero Install package manager.
- `PCManager Service Store` — Microsoft PC Manager (Chinese edition).
- `WeType Management Service` — WeChat input method service.

## Windows Services (safe to disable on SSD systems)

| Service | What It Does | Impact of Disabling |
|---------|-------------|---------------------|
| `DiagTrack` | Microsoft telemetry | None |
| `DoSvc` | Delivery Optimization (P2P updates) | Updates download directly from Microsoft |
| `WpnService` | Push notifications | No toast notifications from apps |
| `WSearch` | Windows Search indexer | Search slower, but SSD makes up for it |
| `SysMain` | Superfetch prefetch | Minimal on SSD |
| `whesvc` | Windows Hello biometric login | No fingerprint/face login |
| `cbdhsvc_*` | Clipboard history (Win+V) | Ctrl+C/V still work |

## Kernel Driver Memory Leak

### NDU (Network Data Usage)
- `Ndu.sys` is the most common non-paged pool leak source on Windows 10/11.
- Fix: `reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndu" /v Start /t REG_DWORD /d 4 /f`
- Impact: Network data usage stats in Settings become blank. Networking unaffected.
- Normal non-paged pool: <500 MB. With NDU leak: 1-3+ GB.

### Other Known Leaky Drivers
- MediaTek Wi-Fi (MT7921) — update driver
- Killer Network Suite — uninstall, use default Windows driver
- Old Realtek audio drivers — update
