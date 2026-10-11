---
title: 第 5 周：软件包与 APT
slug: ubuntu-apt-packaging
date: 2026-10-12
tags: [apt, deb, 软件源, snap, 第5周]
summary: 玩转 apt 与 deb 包，配好软件源、配 PPA、分清 snap 与 apt 的取舍。
---

<p class="week-badge">WEEK 05 · 系统阶段</p>

## 本周目标

- 理解 deb 包、apt、dpkg 三者关系
- 熟练 apt 的安装/查询/卸载，包含依赖清理
- 配置软件源与 PPA，会换国内源
- 分清 snap/flatpak/apt 的定位，不混用

> 验收标准：能给机器配上国内源，安装指定版本，并清理掉装完没用的依赖。

## deb / dpkg / apt 是什么

| 层 | 工具 | 管什么 |
| --- | --- | --- |
| 包文件 | `.deb` | 一个软件的打包单元 |
| 底层 | `dpkg` | 装/卸单个 deb，不管依赖 |
| 高层 | `apt` | 解决依赖、从源拉包、升级 |

> 记忆：`dpkg` 装"一个文件"，`apt` 装"一个软件"。

## apt 日常操作

```bash
# 刷新源索引（装任何东西前先 update）
sudo apt update

# 安装，自动带依赖
sudo apt install -y nginx

# 装指定版本
apt-cache madison nginx          # 看可用版本
sudo apt install -y nginx=1.24.0-*

# 升级所有包
sudo apt upgrade -y
# 升级并允许增删包（内核/大版本升级用）
sudo apt full-upgrade -y

# 卸载
sudo apt remove nginx            # 留配置
sudo apt purge nginx             # 连配置一起删
sudo apt autoremove --purge -y   # 清掉孤立的依赖

# 查询
apt search redis
apt show nginx
dpkg -l | grep nginx             # 看已装版本
dpkg -L nginx                    # 看装了哪些文件
which nginx                      # 可执行文件位置
```

## 软件源与 PPA

源配置在 `/etc/apt/sources.list` 和 `/etc/apt/sources.list.d/`。Ubuntu 24.04 起用 **DEB822 格式** 的 `.sources` 文件。

```bash
# 看当前源
grep -r ^ /etc/apt/sources.list /etc/apt/sources.list.d/

# 换阿里云源（noble 为 24.04 代号）
sudo sed -i 's|http://archive.ubuntu.com|https://mirrors.aliyun.com|g' /etc/apt/sources.list
sudo sed -i 's|http://security.ubuntu.com|https://mirrors.aliyun.com|g' /etc/apt/sources.list
sudo apt update
```

加 PPA（个人软件包仓库，慎用于生产）：

```bash
sudo add-apt-repository ppa:ondrej/php
sudo apt update
```

## apt vs snap vs flatpak

| 体系 | 特点 | 何时用 |
| --- | --- | --- |
| **apt** | 系统级、依赖共享、版本随发行版 | 服务端主力 |
| **snap** | 自包含、跨版本、沙箱、自动更新 | 单一应用、要新版本 |
| **flatpak** | 自包含、桌面应用为主 | 桌面场景 |

```bash
# snap 操作
sudo snap install code --classic
sudo snap list
sudo snap refresh            # 更新所有
sudo snap remove code
```

> 生产服务器常**禁用 snap**（避免后台自动更新引入不确定），改用 apt 装稳定版。

## 实战任务

1. 把默认源换成国内镜像，`apt update` 验证速度。
2. 安装 `htop` 与 `tree`，用 `dpkg -L` 看它们装了哪些文件。
3. 用 `apt show` 查 nginx 包信息，再装指定版本后 `apt-mark hold` 锁版本防升级。
4. 装 `docker.io`，卸载时连同无用依赖一起清掉（`autoremove --purge`）。

## 命令速查

| 命令 | 作用 |
| --- | --- |
| `apt update` | 刷新源索引 |
| `apt install pkg` | 安装 |
| `apt remove pkg` | 卸载 |
| `apt purge pkg` | 卸载+删配置 |
| `apt autoremove` | 清孤立依赖 |
| `apt-cache madison pkg` | 查可用版本 |
| `apt-mark hold pkg` | 锁版本防升级 |
| `dpkg -L pkg` | 看装了哪些文件 |

## 常见坑

- **不 update 就 install**：装到旧索引导致依赖错乱，养成先 update 习惯。
- **PPA 装生产**：PPA 不保证稳定，生产只信官方源。
- **snap 自动更新打断服务**：关键服务用 apt，或 `snap refresh --hold` 暂停。
- **purge 把别人的配置也删了**：purge 删的是该包自己的配置，看清包名再删。

## 参考资料

- `man apt` / `man sources.list`
- Ubuntu 软件源文档：https://wiki.ubuntu.com/Repositories

---

下一步：[第 6 周 · 进程与 systemd 服务管理](ubuntu-systemd-services.html)。装好软件了，该让服务跑起来、管起来。