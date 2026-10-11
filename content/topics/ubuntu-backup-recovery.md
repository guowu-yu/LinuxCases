---
title: 第 14 周：备份与灾难恢复
slug: ubuntu-backup-recovery
date: 2026-10-12
tags: [rsync, tar, timeshift, 备份, 第14周]
summary: 用 rsync/tar 做数据备份，用 timeshift 保系统状态，建好"3-2-1"备份与恢复演练。
---

<p class="week-badge">WEEK 14 · 进阶阶段</p>

## 本周目标

- 用 rsync 做增量目录备份
- 用 tar 做打包归档
- 用 timeshift 给系统上"快照保险"
- 理解 3-2-1 备份原则与恢复演练

> 验收标准：模拟误删一个数据库目录，能从备份完整恢复，并记录恢复用时。

## 备份策略：3-2-1

- **3** 份数据（1 份原件 + 2 份备份）
- **2** 种介质（如 本地盘 + 外置/NAS）
- **1** 份异地（云、异地机房）

> 没做过恢复演练的备份，等于没备份。定期练。

## rsync：增量同步

```bash
# 增量同步 /srv/data → /backup/data，保留权限属主软链
rsync -aHAX --delete /srv/data/ /backup/data/
# -a 归档  -H 硬链  -A ACL  -X xattr  --delete 删源端已删的
# 注意：源路径末尾的 / 决定是否带目录本身

# 远程备份（走 SSH）
rsync -aHAX --delete -e "ssh -p 2222" /srv/data/ deploy@backup:/backup/data/

# 用 --link-dest 做快照式增量（省空间）
rsync -aHAX --delete --link-dest=/backup/cur /srv/data/ /backup/$(date +%F)
```

## tar：打包归档

```bash
# 全量打包 + gzip
tar -czf /backup/app-$(date +%F).tar.gz -C /srv app

# 增量（基于上次全量的快照文件）
tar -czf /backup/app-inc-$(date +%F).tar.gz -g /backup/snap.db -C /srv app

# 查看内容（不解包）
tar -tzf /backup/app-2026-10-12.tar.gz

# 解包
tar -xzf /backup/app-2026-10-12.tar.gz -C /restore
```

## timeshift：系统级快照

类似 macOS Time Machine，给系统做快照，挂掉一键回滚。

```bash
sudo apt install -y timeshift
sudo timeshift --create --comments "before upgrade" --tags D
sudo timeshift --list
sudo timeshift --restore           # 交互选快照恢复
```

## 实战任务

1. 用 rsync 把 `/srv/data` 增量同步到 `/backup/data`，改几个文件再跑，确认只传增量。
2. 写一个 cron/timer 定时全量 tar 备份，保留最近 7 份。
3. 装 timeshift 做一次系统快照，删个系统文件后用 `--restore` 回滚。
4. 演练：误删数据库目录，从备份计时恢复，写恢复步骤与用时。

## 命令速查

| 命令 | 作用 |
| --- | --- |
| `rsync -aHAX --delete src/ dst/` | 增量同步 |
| `tar -czf out.tgz dir` | 打包 gzip |
| `tar -xzf out.tgz -C dir` | 解包 |
| `timeshift --create/--list/--restore` | 系统快照 |

## 常见坑

- **只备份没演练**：真出事发现备份坏了，两手空空。
- **rsync 源末尾 `/` 写错**：`src/` 与 `src` 结果差一层目录，最常踩。
- **备份与原数据同一台盘**：盘坏全完，违背 3-2-1。
- **没保留历史**：`--delete` 会让备份与源同步，误删会被同步删除——快照式 `--link-dest` 才保历史。

## 路线图收尾

14 周走完，你已具备：装机→命令行→权限→存储→装包→服务→网络→SSH→安全→性能→排查→容器→自动化→备份的完整 Ubuntu Server 能力链。

接下来三件事：
1. **复盘**：把每周笔记整理成自己的速查手册。
2. **做项目**：用这套技能部署一个真实服务（如自托管 Git、监控、博客）。
3. **回看路线图**：[总览](ubuntu-server-roadmap.html)，把薄弱周再练一遍。

> 命令会被忘，但"装得对、管得住、查得清、扶得起"的系统化手感，练过就长在身上。