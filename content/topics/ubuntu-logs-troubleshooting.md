---
title: 第 11 周：日志与故障排查
slug: ubuntu-logs-troubleshooting
date: 2026-10-12
tags: [journald, strace, tcpdump, 故障排查, 第11周]
summary: 用 journald/syslog 查日志，用 strace/tcpdump 定位"为什么挂了、为什么连不上"。
---

<p class="week-badge">WEEK 11 · 稳健阶段</p>

## 本周目标

- 熟练用 journald 与传统 syslog 查日志
- 用 strace 定位程序"卡哪、缺什么"
- 用 tcpdump 抓包分析"连不上"
- 建立可复用的故障排查回路

> 验收标准：服务起不来，你不靠猜，用日志+strace 5 分钟内定位根因。

## 日志体系

```
systemd 服务日志 → journald (/run/log/journal, /var/log/journal)
传统 syslog(如 cron/auth) → rsyslog → /var/log/*.log
通用应用日志 → 自己的目录，如 /var/log/nginx/
```

## journalctl 精查

```bash
journalctl -u app -f                    # 实时跟踪
journalctl -u app --since "10 min ago"
journalctl -p err                        # error 以上
journalctl -p warning -u app --since today
journalctl -b                            # 本次启动
journalctl -b -1                         # 上次启动
journalctl --no-pager -n 200 -u app      # 无分页，最近 200 行
```

## 传统日志

```bash
/var/log/syslog        # 系统通用
/var/log/auth.log      # 认证（登录、sudo）
/var/log/kern.log      # 内核
/var/log/dpkg.log      # 装包历史
```

## strace：程序在干什么

```bash
strace -f -e trace=openat,connect nginx 2>&1 | head
sudo strace -p $(pidof nginx) -f -e trace=network
```

> strace 看"卡哪、缺什么、连哪"。后台 `-f` 跟子进程，`-e trace=` 只看某类调用。

## tcpdump：网络在传什么

```bash
# 抓 80 端口流量
sudo tcpdump -i any port 80 -n

# 抓与某主机的握手
sudo tcpdump -i any host 10.0.0.5 and port 443 -n

# 存包用 wireshark 看
sudo tcpdump -i any port 443 -w debug.pcap
```

## 故障排查回路

| 现象 | 第一步 | 第二步 |
| --- | --- | --- |
| 服务起不来 | `systemctl status` + `journalctl -u` | 看 ExecStart 路径/权限 |
| 能 ping IP 不通域名 | `resolvectl status` / `dig` | 查软链、安全组 |
| 端口连不上 | `ss -tlnp` 看是否监听 | `ufw status` 看是否放行 |
| 磁盘满 | `df -h` | `du -xh / \| sort -rh \| head` |
| 被 OOM kill | `dmesg -T \| grep -i oom` | 加内存或限资源 |

## 实战任务

1. 故意把服务 ExecStart 写错，用 `systemctl status` + `journalctl` 定位。
2. 删一个程序依赖的配置文件，`strace` 看它 openat 失败。
3. 关掉 nginx 用 `tcpdump` 抓一次被拒的 80 连接，看 RST。
4. 制造磁盘写满（`fallocate -l 9G /tmp/big`），用 `du` 定位并清理。

## 命令速查

| 命令 | 作用 |
| --- | --- |
| `journalctl -u unit -f` | 跟踪服务日志 |
| `dmesg -T` | 内环消息 |
| `strace -f -e trace=...` | 跟踪系统调用 |
| `tcpdump -i any port N -n` | 抓包 |
| `du -xh / \| sort -rh \| head` | 找大目录 |
| `lsof -i :80` | 谁在用 80 |

## 常见坑

- **journald 丢了老日志**：默认 volatile 存储，重启就没；开 persistent 见 `man journald.conf`。
- **tcpdump 看不懂**：先 `-n` 关解析、加 `-c 20` 限量。
- **只看一份日志就下结论**：服务、systemd、auth 三处交叉看。

## 参考资料

- `man journalctl` / `man journald.conf`
- tcpdump 示例：https://tcpdump.org/

---

下一步：[第 12 周 · 容器与虚拟化](ubuntu-containers-virtualization.html)。单机排查够了，开始用容器提升部署效率。