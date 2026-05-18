---
name: memory-cleanup-master
description: Windows 内存清理大师。当用户遇到开机内存占用高、非分页池泄漏、无用后台进程/服务/计划任务占内存时触发。扫描并禁用已知 bloatware（华硕/QQ/WPS/NVIDIA/罗技等），修复驱动内存泄漏。核心原则：扫描激进，禁用保守，每次生成还原脚本。触发词：内存占用高、开机内存、清理内存、内存优化、禁用无用服务、non-paged pool。
---

# Memory Cleanup Master — Windows 内存清理大师

## 核心原则

1. **扫描激进，禁用保守**
   - 扫描：全量抓取进程、服务、计划任务、Run keys、非分页池
   - 禁用：仅禁用已知 bloatware 和无风险项，不碰用户工作进程
2. **每次修改后立即更新还原脚本**
   - 还原脚本固定路径：`$env:USERPROFILE\Desktop\memory_restore.ps1`
   - 任何禁用/修改操作执行后，同步更新还原脚本，覆盖所有历史改动
   - 还原脚本覆盖：服务（含 NDU）、计划任务、Run keys、注册表（内存压缩、页面文件）
   - 不另外建 `restore_services.ps1` 等多个还原文件，全部合并到 `memory_restore.ps1`
3. **重启前不报最终结果**
   - 禁用操作需重启生效，重启前展示的是当前状态

## 安全分级

| 级别 | 含义 | 示例 |
|------|------|------|
| 🟢 安全 | 已知无用，禁了不影响功能 | ASUS bloat, DiagTrack, DoSvc, PnkBstrA, NDU fix |
| 🟡 有影响 | 禁了丢功能，但功能可能不需要 | WSearch (搜索变慢), SysMain (SSD 无影响), Windows Hello |
| 🔴 禁止 | 用户正在使用或系统核心 | Claude, WSL, 用户打开的 Python 脚本, RpcSs, DcomLaunch |

## 标准工作流程

### Step 1: 扫描

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .claude/skills/memory-cleanup-master/scripts/scan_memory.ps1
```

输出包括：
- 总内存/可用内存/使用率
- 非分页池大小及泄漏警告 (>500MB)
- NDU 状态
- WSL VM 内存
- Top 25 进程按 Private Memory 排序
- 已知 bloatware 服务列表
- 未分类的非 MS 自启服务
- Run Keys
- 非 MS 计划任务

### Step 2: 分析

对照 `references/known_bloat.md` 分类：
- 命中已知模式 → 🟢 或 🟡
- 未分类服务 → 检查 DisplayName 和 PathName，判断是否安全
- 用户工作进程 → 🔴 排除

**Non-paged pool > 500 MB → 优先修复：**
1. 检查 NDU 状态
2. 如果 NDU 已禁但泄漏仍在 → 查 Wi-Fi/网卡驱动（MediaTek MT7921、Killer 已知泄漏）

### Step 3: 向用户呈现

用表格展示：
- 进程大户（哪些在吃内存）
- 非分页池状态
- 可禁服务（按 🟢🟡 分级）
- 可禁计划任务
- 可删 Run keys

让用户决定处理哪些。批量指令"全禁"可直接执行全部 🟢 项，🟡 项逐项确认。

### Step 4: 执行清理

```powershell
# 禁用指定服务
powershell -NoProfile -ExecutionPolicy Bypass -File .claude/skills/memory-cleanup-master/scripts/cleanup_memory.ps1 -Services 'ASUS','NVIDIA','QQ' ...

# 禁用 NDU
powershell -NoProfile -ExecutionPolicy Bypass -File .claude/skills/memory-cleanup-master/scripts/cleanup_memory.ps1 -DisableNdu

# 预览模式
powershell -NoProfile -ExecutionPolicy Bypass -File .claude/skills/memory-cleanup-master/scripts/cleanup_memory.ps1 -DryRun -Services 'ASUS'
```

`cleanup_memory.ps1` 参数：
- `-Services` — 服务名列表，支持类别名（ASUS/NVIDIA/QQ/WPS/Logitech/Other 批量展开）
- `-Tasks` — 计划任务名列表
- `-RunKeyNames` — Run key 名列表
- `-DisableNdu` — 修复 NDU 泄漏
- `-DryRun` — 预览模式
- `-RestoreScriptPath` — 还原脚本路径

### Step 5: 验证

- 重启后重新扫描，对比禁用前后
- 确认非分页池回落到 500MB 以下
- 确认待机内存下降

## 重启后复查清单

部分服务重启后可能恢复 Auto 状态，需重新扫描确认：

| 项目 | 检查方式 |
|------|----------|
| RadeonSoftware.exe | 进程列表不应出现 |
| DoSvc | 常被 Windows 恢复为 Auto |
| AMD External Events Utility | 驱动安装可能重新启用 |
| Widgets | 不应有相关进程 |
| msedgewebview2 扩散 | 不应超过 3 个实例 |
| 计划任务 | 不应有新的 Ready 任务 |
| 非分页池 | NDU 已禁 + MT7921 新驱动 → 应 < 500MB |

## NDU 泄漏修复（高频问题）

Windows Network Data Usage 驱动 `Ndu.sys` 是非分页池泄漏的首要原因。

**症状：** 非分页池 1-3+ GB，Task Manager 不归因到任何进程，开机即开始增长。

**修复：**
```powershell
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndu" /v Start /t REG_DWORD /d 4 /f
```
重启生效。影响：设置里的流量统计变为空白，网络功能不受影响。

## MT7921 Wi-Fi 驱动泄漏（ASUS TUF/ROG 笔记本高频）

MediaTek MT7921 旧版驱动会持续泄漏非分页池。NDU 禁用后仍 >500MB 时优先排查。

**检查：**
```powershell
Get-NetAdapter | Where-Object { $_.InterfaceDescription -match 'MT7921' }
```
当前版本若 < `25.x` 则需更新。

**修复流程：**
1. 打开 [Microsoft Update Catalog](https://www.catalog.update.microsoft.com/Search.aspx?q=MediaTek+MT7921+Wireless+LAN+Driver+Windows+11)
2. 按 Last Updated 排序，下载最新 `.cab` 文件
3. 解包安装：
```powershell
C:\Windows\System32\expand.exe <cab文件> -F:* C:\MT7921_Driver
pnputil /add-driver C:\MT7921_Driver\mtkwl6ex.inf /install
```
4. 重启生效。注意：CAB 解包必须用完整路径 `C:\Windows\System32\expand.exe`，否则 bash 的 `expand` 会冲突。

## AMD 显卡驱动纯净化（去 Adrenalin）

RadeonSoftware (~250MB) 由 AMD 内核驱动直接拉起，禁服务无用。根治方式：

1. 从 [AMD 官网](https://www.amd.com/en/support) 下载最新 Adrenalin 驱动 `.exe`
2. 运行一次安装器让它解包到 `C:\AMD\`（出现安装向导后关闭）
3. 找到 `C:\AMD\...\Packages\Drivers\Display\WT6A_INF\*.inf`
4. 注入纯驱动：
```powershell
pnputil /add-driver C:\AMD\AMD-Software-Installer\Packages\Drivers\Display\WT6A_INF\u*.inf /install
```
5. 重启后 RadeonSoftware 不再启动。需要面板时重装完整 Adrenalin 即可。

## 还原脚本覆盖范围

`Desktop/memory_restore.ps1` 必须覆盖所有修改类型：

| 修改类型 | 还原方式 |
|----------|----------|
| 禁用服务 (Set-Service) | `Set-Service -StartupType Automatic` |
| 禁用 NDU (注册表) | `reg add ... Ndu ... /d 2` |
| 启用内存压缩 (注册表) | `Set-ItemProperty ... EnableCompression -Value 0` |
| 页面文件迁移 (CIM) | `Remove-CimInstance` C: + `Set-CimInstance` E: |
| 禁用计划任务 | `Enable-ScheduledTask -TaskName` (含完整路径) |
| 删除 Run keys | `Set-ItemProperty` 恢复原始值 |

## 脚本清单

| 脚本 | 用途 |
|------|------|
| `scripts/scan_memory.ps1` | 全量扫描，输出内存全景报告 |
| `scripts/cleanup_memory.ps1` | 执行服务/任务/Run key 清理，自动生成还原脚本 |
| `scripts/kill_bloat.ps1` | 杀掉已知 bloatware 进程 |
| `scripts/kill_search.ps1` | 杀掉 SearchHost / StartMenu / TextInputHost 等惰性进程 |
| `scripts/audit_full.ps1` | 深度审计：内存压缩、页面文件、非 MS 服务、启动项、进程树 |
| `scripts/squeeze.ps1` | 扫描剩余优化目标（进程 >20MB、webview 父进程、ASUS 复活检测） |
| `scripts/squeeze_kill.ps1` | 批量杀 webview 链 + Widgets + PhoneExperienceHost + 改 FontCache/CDP/透明度 |
| `scripts/permanent_disable.ps1` | Widgets 组策略永久禁用 + Phone Link 卸载 + 重启 explorer |
| `scripts/find_respawns.ps1` | 诊断进程复活源（Run key / 任务 / 服务） |
| `scripts/check_gpu.ps1` | 查询 GPU 型号和驱动版本 |
| `scripts/download_amd.ps1` | 下载 AMD 驱动（可能被 CDN 拦） |
| `scripts/install_amd_driver_only.ps1` | 提取 AMD 驱动包，pnputil 注入纯驱动（无 Adrenalin） |
| `scripts/update_driver.ps1` | 检查 MT7921 Wi-Fi 驱动状态 |
| `references/known_bloat.md` | 已知 bloatware 模式 + 复活机制说明 + 优化技术参考 |
| `Desktop/memory_restore.ps1` | **唯一还原脚本，每次修改后同步更新** |

## 输出模板

### 扫描报告
```
========== Memory Scan Report ==========
Total RAM: 15.2 GB | Available: 2.1 GB | Usage: 86%
Non-Paged Pool: 1680 MB *** WARNING: >500MB ***
NDU: auto  *** FIX REQUIRED ***
WSL VM Memory: 4100 MB

--- Top 10 Processes ---
(full list)

--- Known Bloatware (X services) ---
| Service | Category | Risk |
(full list)

--- Run Keys (Y entries) ---
(full list)
========== End Report ==========
```

### 清理建议表
| 类别 | 项 | 风险 | 说明 |
|------|-----|------|------|
| ... | ... | 🟢/🟡 | ... |

### 清理后汇总
| 操作 | 数量 |
|------|------|
| 禁用服务 | N |
| 禁用任务 | N |
| 删除 Run key | N |
| 注册表修复 | N |
| 预计释放 | ~X GB |
| 还原脚本 | Desktop/memory_restore.ps1 |

## 进程复活机制与根治手段

本节记录已遇到的顽固进程及复活原理。

| 进程 | 复活机制 | 根治手段 |
|------|----------|----------|
| **RadeonSoftware** (~250MB) | AMD 显卡内核驱动 (`amdwddmg.sys`) 直接拉起用户态控制面板。AMD External Events Utility 服务禁了也没用，驱动层无视服务状态 | 安装 AMD 驱动时选 **Driver Only**（pnputil 注入纯驱动 INF），不装 Adrenalin 控制面板 |
| **asus_framework** (~90MB ×4) | `ArmourySocketServer.exe` 是父进程守护者。asus_framework 是 Electron 应用，ArmourySocketServer 监控并复活它 | 先杀 ArmourySocketServer 再杀 asus_framework；禁用 `\ASUS\ArmourySocketServer` 计划任务 |
| **msedgewebview2** (可达 500MB+) | Widgets / SearchHost 各启动一个父 webview，父 webview 再链式启动多个子 webview | 禁用 Widgets（组策略 `HKLM\SOFTWARE\Policies\Microsoft\Dsh`）；SearchHost 无解（任务栏搜索） |
| **Widgets** (~17MB + webview 链) | Windows Shell 体验主机按用户交互触发启动 | 组策略注册表 `AllowNewsAndInterests=0`，永久禁用 |
| **PhoneExperienceHost** (~48MB) | 预装 Phone Link App，用户登录时自动后台启动 | 卸载 AppxPackage: `Remove-AppxPackage *YourPhone*` |
| **SearchHost** (~47MB) | 任务栏搜索框，用户任何任务栏交互都会重启 | 无法根治。杀了随时点搜索框即复活 |
| **StartMenuExperienceHost** (~67MB) | 开始菜单，点击即重启 | 同上 |
| **TextInputHost** (~28MB) | 文本输入/触摸键盘，焦点到文本框即重启 | 同上 |

## PowerShell 调用规范

**严禁** `-Command` 传含 `$_` / `$_.` / `$(` 的代码，bash 会吃掉这些变量。

```powershell
# ❌ 错误：bash 把 $_ 解析为自己的特殊变量
powershell -Command "Get-Process | Where-Object { $_.Name -match 'foo' }"

# ✅ 正确：脚本文件，PowerShell 直接解析
powershell -File script.ps1
```

如果逻辑简单，可用 `-Command` 但避免 `$_` 和 `{}` 内的 `$`。需要复杂过滤时，**一律写成 `.ps1` 脚本文件再 `-File` 执行**。

## CDN 下载限制

AMD（Akamai）和 ASUS（阿里云 CDN）的驱动下载链接从终端直接下载会被 403/拦截：

| 来源 | CDN | curl | wget | IWR | BITS |
|------|-----|------|------|-----|------|
| AMD drivers.amd.com | Akamai | ❌ 403 | ❌ 403 | ❌ 403 | ❌ 403 |
| ASUS dlcdnets.asus.com | 阿里云 | ❌ | ❌ | ❌ | 未测 |

**唯一可靠方式：** `Start-Process <url>` 打开浏览器，用户手工点下载按钮。下载完成后脚本接管后续操作。

## 优化大招（优先级从高到低）

| 优先级 | 操作 | 预期收益 | 风险 |
|--------|------|----------|------|
| 🔴 最高 | 启用内存压缩 | 等效 +2-3 GB | 零（Windows 10/11 默认就该开） |
| 🔴 最高 | NDU 禁用 | 修复非分页池泄漏主因 | 极低（流量统计变空白） |
| 🟡 高 | 杀 RadeonSoftware | ~250 MB | 无面板调不了独显直连等 |
| 🟡 高 | 页面文件 HDD→SSD | IO 性能提升 | 零（纯收益） |
| 🟢 中 | msedgewebview2 清理 | 100-500 MB | 相关 App 的 Web 界面失效 |
| 🟢 中 | 禁用 Widgets | ~20 MB + webview 链 | 看不到资讯卡片 |
| 🟢 中 | 卸载 Phone Link | ~50 MB | 不能 PC 接手机 |
| 🔵 低 | 禁用计划任务/服务 | 50-200 MB | 各组件更新/功能丢失 |
