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
- `asus` / `asusm` — ASUS system service (starts asus_framework)
- Run key: `ASUS Smart Display Control`
- Tasks: `ASUS Optimization`, `ASUS Update Checker`, `AsusSystemAnalysis`, `ASUSUpdateTaskMachineCore/UA`, `P508PowerAgent_sdk`, `ArmourySocketServer`

**asus_framework 进程复活链:**
1. `ArmourySocketServer.exe` (PID 父进程) 是守护者
2. 杀 ArmourySocketServer 后 asus_framework 不再复活
3. 需同时: 杀 ArmourySocketServer → 杀 asus_framework 子进程 → 禁用 `\ASUS\ArmourySocketServer` 任务

**其他 ASUS 进程:**
- `AcPowerNotification` — 电源通知 (~29MB)，直接杀不复活

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

**RadeonSoftware 复活问题:**
- `RadeonSoftware.exe` (~250MB) 由 AMD 显卡内核驱动 `amdwddmg.sys` 直接启动
- `AMD External Events Utility` 禁了也没用，驱动层无视服务状态
- 根治：安装 AMD 驱动时选 **Driver Only**（pnputil 注入纯 INF），不装 Adrenalin 面板
- 手动杀只是暂时的，随时复活

### Radmin VPN
- `RvControlSvc` — VPN control service.
- Run key: `RadminVPN` (GUI auto-start)

### msedgewebview2 (WebView2 Runtime)
- 不是恶意软件，但会扩散到 10+ 实例，总内存可达 500MB+
- 每个使用 Web 界面的 App（Widgets、Search、Teams 等）启动自己的实例
- 父 webview 会链式启动子 webview
- Widgets → webview (51MB) → 5个子 webview (157MB)
- SearchHost → webview (50MB) → 6个子 webview (201MB)
- **处理：** 杀 Widgets + 禁 Widgets 组策略 = 断掉主要来源
- SearchHost 的 webview 链杀后随搜索框交互复活

### Windows Shell UI 进程
都是惰性重启的，杀了不影响系统，用时重新加载：
- `SearchHost` (~47MB) — 任务栏搜索
- `StartMenuExperienceHost` (~67MB) — 开始菜单
- `TextInputHost` (~28MB) — 文本输入/触摸键盘
- `PhoneExperienceHost` (~48MB) — Phone Link App，卸载后不再出现
- `Widgets` — 组策略可永久禁用

### Installer/Updater Tasks
纯更新任务，禁了不影响已安装软件使用：
- `\GoogleSystem\GoogleUpdater\GoogleUpdaterTaskSystem*` — Google 更新
- `\Mozilla\Firefox Background Update *` / `Firefox Default Browser Agent *` — Firefox 更新
- `\Zero Install\Self update` / `Update apps` — Zero Install 商店
- `MicrosoftEdgeUpdateTaskMachineCore/UA` — Edge 更新

### SoftLanding
软着陆系列 — 来源不明的计划任务，禁了无影响。多版本 GUID 共存：
- `\SoftLanding\...\SoftLandingCreativeManagementTask`
- `\SoftLanding\...\SoftLandingDeferralTask-{...}`
- GUID 格式可能变化，需扫描确认实际名称

### Other Common Bloat
- `XLServicePlatform` — Xunlei download manager service.
- `WSAIFabricSvc` — Windows Subsystem for Android.
- `PnkBstrA` — PunkBuster anti-cheat (ancient games).
- `0store-service` — Zero Install package manager.
- `PCManager Service Store` — Microsoft PC Manager (Chinese edition).
- `WeType Management Service` — WeChat input method service.
- `InventorySvc` — ASUS/厂商自定义服务（DisplayName 乱码），svchost -k InvSvcGroup，可安全禁用。

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

## Memory Optimization Techniques (non-service)

### Memory Compression
Windows 10/11 内置功能，等效扩容 2-3 GB，常被意外关闭。
- 检查: `Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name EnableCompression`
- 启用: `Set-ItemProperty ... -Name EnableCompression -Value 1`
- 重启生效

### Pagefile Location
ASUS 双硬盘笔记本常见问题：页面文件被放在 HDD (E:) 上。
- 检查: `Get-CimInstance Win32_PageFileUsage`
- DriveType 3=HDD, 5=SSD
- 修复: `Remove-CimInstance` HDD 页面文件 + `Set-CimInstance` SSD 系统管理

### Transparency Effects
- `HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize` → `EnableTransparency = 0`
- 节省少量显存/内存，即时生效

### Visual Effects
- `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects` → `VisualFXSetting = 0`
- 关闭动画和阴影，减少 dwm/explorer 内存占用

### CDPUserSvc (Connected Devices Platform)
- 始终自动启动，但可改为 Manual
- 影响: 跨设备剪贴板/通知同步失效
- 服务名含 SID 后缀，如 `CDPUserSvc_80581`
