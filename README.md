# Memory Cleanup Master

English | [中文](README_ZH.md)


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
