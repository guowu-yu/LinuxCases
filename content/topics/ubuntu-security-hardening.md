---
title: 第 9 周：防火墙与安全加固
slug: ubuntu-security-hardening
date: 2026-10-12
tags: [ufw, fail2ban, 安全加固, 最小化, 第9周]
summary: 用 ufw 收紧端口、用 fail2ban 防爆破、做最小化与自动更新，建立纵深防御。
---

<p class="week-badge">WEEK 09 · 稳健阶段</p>

## 本周目标

- 用 ufw 配置默认拒绝 + 按需放行
- 用 fail2ban 拦截暴力破解
- 落地最小化原则：关多余服务、删多余账号
- 配 unattended-upgrades 自动打安全补丁

> 验收标准：改完 ufw 只放 2222 与 80；用 hydra 模拟爆破被 fail2ban 封 IP。

## 防火墙：ufw

ufw 是 iptables/nftables 的友好前端，生产单机够用。

```bash
sudo ufw enable                # 启用（先放行 SSH 再 enable，否则锁外面）
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 放行（改了端口的 SSH）
sudo ufw allow 2222/tcp

# 服务放行
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 53/tcp       # DNS
sudo ufw allow 53/udp

# 限流（防爆破）：同 IP 30 秒内最多 6 次连接
sudo ufw limit 2222/tcp

# 来源限制：只允许管理网段
sudo ufw allow from 192.168.10.0/24 to any port 2222

sudo ufw status verbose
sudo ufw reload
```

## fail2ban：封爆破者

读登录日志，多次失败就调用防火墙封 IP。

```bash
sudo apt install -y fail2ban
sudo nano /etc/faild2ban/jail.local
```

```ini
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd

[sshd]
enabled = true
port    = 2222
```

```bash
sudo systemctl restart fail2ban
sudo fail2ban-client status sshd       # 看封了谁
sudo fail2ban-client set sshd unbanip 1.2.3.4   # 解封
```

## 最小化：关该关的

```bash
systemctl list-unit-files --state=enabled
# 关掉不需要的，例如蓝牙、ModemManager（服务器用不到）
sudo systemctl disable --now bluetooth
sudo systemctl disable --now ModemManager

# 看哪些端口在听
ss -tlnp
# 每个开放的端口都要能回答：谁在用？必须开吗？
```

## 自动安全更新

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades   # 选 Yes
```

配置 `/etc/apt/apt.conf.d/50unattended-upgrades` 控制只装安全更新（默认即可）。生产关键服务建议测试后再开自动重启。

## 实战任务

1. ufw 设默认拒绝入站，仅放 2222、80、443，SSH 用 `limit`。
2. 装 fail2ban，配置 sshd jail，用 `hydra` 或脚本模拟失败登录，观察 IP 被封。
3. 列出所有开机自启服务，关掉 3 个服务器不需要的。
4. 开启 unattended-upgrades 自动安全更新。

## 命令速查

| 命令 | 作用 |
| --- | --- |
| `ufw allow/limit/deny` | 放行/限流/拒绝 |
| `ufw status verbose` | 看规则 |
| `fail2ban-client status` | 看封禁状态 |
| `ss -tlnp` | 看监听端口 |
| `systemctl disable --now unit` | 关闭并停用 |

## 常见坑

- **enable ufw 前没放 SSH**：直接把自己挡外面，只能去控制台救。
- **fail2ban 端口没对**：写了 `port=22` 但 SSH 已改 2222，封不到。
- **开了自动更新还自动重启**：业务被重启打断，关键服务关闭自动重启。
- **该关的没关**：暴露的管理端口越多，攻击面越大。

## 参考资料

- ufw：https://help.ubuntu.com/community/UFW
- fail2ban：https://github.com/fail2ban/fail2ban

---

下一步：[第 10 周 · 性能监控与调优](ubuntu-performance-monitoring.html)。安全圈起来了，得看机器跑得健不健康。