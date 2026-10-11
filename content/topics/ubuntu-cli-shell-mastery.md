---
title: 第 2 周：命令行与 Shell 精通
slug: ubuntu-cli-shell-mastery
date: 2026-10-12
tags: [bash, 管道, 文本处理, grep, sed, awk, 第2周]
summary: 掌握引号、重定向、管道与文本三剑客 grep/sed/awk，把命令行练成肌肉记忆。
---

<p class="week-badge">WEEK 02 · 入门阶段</p>

## 本周目标

- 理解 Bash 的引号、变量、通配与展开
- 熟练使用重定向与管道组合命令
- 用 grep/sed/awk 完成典型文本处理
- 写出能复用的简短管道，而不是一条条手敲

> 验收标准：给你一份日志，能在 5 分钟内用管道统计出"出错最多的前 5 个服务"。

## Shell 的几种"展开"

这是命令行最容易糊涂的地方——同一个 `*`、`$`、`~`，在不同引号里命运完全不同：

| 写法 | 含义 | 例子 |
| --- | --- | --- |
| `*` / `?` | 通配符展开（路径匹配） | `ls *.log` |
| `~` | 家目录展开 | `cd ~` |
| `$VAR` / `${VAR}` | 变量展开 | `echo $HOME` |
| `$(cmd)` | 命令替换 | `DATE=$(date +%F)` |
| `"..."` | 双引号：保留 `$`、`` ` ``、`\`，空格当字面 | `"today is $(date)"` |
| `'...'` | 单引号：所见即所得，全部字面 | `'$HOME 不是变量'` |

> 黄金法则：含变量/命令替换用双引号；要原样就用单引号。

## 重定向与管道

```bash
# 标准输出到文件（覆盖 / 追加）
cmd > out.log
cmd >> out.log

# 标准错误也收进来
cmd > all.log 2>&1
cmd &> all.log          # bash 简写

# 丢弃输出，常见于定时任务
cmd > /dev/null 2>&1

# 输入重定向
mysql < dump.sql

# 管道：上一步的 stdout 喂给下一步 stdin
dmesg | grep -i error | less
```

## 文本三剑客

### grep —— 找行

```bash
grep -i error /var/log/syslog     # -i 忽略大小写
grep -n "panic" kernel.log         # -n 带行号
grep -v INFO app.log              # -v 反向（不含 INFO 的行）
grep -E "err|warn|fail" app.log    # -E 扩展正则（或用 egrep）
grep -c "error" app.log            # -c 只数匹配行数
grep -r "TODO" .                   # -r 递归当前目录
```

### sed —— 改流（流编辑）

```bash
# 替换每行第一个匹配
sed 's/foo/bar/' file
# 全局替换
sed 's/foo/bar/g' file
# 原地修改（加 -i 备份）
sudo sed -i.bak 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
# 删空行
sed '/^$/d' file
# 打印 10-20 行
sed -n '10,20p' file
```

### awk —— 列处理

```bash
# 打印第 1、3 列
awk '{print $1, $3}' file
# 按分隔符
awk -F: '{print $1}' /etc/passwd
# 带条件：第 3 列大于 1000 的行
awk -F: '$3 > 1000 {print $1, $3}' /etc/passwd
# 求和：统计某列总和
awk '{sum += $5} END {print sum}' data.txt
```

> 心法：**grep 选行、sed 改文本、awk 算列**。三者组合能解 80% 文本处理需求。

## 实战任务

1. **找最占内存的进程**：
   ```bash
   ps aux --sort=-%mem | head -n 6
   ```
2. **统计某日志里各 ERROR 出现次数 Top 5**：
   ```bash
   grep -i error app.log | awk '{print $NF}' | sort | uniq -c | sort -rn | head -5
   ```
3. **批量把 `.txt` 改成 `.log`**：
   ```bash
   for f in *.txt; do mv "$f" "${f%.txt}.log"; done
   ```
4. **把 `/etc/passwd` 里所有用户名导出成一行**：
   ```bash
   cut -d: -f1 /etc/passwd | paste -sd,
   ```
5. **写个函数：快速进入某服务日志目录并 tail**：
   ```bash
   jlog() { sudo journalctl -u "$1" -f; }
   # 用法: jlog nginx
   ```

## 命令速查

| 命令 | 作用 |
| --- | --- |
| `head -n N` / `tail -n N` | 取前/后 N 行 |
| `tail -f file` | 实时跟踪追加 |
| `sort` / `uniq -c` | 排序 / 去重并计数 |
| `wc -l` | 数行数 |
| `cut -d: -f1` | 按分隔符取列 |
| `tr 'a-z' 'A-Z'` | 字符转换 |
| `tee file` | 同时输出屏幕和文件 |
| `xargs` | 把 stdin 转成参数 |

## 提效小习惯

- `Ctrl+R` 反向搜索历史命令，比 `↑` 翻页快得多。
- `!!` 重复上一条，`sudo !!` 补权限神器。
- 别名放进 `~/.bashrc`：`alias ll='ls -lah'`。
- 复杂管道别硬记，存成脚本放 `~/bin/` 并加进 `PATH`。

## 参考资料

- Bash 手册：`man bash`
- sed/awk one-liners：https://www.gnu.org/software/gawk/manual/
- "Linux 命令行与 Shell 脚本编程大全"

---

下一步：[第 3 周 · 用户、组与权限](ubuntu-users-permissions.html)。命令行顺手了，该搞清楚"谁能在机器上干什么"。