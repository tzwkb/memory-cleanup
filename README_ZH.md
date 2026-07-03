# Memory Cleanup Master

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Agent Skill](https://img.shields.io/badge/Agent%20Skill-Codex-blue.svg)](SKILL.md)
[![PowerShell](https://img.shields.io/badge/PowerShell-scripts-5391FE.svg)](https://learn.microsoft.com/powershell/)

[English](README.md) | 中文

## 概览

Windows 内存清理 Agent Skill，用于排查开机内存占用高、非分页池泄漏、后台进程/服务/计划任务占用，并生成可回滚优化方案。

## 主要能力

- 扫描内存压力、启动项、服务、计划任务和非分页池。
- 按风险保守分类，避免影响用户工作进程或系统核心服务。
- 修改前保留回滚脚本。

## 使用方式

按 SKILL.md 和 README 中的扫描脚本执行，再确认可禁用项。

## 注意事项

默认扫描激进、禁用保守。
