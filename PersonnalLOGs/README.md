# Ubuntu Server 技能提升 - 第一周

Ubuntu Server 上练习 Linux 运维技能的第一周学习计划，主题为 Nginx Web 服务器 + OpenSSH 安全加固。

## 文件说明

- `requirements.txt` — 依赖包清单（apt 包列表 + 说明）
- `install.sh` — 一键安装脚本（在服务器上用 sudo 运行）
- `week1-plan.md` — 7 天逐日学习计划

## 快速开始

```bash
# 在 Ubuntu Server 上执行
sudo bash install.sh

# 然后按 week1-plan.md 从 Day 1 开始
```

## 本周覆盖技能

- systemd 服务管理（start/stop/enable/reload/status）
- Nginx 配置：虚拟主机、静态托管、HTTPS
- OpenSSH 加固：密钥认证、禁用密码、端口控制
- ufw 防火墙配置
- fail2ban 防暴力破解
- 日志查看与排查（journalctl、access log）
- 网络诊断工具（nmap、tcpdump、dig）