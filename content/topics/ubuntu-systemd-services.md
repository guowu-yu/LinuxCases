---
title: 第 6 周：进程与 systemd 服务管理
slug: ubuntu-systemd-services
date: 2026-10-12
tags: [systemd, systemctl, journalctl, timer, 第6周]
summary: 用 systemctl 管服务、用 journalctl 查日志、用 systemd timer 替代 cron，掌握现代服务管理。
---

<p class="week-badge">WEEK 06 · 系统阶段</p>

## 本周目标

- 理解进程、信号与前台/后台
- 用 systemctl 启停、开机自启、查状态
- 写一个自定义 systemd unit 与一个 systemd timer
- 用 journalctl 精准查日志

> 验收标准：把一个脚本做成开机自启服务，崩了自动拉起，并定时备份，全用 systemd 完成。

## 进程与信号速览

```bash
ps aux | grep nginx
pstree -p                  # 看进程树
top                        # 实时（或更友好的 htop）
kill -TERM 1234            # 优雅退出
kill -9 1234               # 强杀（SIGKILL，无法善后）
kill -HUP $(cat /var/run/nginx.pid)   # 重载配置
nohup ./app > app.log 2>&1 &          # 脱离终端后台跑
jobs / bg / fg
```

> 生产服务别用 `nohup &` 长期跑，交给 systemd 管理，才有重启、日志、开机自启。

## systemctl 管服务

```bash
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
sudo systemctl reload nginx        # 不断连接重载配置
sudo systemctl status nginx
sudo systemctl enable nginx        # 开机自启
sudo systemctl enable --now nginx  # 启用且立即启动
sudo systemctl disable nginx
systemctl list-units --type=service
systemctl list-unit-files --state=enabled    # 看哪些开机自启
systemctl daemon-reload           # 改了 unit 文件后必做
```

## 看懂一个 unit 文件

```bash
systemctl cat nginx
```

地址正式写法（自己写服务放 `/etc/systemd/system/`）：

```ini
# /etc/systemd/system/app.service
[Unit]
Description=My Python App
After=network.target

[Service]
Type=simple
User=app
WorkingDirectory=/srv/app
ExecStart=/usr/bin/python3 /srv/app/server.py
Restart=on-failure
RestartSec=3
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
```

| 字段 | 含义 |
| --- | --- |
| `Type=simple` | 前台进程，systemd 直接判定启动完成 |
| `Type=forking` | 服务会 fork 到后台（如老式 nginx） |
| `Restart=on-failure` | 非正常退出自动拉起 |
| `Restart=always` | 任何退出都拉起 |
| `WantedBy=multi-user.target` | 多用户（命令行）开机自启 |

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now app.service
```

## journalctl 查日志

systemd 把日志收到 journald，统一用 `journalctl` 查：

```bash
journalctl -u nginx                 # 某服务
journalctl -u nginx -f              # 实时跟踪
journalctl --since "10 min ago"     # 时间范围
journalctl -p err                   # 只要 error 以上
journalctl -k                       # 内核日志
journalctl --since today -u app
```

## 用 systemd timer 替代 cron

比 cron 更强：有依赖、有日志、能看上次运行状态。

```ini
# /etc/systemd/system/backup.service
[Unit]
Description=Nightly Backup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
```

```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Run backup daily

[Timer]
OnCalendar=*-*-* 02:30:00
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
sudo systemctl enable --now backup.timer
systemctl list-timers
```

## 实战任务

1. 写一个 Python/Shell 程序，做成 systemd 服务：非正常退出 3 秒后重启，开机自启。
2. 用 `journalctl -u` 跟踪它的日志，故意 kill 掉进程，观察自动拉起。
3. 给它配一个 timer：每小时跑一次，用 `systemctl list-timers` 确认。
4. 限制该服务的资源（CPU/内存），用 `systemctl set-property` 或在 unit 里写 `CPUQuota=` `MemoryMax=`。

## 命令速查

| 命令 | 作用 |
| --- | --- |
| `systemctl status/start/stop unit` | 管服务 |
| `systemctl enable --now unit` | 开机自启并启动 |
| `systemctl cat unit` | 看 unit 定义 |
| `systemctl daemon-reload` | 改完 unit 必做 |
| `journalctl -u unit -f` | 跟踪服务日志 |
| `systemctl list-timers` | 看所有定时器 |
| `kill -HUP pid` | 重载配置 |

## 常见坑

- **改了 unit 没生效**：忘了 `systemctl daemon-reload`。
- **`Type=simple` 配 `Restart=always` 死循环**：程序本身有 bug 没修，光重启没用，看 journalctl 定位。
- **cron 没日志**：systemd timer 自带日志，新项目优先用 timer。
- **资源不限制**：一个失控进程吃光内存，用 cgroup 限制，第 10 周细讲。

## 参考资料

- `man systemd.service` / `man systemd.timer`
- systemd 实例：https://systemd.io/

---

下一步：[第 7 周 · 网络配置](ubuntu-networking.html)。服务跑起来了，得让网络通起来、稳定下来。