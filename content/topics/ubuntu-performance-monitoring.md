---
title: 第 10 周：性能监控与调优
slug: ubuntu-performance-monitoring
date: 2026-10-12
tags: [top, iostat, 性能, cgroup, 第10周]
summary: 用 top/iostat/vmstat 定位 CPU、内存、IO 瓶颈，用 cgroup 给服务上资源限制。
---

<p class="week-badge">WEEK 10 · 稳健阶段</p>

## 本周目标

- 用工具快速判断瓶颈在 CPU、内存还是 IO
- 读懂 top/vmstat/iostat 的关键列
- 用 cgroup（systemd 资源控制）限制服务资源
- 知道压测的基本姿势

> 验收标准：一台机器卡顿，你能在 5 分钟内说出"卡在哪、谁干的、怎么办"。

## 性能三角：CPU / 内存 / IO

先判断大方向，再钻细节：

| 怀疑 | 第一工具 | 关键信号 |
| --- | --- | --- |
| CPU 不足 | `top` / `uptime` | load 高、us 高、%CPU 接近 100% |
| 内存不足 | `free -h` / `vmstat` | available 低、swap 在涨、si/so 大 |
| 磁盘慢 | `iostat -xz` / `iotop` | %util 高、await 大、svctm 大 |
| 网络问题 | `iftop` / `nload` | 带宽打满、丢包 |

## CPU 与内存

```bash
uptime               # load 平均值（1/5/15 分钟），> 核数 *= 瓶颈
top                  # 实时，看 us/sy/wa
htop                 # 更友好（apt install htop)
free -h              # 总/用/空闲/可用/缓存/swap
vmstat 1 5           # 每秒一次共 5 次
```

vmstat 关键列：

```
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 1  0      0 200000  50000 800000    0    0     0     2  120  200 10  5 85  0  0
```

- `r` > 核数 → CPU 排队
- `b` > 0 → 在等 IO
- `si/so` 大 → 在 swap 抖，内存吃紧
- `wa` 高 → 在等 IO

## 磁盘 IO

```bash
iostat -xz 1                       # 每 1 秒，扩展模式
sudo apt install sysstat -y        # 提供 iostat
sudo iotop                         # 看哪个进程在读写
```

iostat 关键列：

| 列 | 含义 | 红线 |
| --- | --- | --- |
| `%util` | 设备忙时占比 | 持续 > 80% 接近满载 |
| `await` | 请求平均等待(ms) | HDD > 20、SSD > 5 异常 |
| `r/s w/s` | 每秒读写数 | 配合 %util 看 |

## 用 cgroup 限资源

systemd 自带 cgroup 集成，直接给服务设限：

```bash
# 限制 app.service 最多用 1 核、512M
sudo systemctl set-property app.service \
    CPUQuota=100% MemoryMax=512M

# 写进 unit 文件持久化
[Service]
CPUQuota=100%
MemoryMax=512M
MemoryHigh=400M        # 软上限，超了会限速回收
```

## 压测速览

```bash
# CPU 压测
yes > /dev/null &            # 简单占满一核
# 真正压测用 stress-ng
sudo apt install stress-ng
stress-ng --cpu 4 --timeout 60s

# 磁盘压测
fio --name=test --rw=randread --bs=4k --size=1G --runtime=30s --time_based

# 网络吞吐
iperf3 -s            # 服务端
iperf3 -c server_ip  # 客户端
```

## 实战任务

1. 用 `stress-ng` 制造 CPU 100%，用 top/vmstat 观察，判断瓶颈类型。
2. 写文件到磁盘同时 `iostat -xz 1` 观察 await/%util。
3. 给一个服务设 `CPUQuota=20% MemoryMax=256M`，压测验证被限住。
4. 模拟内存耗尽（开大进程吃内存），观察 swap 与 OOM killer 日志。

## 命令速查

| 命令 | 作用 |
| --- | --- |
| `uptime` | load 平均 |
| `top` / `htop` | 实时进程 |
| `free -h` | 内存 |
| `vmstat 1` | 综合趋势 |
| `iostat -xz 1` | 磁盘 IO |
| `iotop` | 谁在读写 |
| `systemctl set-property` | 限制服务资源 |

## 常见坑

- **load 高就怪 CPU**：load 也含等 IO 的进程，先看 `wa`。
- **free 少就扩内存**：Linux 喜欢把空闲内存当缓存用，看 `available` 才准。
- **swap 一点就慌**：偶尔换入换出正常，持续 `si/so` 大才是病。
- **限制设太死**：服务一忙就被 OOM kill，留 headroom。

## 参考资料

- Brendan Gregg 性能分析：http://www.brendangregg.com/linuxperf.html
- `man iostat` / `man vmstat`

---

下一步：[第 11 周 · 日志与故障排查](ubuntu-logs-troubleshooting.html)。性能看得见了，出了事还得能查。