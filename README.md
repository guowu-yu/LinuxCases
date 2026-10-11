# Linux 案例集 · Linux Cases

Ubuntu Server 技能提升按周学习路线图站点。作者：**通信小鱼**。

## 架构

```
content/topics/*.md   # 按周学习专题（Markdown + YAML 头信息）
src/                  # 页面模板、样式、脚本
build.py              # 构建：Markdown → 静态站 + 搜索索引
dist/                 # 构建产物（GitHub Pages 发布）
.github/workflows/    # 推送 main 后自动发布
```

### 信息流

1. 在 `content/topics/` 新增或修改专题 Markdown
2. `push` 到 `main`
3. Actions 构建并发布到 GitHub Pages
4. 首页搜索框读取 `search-index.json` 做本地检索

### 专题 Front Matter

```
---
title: 标题
slug: url-slug
date: YYYY-MM-DD
tags: [标签1, 标签2]
summary: 一句话摘要
cover: https://...  # 可选封面图
---
```

## 本地开发

```
pip install markdown
python build.py
# 用任意静态服务器打开 dist/，例如：
# python -m http.server -d dist 4173
```

## 学习路线图（14 周）

| 周次 | 专题 | 关键词 |
| --- | --- | --- |
| 总览 | Ubuntu Server 学习路线图 | 路线图、学习地图 |
| 第 1 周 | 安装与系统初识 | 安装、SSH、apt、netplan |
| 第 2 周 | 命令行与 Shell 精通 | bash、管道、文本处理 |
| 第 3 周 | 用户、组与权限 | useradd、sudo、ACL |
| 第 4 周 | 文件系统与存储管理 | 磁盘、LVM、挂载 |
| 第 5 周 | 软件包与 APT | apt、deb、源、snap |
| 第 6 周 | 进程与 systemd 服务管理 | systemd、journalctl、定时器 |
| 第 7 周 | 网络配置 | netplan、ip、路由、DNS |
| 第 8 周 | SSH 与远程访问安全 | sshd、密钥、跳板 |
| 第 9 周 | 防火墙与安全加固 | ufw、fail2ban、最小化 |
| 第 10 周 | 性能监控与调优 | top、atop、iostat、压测 |
| 第 11 周 | 日志与故障排查 | journald、syslog、strace |
| 第 12 周 | 容器与虚拟化 | LXD、Docker、KVM |
| 第 13 周 | 自动化运维 | Bash 脚本、Ansible |
| 第 14 周 | 备份与灾难恢复 | rsync、tar、timeshift |

## 站点品牌

- 中文名：**Linux 案例集**
- 副题：Ubuntu Server 技能提升
- 作者：通信小鱼