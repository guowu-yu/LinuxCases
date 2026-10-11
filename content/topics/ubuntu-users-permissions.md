---
title: 第 3 周：用户、组与权限
slug: ubuntu-users-permissions
date: 2026-10-12
tags: [useradd, sudo, 文件权限, ACL, 第3周]
summary: 搞清 rwx 权限位、用户组体系与 sudo 提权，用 ACL 处理基础权限够不着的精细授权。
---

<p class="week-badge">WEEK 03 · 入门阶段</p>

## 本周目标

- 看懂 `ls -l` 的权限位，会用 `chmod`/`chown`
- 熟练增删用户与组，理解 `sudo` 的提权机制
- 用 ACL 做精细授权，突破"属主/属组/其他"三段限制
- 知道何时用 `sudo`、何时直接 root，避免权限设计混乱

> 验收标准：新来一个同事，给他建账号、加进对应组、只让他能读某项目目录、能 sudo 重启指定服务。

## 权限位的真相

```
$ ls -l deploy.sh
-rwxr-xr-- 1 dev dev 412 Oct 12 10:00 deploy.sh
 ├┬─┬─┬─
 │ │ │ └─ 其他: r-- (4)
 │ │ └──── 属组: r-x (5)
 │ └────── 属主: rwx (7)
 └──────── 类型: - 普通文件 / d 目录 / l 链接
```

| 数字 | 权限 | 字母 |
| --- | --- | --- |
| 4 | 读 | r |
| 2 | 写 | w |
| 1 | 执行 | x |

目录的 `x` 是"可进入"，没它 `cd` 都进不去。

## chmod 与 chown

```bash
# 数字法
chmod 755 deploy.sh        # rwxr-xr-x
chmod 644 config.yml       # rw-r--r--

# 符号法（更直观）
chmod u+x script.sh        # 属主加执行
chmod g-w data/            # 属组去写
chmod o-r secret.key       # 其他去读
chmod a+r notice.txt       # 全部加读

# 改属主属组
sudo chown dev:dev deploy.sh
sudo chown -R dev:dev /srv/app     # 递归
```

## 用户与组

```bash
# 创建用户（建议用 adduser，交互式更安全）
sudo adduser alice
# 非交互（脚本里）
sudo useradd -m -s /bin/bash -c "Alice" alice && sudo passwd alice

# 删除用户但保留家目录文件
sudo deluser alice
# 连家目录一起删
sudo deluser --remove-home alice

# 组操作
sudo groupadd deploy
sudo usermod -aG deploy alice       # -aG 追加进组，别漏 -a
# 查看用户所属组
groups alice
id alice
```

> 加入组后**要重新登录**（或 `newgrp deploy`）才生效。

## sudo 提权机制

Ubuntu 默认禁用 root 登录，靠 `sudo` 提权。`sudo` 的规则在 `/etc/sudoers` 与 `/etc/sudoers.d/`，**永远用 `visudo` 编辑**——写错语法会让 sudo 罢工。

```bash
# 让 alice 免密 sudo
sudo visudo -f /etc/sudoers.d/alice
```

```
alice ALL=(ALL) NOPASSWD: ALL
```

更安全的做法是**只放行特定命令**：

```
alice ALL=(root) NOPASSWD: /bin/systemctl restart nginx
alice ALL=(root) NOPASSWD: /usr/bin/apt update
```

`sudo` 提示密码后，**默认 15 分钟内不重问**（`timestamp_timeout`）。

## ACL：精细授权

基础权限只有三段（属主/属组/其他）。当需要"让 bob 也能读，但他不在 dev 组"时，用 ACL：

```bash
# 开启 ACL（现代文件系统默认支持）
sudo setfacl -m u:bob:r /srv/app/config.yml
# 给组
sudo setfacl -m g:qa:rw /srv/app/logs/
# 递归设置默认 ACL（新建文件自动继承）
sudo setfacl -d -m g:qa:rw /srv/app/logs/
# 查看 ACL
getfacl /srv/app/logs/
# 删除某条
sudo setfacl -x u:bob /srv/app/config.yml
```

## 实战任务

1. 用 `adduser` 建一个用户 `tom`，加进 `deploy` 组，确认 `groups tom` 能看到。
2. 建目录 `/srv/shared`，属主属组 `dev:dev`，模式 `770`；用 ACL 让 `qa` 组只读。
3. 配置 `tom` 只能免密执行 `sudo systemctl restart nginx`，验证其他 sudo 命令仍问密码。
4. 解释这条命令的最终权限：`chmod 750 dir && setfacl -m u:bob:rx dir`。

## 命令速查

| 命令 | 作用 |
| --- | --- |
| `chmod 755 file` | 设置权限 |
| `chown user:group file` | 改属主属组 |
| `useradd -m -s /bin/bash u` | 建用户 |
| `usermod -aG grp user` | 追加进组 |
| `groups user` / `id user` | 看所属组 |
| `visudo` | 安全编辑 sudoers |
| `getfacl / setfacl` | 查看/设置 ACL |

## 常见坑

- `usermod -G grp user`（漏 `-a`）会把 user 从其他组踢出去，务必用 `-aG`。
- 直接改 `/etc/sudoers` 写错语法 → 全员 sudo 失效，只能进单用户模式救。
- 目录没 `x` 位，`r` 也用不上——能列出名字但 `cd` 不进去。
- ACL 与基础权限混用时，有效权限是"基础位 **或** ACL"的并集，理解清楚别被绕晕。

## 参考资料

- `man chmod` / `man acl` / `man sudoers`
- Ubuntu sudo 文档：https://ubuntu.com/server/docs/sudoers

---

下一步：[第 4 周 · 文件系统与存储管理](ubuntu-filesystem-storage.html)。权限管完了，该管"数据存在哪、怎么扩"。