---
title: 第 8 周：SSH 与远程访问安全
slug: ubuntu-ssh-remote-access
date: 2026-10-12
tags: [SSH, sshd, 密钥, 跳板机, 第8周]
summary: 硬化 sshd 配置、管理密钥与 known_hosts、用跳板机与端口转发，把远程入口守成铁桶。
---

<p class="week-badge">WEEK 08 · 稳健阶段</p>

## 本周目标

- 用密钥登录，禁用密码登录与 root 直登
- 改端口、限来源，硬化 sshd 配置
- 用 SSH 跳板机和端口转发做远程访问
- 会排查 SSH 登录失败、会话异常断开

> 验收标准：改完 sshd 后能稳定用密钥登录，且能解释每条加固项的意义与风险。

## 密钥与免密登录

```bash
# 本机生成 ed25519 密钥（推荐，比 RSA 短而安全）
ssh-keygen -t ed25519 -C "alice@laptop"

# 推送公钥到服务器
ssh-copy-id alice@192.168.1.20
# 或手动
cat ~/.ssh/id_ed25519.pub | ssh alice@host 'cat >> ~/.ssh/authorized_keys'
```

权限很关键，权限不对 sshd 会拒认：

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/id_ed25519
```

## 硬化 sshd_config

```bash
sudo nano /etc/ssh/sshd_config
# 改完先测语法再重启，防止把自己锁外面
sudo sshd -t
sudo systemctl restart ssh
```

关键加固项：

```
Port 2222                          # 改非标端口
PermitRootLogin no                 # 禁 root 直登
PasswordAuthentication no          # 禁密码（确认密钥能登后再开）
PubkeyAuthentication yes
AllowUsers alice deploy            # 白名单
MaxAuthTries 3
ClientAliveInterval 300            # 保活，防 NAT 断
ClientAliveCountMax 2
LoginGraceTime 20
X11Forwarding no
```

> **铁律**：改 sshd 时另开一个已登录的会话别关，`sshd -t` 通过再 restart，确认新会话能登，才关旧会话。

## SSH 跳板机（ProxyJump）

不通公网的机器，通过跳板机进：

```bash
# ~/.ssh/config
Host bastion
    HostName 1.2.3.4
    User alice
    Port 2222

Host db1
    HostName 10.0.0.55
    User deploy
    ProxyJump bastion
```

```bash
ssh db1    # 自动经 bastion 跳转
```

## 端口转发

```bash
# 本地转发：把远程的 3306 映射到本机 13306
ssh -L 13306:10.0.0.55:3306 bastion
mysql -h 127.0.0.1 -P 13306 -u root -p

# 远程转发：把本机的 8080 暴露到远程
ssh -R 8080:localhost:80 ssh-with.pub -N

# 动态转发（SOCKS 代理）
ssh -D 1080 bastion -N
```

## 排查登录失败

```bash
# 服务器端看 SSH 日志
sudo journalctl -u ssh -n 50 --no-pager

# 客户端详细调试
ssh -vvv alice@host

# 常见原因
# - authorized_keys 权限不对（最常见）
# - PasswordAuthentication 关了但密钥没配好
# - 防火墙/安全组没收 2222 端口
# - root 直登被禁但你正用 root 登
```

## 实战任务

1. 生成 ed25519 密钥，`ssh-copy-id` 推送，实现免密登录。
2. 改 SSH 端口为 2222，禁用密码与 root 直登；`sshd -t` 后重启，开新会话验证。
3. 配 `~/.ssh/config`，用 ProxyJump 经跳板机连内网机。
4. 用本地端口转发，从本机直连内网 MySQL。

## 命令速查

| 命令 | 作用 |
| --- | --- |
| `ssh-keygen -t ed25519` | 生成密钥 |
| `ssh-copy-id user@host` | 推公钥 |
| `sshd -t` | 测配置语法 |
| `ssh -L/R/D` | 本地/远程/动态转发 |
| `ProxyJump` | 跳板机 |
| `journalctl -u ssh` | 看登录日志 |

## 常见坑

- **把自己锁外面**：没开新会话验证就重启 sshd / 关旧会话。
- **关密码太早**：密钥没配好就 `PasswordAuthentication no`，瞬间登不进。
- **权限太松**：`~/.ssh` 或 `authorized_keys` 被 group 可写，sshd 静默拒认。
- **改端口忘了放行**：selinux/ufw/安全组没收新端口。

## 参考资料

- `man sshd_config`
- Mozilla SSH 加固指南：https://infosec.mozilla.org/guidelines/openssh

---

下一步：[第 9 周 · 防火墙与安全加固](ubuntu-security-hardening.html)。SSH 入口锁了，该把整台机器的防护做齐。