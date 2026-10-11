---
title: Ubuntu Server 学习路线图
slug: ubuntu-server-roadmap
date: 2026-10-05
tags: [路线图, 总览, Ubuntu Server]
summary: 14 周从入门到胜任的 Ubuntu Server 技能提升地图——每周一专题，配实战命令与练习任务。
---

<p class="week-badge">总览 · 学习地图</p>

## 为什么是 14 周

Ubuntu Server 是云、容器、边缘设备最常见的主机系统。要"胜任"它，不是背几条命令，而是建立一条**从安装到自动化运维**的完整能力链。这份路线图把核心技能拆成 **14 个周专题**，每周聚焦一个主题，配可上手的命令与练习任务，刻意追求"练得会、记得住、查得到"。

> 节奏建议：周一读知识点 → 周二到周四动手练命令 → 周五做实战任务 → 周末复盘写笔记。

## 14 周学习地图

| 周次 | 专题 | 核心能力 | 难度 |
| --- | --- | --- | --- |
| 总览 | 学习路线图 | 全局视野 | ★ |
| 第 1 周 | [安装与系统初识](ubuntu-install-bootstrap.html) | 装好、联网、能 SSH | ★ |
| 第 2 周 | [命令行与 Shell 精通](ubuntu-cli-shell-mastery.html) | 管道、重定向、文本三剑客 | ★★ |
| 第 3 周 | [用户、组与权限](ubuntu-users-permissions.html) | 账号、sudo、ACL | ★★ |
| 第 4 周 | [文件系统与存储管理](ubuntu-filesystem-storage.html) | 分区、LVM、挂载 | ★★★ |
| 第 5 周 | [软件包与 APT](ubuntu-apt-packaging.html) | apt、deb、源、snap | ★★ |
| 第 6 周 | [进程与 systemd 服务管理](ubuntu-systemd-services.html) | unit、timer、journalctl | ★★★ |
| 第 7 周 | [网络配置](ubuntu-networking.html) | netplan、ip、路由、DNS | ★★★ |
| 第 8 周 | [SSH 与远程访问安全](ubuntu-ssh-remote-access.html) | sshd、密钥、跳板 | ★★ |
| 第 9 周 | [防火墙与安全加固](ubuntu-security-hardening.html) | ufw、fail2ban、最小化 | ★★★ |
| 第 10 周 | [性能监控与调优](ubuntu-performance-monitoring.html) | top、atop、iostat | ★★★ |
| 第 11 周 | [日志与故障排查](ubuntu-logs-troubleshooting.html) | journald、strace、tcpdump | ★★★ |
| 第 12 周 | [容器与虚拟化](ubuntu-containers-virtualization.html) | LXD、Docker、KVM | ★★★ |
| 第 13 周 | [自动化运维](ubuntu-automation-ansible.html) | Bash 脚本、Ansible | ★★★ |
| 第 14 周 | [备份与灾难恢复](ubuntu-backup-recovery.html) | rsync、tar、timeshift | ★★ |

## 四个阶段，能力递进

整张地图可以分成四个阶段，前面是后面地基：

| 阶段 | 周次 | 你能做什么 |
| --- | --- | --- |
| **入门** | 第 1–3 周 | 独立装机、联网、用命令行完成日常管理 |
| **系统** | 第 4–7 周 | 管磁盘、装软件、起服务、配网络，让机器"可用" |
| **稳健** | 第 8–11 周 | 安全加固、监控性能、排查故障，让机器"靠谱" |
| **进阶** | 第 12–14 周 | 用容器与自动化提升效率，用备份兜底 |

## 怎么用这份路线图

1. **按周学**：右下角悬窗列出全部 15 个专题，点击直达本周页面。
2. **动手为主**：每篇都有「实战任务」，强烈建议在虚拟机 / 云主机上真练。
3. **建笔记库**：把每周踩的坑、好用的命令记下来，胜过看十遍教程。
4. **可跳可回头**：有基础的可以跳着读，但第 6/7/9/11 周是硬骨头，别省。

## 实验环境建议

| 方案 | 适用 | 说明 |
| --- | --- | --- |
| Multipass | 本机最快 | Ubuntu 官方虚拟机工具，一条命令起实例 |
| Vagrant + VirtualBox | 多机拓扑 | 练网络/集群时多机方便 |
| 云主机（公有云） | 接近生产 | 有公网 IP，练 SSH/防火墙最真实 |
| WSL2 | 轻体验 | Windows 上练命令行够用，但 systemd/网络受限 |

> 推荐主线：**Multipass 本机练 → 公有云小机器验证 → 笔记沉淀**。

```bash
# Multipass 一键起一台 Ubuntu 24.04 实例并进入
multipass launch --name lab --cpus 2 --mem 2G --disk 10G 24.04
multipass shell lab
```

---

下周开始：[第 1 周 · 安装与系统初识](ubuntu-install-bootstrap.html)。装好一台机器，让它能联网、能 SSH，是后面一切的基础。