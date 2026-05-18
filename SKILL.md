---
name: memory-cleanup-master
description: Windows 内存清理大师。当用户遇到开机内存占用高、非分页池泄漏、无用后台进程/服务/计划任务占内存时触发。扫描并禁用已知 bloatware（华硕/QQ/WPS/NVIDIA/罗技等），修复驱动内存泄漏。核心原则：扫描激进，禁用保守，每次生成还原脚本。触发词：内存占用高、开机内存、清理内存、内存优化、禁用无用服务、non-paged pool。
---

# Memory Cleanup Master — Windows 内存清理大师

## 核心原则

1. **扫描激进，禁用保守**
   - 扫描：全量抓取进程、服务、计划任务、Run keys、非分页池
   - 禁用：仅禁用已知 bloatware 和无风险项，不碰用户工作进程
2. **每次生成还原脚本**
   - 任何修改操作之前，先构建可逆方案
   - 还原脚本放在桌面 `memory_restore.ps1`
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

## NDU 泄漏修复（高频问题）

Windows Network Data Usage 驱动 `Ndu.sys` 是非分页池泄漏的首要原因。

**症状：** 非分页池 1-3+ GB，Task Manager 不归因到任何进程，开机即开始增长。

**修复：**
```powershell
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndu" /v Start /t REG_DWORD /d 4 /f
```
重启生效。影响：设置里的流量统计变为空白，网络功能不受影响。

## 脚本清单

- `scripts/scan_memory.ps1` — 全量扫描，输出内存全景报告
- `scripts/cleanup_memory.ps1` — 执行清理，自动生成还原脚本
- `references/known_bloat.md` — 已知 bloatware 模式参考

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
