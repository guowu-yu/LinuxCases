---
title: 第 13 周：自动化运维
slug: ubuntu-automation-ansible
date: 2026-10-12
tags: [Bash, Ansible, 自动化, idempotent, 第13周]
summary: 用 Bash 脚本固话重复操作，用 Ansible 实现幂等、可复现的多机配置管理。
---

<p class="week-badge">WEEK 13 · 进阶阶段</p>

## 本周目标

- 写出健壮的 Bash 脚本（set -euo pipefail、错误处理）
- 理解 Ansible 的 Inventory / Module / Playbook 三件套
- 写一个幂等的 Ansible playbook 部署 nginx
- 分清脚本与配置管理的边界

> 验收标准：给定一批新机器，一条命令把 nginx 部署到所有机器，重复跑结果一致。

## Bash 脚本健壮性

```bash
#!/usr/bin/env bash
set -euo pipefail    # -e 出错即退 -u 未定义变量报错 -o pipefail 管道传递错误

log() { echo "[$(date +%H:%M:%S)] $*" >&2; }
die() { log "ERROR: $*"; exit 1; }

workdir="${1:-}"
[[ -n "$workdir" ]] || die "用法: $0 <dir>"
mkdir -p "$workdir" || die "无法创建 $workdir"

trap 'log "脚本在 line $LINENO 失败"' ERR
```

> 单机一次性、逻辑固定的用脚本；多机、要幂等可复现的用 Ansible。

## Ansible 基础

Ansible 是无 agent 的配置管理：控制端通过 SSH 推 YAML playbook，被控端用 Python 执行模块。幂等是核心：跑多少遍，最终状态一致。

```bash
sudo apt install -y ansible
```

## Inventory

```ini
# inventory.ini
[servers]
web1 ansible_host=10.0.0.11
web2 ansible_host=10.0.0.12

[db]
db1 ansible_host=10.0.0.50

[all:vars]
ansible_user=deploy
ansible_port=2222
```

```bash
# 不改 target，先测通
ansible all -i inventory.ini -m ping
ansible all -i inventory.ini -a "uptime"
```

## Playbook

```yaml
# deploy_nginx.yml
- name: Deploy nginx
  hosts: servers
  become: true
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
        update_cache: true

    - name: Ensure nginx is running and enabled
      service:
        name: nginx
        state: started
        enabled: true

    - name: Copy index page
      copy:
        dest: /var/www/html/index.html
        content: "<h1>managed by ansible</h1>"
        owner: www-data
        group: www-data

    - name: Open 80
      ufw:
        rule: allow
        port: "80"
        proto: tcp
```

```bash
ansible-playbook -i inventory.ini deploy_nginx.yml
# 跑第二遍，changed 应全是 0（幂等）
```

## 脚本 vs Ansible

| 维度 | Bash 脚本 | Ansible |
| --- | --- | --- |
| 目标 | 单机、过程式 | 多机、声明状态 |
| 幂等 | 要自己写 | 模块自带 |
| 幂等性 | 难保证 | 内建 |
| 回滚 | 基本没有 | 可改 state: absent |
| 适合 | 备份、临时操作 | 标准化装机、配置 |

## 实战任务

1. 写 Bash 脚本：备份指定目录到带日期的 tar，失败即退并打印错误。
2. 用 Ansible 写 inventory，`ping` 通一批机器。
3. 写 playbook 装 nginx 并开机自启，跑两遍验证幂等。
4. 给上一步加：用 `template` 生成 nginx 配置，改变量后重跑只更新变更项。

## 命令速查

| 命令 | 作用 |
| --- | --- |
| `bash -x script.sh` | 调试，打印每条命令 |
| `ansible all -m ping` | 测连通 |
| `ansible-doc -l` | 列全部模块 |
| `ansible-playbook -i inv pb.yml` | 跑 playbook |
| `--check` / `--diff` | 预演/看差异 |
| `--limit web1` | 只跑部分主机 |

## 常见坑

- **脚本没 `set -e`**：中途失败还继续跑，后果难料。
- **Ansible 不幂等**：用 shell 模块裸写命令会破坏幂等，优先用专门模块。
- **第一台机器就改坏**：写 playbook 先用 `--check --diff` 预演，再小批量上。

## 参考资料

- Ansible 文档：https://docs.ansible.com/

---

下一步：[第 14 周 · 备份与灾难恢复](ubuntu-backup-recovery.html)。自动化搞定了，最后给一切上保险。