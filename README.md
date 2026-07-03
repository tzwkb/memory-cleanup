# Memory Cleanup Master

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Agent Skill](https://img.shields.io/badge/Agent%20Skill-Codex-blue.svg)](SKILL.md)
[![PowerShell](https://img.shields.io/badge/PowerShell-scripts-5391FE.svg)](https://learn.microsoft.com/powershell/)

English | [中文](README_ZH.md)


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
