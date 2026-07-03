# Memory Cleanup Master

<!-- bilingual-readme:start -->

## 双语说明 / Bilingual Documentation

> 本节提供整篇 README 的中英双语维护说明；下方保留原始详细说明、命令、路径和配置示例。
> This section provides bilingual maintenance notes for the full README; the original detailed notes, commands, paths, and configuration examples are preserved below.

### 中文

**概览**：Windows 内存清理 Agent Skill，用于排查开机内存占用高、非分页池泄漏、后台进程/服务/计划任务占用，并生成可回滚优化方案。

**主要能力**：
- 扫描内存压力、启动项、服务、计划任务和非分页池。
- 按风险保守分类，避免影响用户工作进程或系统核心服务。
- 修改前保留回滚脚本。

**使用方式**：按 SKILL.md 和 README 中的扫描脚本执行，再确认可禁用项。

**状态**：该仓库仍按当前 README 的说明维护或使用。

**注意事项**：默认扫描激进、禁用保守。

### English

**Overview**: Windows memory cleanup Agent Skill for diagnosing high startup memory, non-paged pool leaks, background processes/services/tasks, and rollback-safe optimization.

**Key capabilities**:
- Scans memory pressure, startup items, services, scheduled tasks, and non-paged pool usage.
- Classifies changes conservatively to avoid user work processes and Windows core services.
- Keeps rollback scripts before applying changes.

**Usage**: Run scan scripts from SKILL.md/README, then confirm which items may be disabled.

**Status**: This repository is maintained or used according to the current README notes.

**Notes**: The default posture is aggressive scanning and conservative disabling.

<!-- bilingual-readme:end -->

**Agent Skill** — Windows 内存清理大师，用于排查开机内存占用高、非分页池泄漏、无用后台进程/服务/计划任务，并生成可回滚的优化方案。

**Agent Skill** — Windows memory cleanup skill for high startup memory usage, non-paged pool leaks, background process/service/task triage, and rollback-safe optimization.

## Scope

- Scans memory pressure, startup/background processes, services, scheduled tasks, Run keys, and non-paged pool usage.
- Classifies changes conservatively and avoids user work processes or Windows core services.
- Generates a rollback script before applying service, task, Run key, or registry changes.
- Targets Windows 10/11 desktop cleanup and diagnostics.

## Usage

Install as an agent skill and invoke it when troubleshooting high memory usage, startup memory pressure, non-paged pool leaks, or unwanted background services.

## License

[MIT](LICENSE)