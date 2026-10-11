---
title: 第 1 周：安装与系统初识
slug: ubuntu-install-bootstrap
date: 2026-10-12
tags: [安装, SSH, netplan, apt, 第1周]
summary: 从零安装 Ubuntu Server 24.04，完成首次配置、联网与 SSH 远程登录，建立"能上手的机器"。
---

<p class="week-badge">WEEK 01 · 入门阶段</p>

## 本周目标

- 用 ISO / cloud-init 装好一台 Ubuntu Server 24.04
- 理解安装过程中的关键选择（分区、LVM、网络、最小化安装）
- 完成首次联网配置与系统更新
- 开启 SSH 远程登录，从主机连进去

> 验收标准：拔掉显示器网线，只用 SSH 也能完成全部后续操作。

## 安装方式怎么选

| 方式 | 场景 | 特点 |
| --- | --- | --- |
| **Server ISO（手动）** | 物理机 / 标准虚拟机 | 图形安装向导，最贴近生产装机 |
| **Cloud image + cloud-init** | 云、批量部署 | 镜像预装，user-data 注入配置，可复制 |
| **Multipass** | 本机快速实验 | 一条命令起实例，适合练手 |

物理机/标准虚机推荐 **Server ISO + LVM**；云上和批量场景认准 **cloud image**。

## ISO 安装的关键选择

1. **Installer 更新**：联网时建议更新 installer，少踩已知 bug。
2. **磁盘分区**：选 **LVM**，留出扩盘余地；单盘也可全盘 LVM。
3. **存储加密**：物理机/笔记本选 LUKS；云主机一般用平台盘加密。
4. **网络**：DHCP 起步，静态 IP 以后用 netplan 配（第 7 周细讲）。
5. **Profile**：勾选 **Ubuntu Server (minimal)**，只装最小集合，按需再加。
6. **SSH**：**务必勾选 Install OpenSSH server**——否则装完没法远程连。
7. **首个用户**：记好用户名和密码；它会自动进 `sudo` 组。

## 首次启动：更新系统

```bash
# 切到 root 或用 sudo
sudo apt update && sudo apt upgrade -y

# 看版本
lsb_release -a
# No LSB modules are available.
# Distributor ID: Ubuntu
# Description:    Ubuntu 24.04.x LTS
# Release:        24.04
# Codename:       noble

# 内核版本
uname -r
```

## 配置静态 IP（netplan 速览）

```bash
# 看网卡名
ip -br link

# 编辑 netplan 配置（文件名因机器而异）
sudo nano /etc/netplan/50-cloud-init.yaml
```

静态 IP 示例：

```yaml
network:
  version: 2
  ethernets:
    enp5s0:
      dhcp4: no
      addresses: [192.168.1.20/24]
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [223.5.5.5, 1.1.1.1]
```

```bash
sudo netplan try      # 试配置，120s 不确认自动回滚
sudo netplan apply    # 确认生效
```

## 开启并验证 SSH

```bash
# 安装时勾选过的话已经装好，确认状态
sudo systemctl status ssh
sudo systemctl enable --now ssh

# 看监听端口
ss -tlnp | grep :22
```

## 实战任务

1. 用 ISO 装一台 Ubuntu Server 24.04（虚拟机即可），勾选 LVM 与 OpenSSH。
2. 装完后用 netplan 配静态 IP，`netplan try` 验证后 apply。
3. 在主机生成 SSH 密钥：`ssh-keygen -t ed25519`，用 `ssh-copy-id` 推到服务器。
4. 实现**免密 SSH 登录**，并验证 `sudo` 仍需密码。

## 命令速查

| 命令 | 作用 |
| --- | --- |
| `lsb_release -a` | 查看发行版版本 |
| `uname -r` | 查看内核版本 |
| `apt update` | 刷新软件源索引 |
| `apt upgrade -y` | 升级已装软件 |
| `netplan try / apply` | 应用网络配置 |
| `ss -tlnp` | 查看监听端口 |
| `ssh-keygen -t ed25519` | 生成密钥对 |
| `ssh-copy-id user@host` | 推送公钥实现免密 |

## 常见坑

- **装完连不上 SSH**：多半是装机时没勾 OpenSSH server，`sudo apt install openssh-server` 补上。
- **netplan apply 后失联**：永远先 `netplan try`，它会自动回滚。
- **磁盘只在根分区塞满**：装机没选 LVM，后期扩容很痛。务必备选 LVM。
- **`apt update` 报 403/超时**：换国内源（第 5 周讲），或检查 DNS。

## 参考资料

- Ubuntu Server 官方安装指南：https://ubuntu.com/server/docs/installation
- netplan 参考：https://netplan.readthedocs.io/
- Multipass：https://multipass.run/

---

下一步：[第 2 周 · 命令行与 Shell 精通](ubuntu-cli-shell-mastery.html)。机器能用了，接下来让命令行变成你的手。