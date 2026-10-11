---
title: 第 7 周：网络配置
slug: ubuntu-networking
date: 2026-10-12
tags: [netplan, ip, 路由, DNS, 第7周]
summary: 用 netplan 配静态 IP、用 ip 管路由、用 systemd-resolved 搞 DNS，系统化掌握 Ubuntu 网络配置。
---

<p class="week-badge">WEEK 07 · 系统阶段</p>

## 本周目标

- 用 netplan 配置静态 IP、多网卡、VLAN
- 用 `ip` 命令查链路、地址、路由
- 理解 systemd-resolved 与 DNS 解析
- 排查"能 ping IP 但 ping 不通域名"类问题

> 验收标准：给双网卡机器配好静态 IP 与默认路由，并解释 DNS 怎么从网卡配置流到 /etc/resolv.conf。

## 看网络现状

```bash
ip -br link                 # 网卡与状态
ip -br addr                 # 地址
ip route                    # 路由表
ip -6 route

# DNS
resolvectl status
cat /etc/resolv.conf
```

## netplan：Ubuntu 网络配置入口

netplan 是声明式配置，文件在 `/etc/netplan/*.yaml`，渲染到后端（默认 systemd-networkd 或 NetworkManager）。**YAML 缩进必须用空格**。

```yaml
# /etc/netplan/60-static.yaml
network:
  version: 2
  renderer: networkd
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
sudo netplan try      # 试 120s，不确认自动回滚（远程改网络的命根子）
sudo netplan apply
```

## 双网卡与默认路由

不同网卡不要都写 `to: default`，只留一条默认路由；另一条用策略路由或特定网段：

```yaml
network:
  version: 2
  ethernets:
    enp5s0:                 # 业务网卡 → 默认出网
      dhcp4: no
      addresses: [10.0.0.20/24]
      routes:
        - to: default
          via: 10.0.0.1
    enp6s0:                 # 管理网卡 → 只回管理网段
      dhcp4: no
      addresses: [192.168.10.20/24]
      routes:
        - to: 192.168.10.0/24
          via: 192.168.10.1
```

## DNS 链路

现代 Ubuntu 用 **systemd-resolved** 做 DNS 缓存/调度：

```
netplan nameservers → systemd-resolved → /run/systemd/resolve/resolv.conf
                                      ↑
                      /etc/resolv.conf 软链到这里
```

```bash
resolvectl status            # 看每网卡的 DNS
resolvectl query example.com # 手动解析
ls -l /etc/resolv.conf       # 应是指向 stub 的软链
```

> `/etc/resolv.conf` 若被人为改成普通文件，重装 resolved 软链：`sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf`。

## 排查工具箱

```bash
# 二层：链路通不通
ping -c3 192.168.1.1

# 三层：路由对不对
ip route get 8.8.8.8
traceroute 8.8.8.8

# DNS：名字解得出来吗
dig example.com
dig @8.8.8.8 example.com

# 端口：服务在听吗、防火墙放了吗
ss -tlnp | grep :80
sudo ufw status
```

## 实战任务

1. 给机器配静态 IP（含默认路由与 DNS），`netplan try` 验证后 apply。
2. 配双网卡：业务网卡默认路由 + 管理网卡只回管理网段，`ip route get` 验证走向。
3. 用 `resolvectl query` 解析一个域名，对照 `resolvectl status` 看用的是哪个 DNS。
4. 故意把 `/etc/resolv.conf` 改成普通文件写错 DNS，复现"能 ping IP 不能 ping 域名"，再修复软链。

## 命令速查

| 命令 | 作用 |
| --- | --- |
| `ip -br a` | 看地址 |
| `ip route` / `ip route get` | 看/查路由 |
| `netplan try/apply` | 应用网络配置 |
| `resolvectl status/query` | DNS 状态/解析 |
| `ss -tlnp` | 看监听端口 |
| `dig` / `traceroute` | DNS / 路径追踪 |

## 常见坑

- **netplan apply 后失联**：永远 `netplan try`，留 120s 后悔窗口。
- **YAML 缩进用 Tab**：netplan 直接报错，全用空格。
- **resolv.conf 被改死**：导致 DNS 永远错，认准软链。
- **双网卡都写默认路由**：流量乱跑，只留一条 default。

## 参考资料

- netplan：https://netplan.readthedocs.io/
- systemd-resolved：https://www.freedesktop.org/software/systemd/man/systemd-resolved.service.html

---

下一步：[第 8 周 · SSH 与远程访问安全](ubuntu-ssh-remote-access.html)。网络通了，远程管理入口要锁死。