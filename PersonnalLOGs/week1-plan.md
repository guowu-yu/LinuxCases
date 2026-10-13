# Ubuntu Server 第一周学习计划

> **主题**: Nginx Web 服务器 + OpenSSH 安全加固
> **目标**: 熟悉 systemd 服务管理、网络配置、防火墙、文件权限——Linux 运维基本功
> **每日时长**: 1.5–2 小时（阅读 + 动手）
> **环境**: Ubuntu Server 22.04 / 24.04，已有 root 或 sudo 用户

---

## 环境准备（Day 0，约 30 分钟）

1. 在主机上登录终端
2. 将本目录的 `install.sh` 传到服务器，或直接复制内容粘贴执行：
   ```bash
   sudo bash install.sh
   ```
3. 查看本机 IP：`ip addr show` → 记下内网 IP（如 192.168.x.x）
4. 从另一台机器测试连通：`ping <服务器IP>`

**验证清单**
- [ ] `curl -I http://localhost` 返回 `HTTP/1.1 200`（Nginx 已跑起来）
- [ ] `systemctl status nginx` 显示 active (running)
- [ ] `ufw status` 显示 inactive（明天再开启）

---

## Day 1 — Nginx 初识与 systemd 服务管理

### 学什么
- systemd 是 Ubuntu 的 init 系统，几乎所有服务都由它管理
- 掌握 5 个核心命令，这是后面所有服务通用的：
  - `systemctl status <服务>` — 看状态
  - `systemctl start / stop / restart <服务>` — 控制
  - `systemctl enable / disable <服务>` — 开机自启
  - `systemctl reload <服务>` — 重载配置（不中断连接）
  - `journalctl -u <服务> -f` — 实时看日志

### 动手任务
```bash
# 1. 停止 Nginx，观察现象
sudo systemctl stop nginx
curl -I http://localhost        # 应该连接失败

# 2. 启动并查看状态
sudo systemctl start nginx
systemctl status nginx

# 3. 查看日志，理解日志在哪
sudo journalctl -u nginx -n 50 --no-pager
sudo journalctl -u nginx -f     # Ctrl+C 退出

# 4. 理解 Nginx 的文件布局
ls -la /etc/nginx/
cat /etc/nginx/nginx.conf       # 主配置
ls /etc/nginx/sites-enabled/    # 站点配置
ls /var/www/html/               # 默认网页根目录
```

### 产出
- [ ] 在笔记中记录：systemctl 的 5 个命令用法
- [ ] 画出 Nginx 配置文件的层级关系（nginx.conf → sites-enabled → ...）

---

## Day 2 — 自定义网页 + 虚拟主机

### 学什么
- Nginx 配置文件结构
- server 块、location 块
- 静态文件托管

### 动手任务
**任务 A：替换默认页面**
```bash
sudo nano /var/www/html/index.html
# 改成你自己的内容，保存后刷新浏览器
```

**任务 B：配置第二个站点**（基于端口的虚拟主机）
```bash
# 1. 建站点目录
sudo mkdir -p /var/www/site2
echo "<h1>Hello from Site 2</h1>" | sudo tee /var/www/site2/index.html

# 2. 写配置
sudo nano /etc/nginx/sites-available/site2
# 内容如下：
# server {
#     listen 8080;
#     server_name _;
#     root /var/www/site2;
#     index index.html;
# }

# 3. 启用站点（软链接到 sites-enabled）
sudo ln -s /etc/nginx/sites-available/site2 /etc/nginx/sites-enabled/

# 4. 测试配置语法 + 重载
sudo nginx -t
sudo systemctl reload nginx

# 5. 访问测试
curl http://localhost:8080
```

### 产出
- [ ] 浏览器访问 `http://<IP>` 和 `http://<IP>:8080` 看到不同内容
- [ ] 在笔记中解释 sites-available 和 sites-enabled 的关系

---

## Day 3 — 日志、错误处理、配置调试

### 学什么
- Nginx 日志体系（access.log / error.log）
- 常见错误排查思路
- `nginx -t` 的重要性

### 动手任务
```bash
# 1. 观察 access log
sudo tail -f /var/log/nginx/access.log
# 同时在浏览器刷几下，观察日志格式

# 2. 故意制造一个错误（改坏配置）
sudo nano /etc/nginx/sites-available/default
# 把 listen 80; 改成 listen 80;（少个分号）或乱写一行
sudo nginx -t          # 会报错，看懂错误信息
sudo systemctl reload nginx  # 配置错误时 reload 会失败但服务不挂

# 3. 修复后重载
# 4. 理解 access.log 字段含义：IP - - [时间] "请求" 状态码 字节数 ...
```

### 思考题
1. `reload` 和 `restart` 有什么区别？什么时候用哪个？
2. 为什么改配置前一定要 `nginx -t`？
3. access.log 越来越大怎么办？（预习 logrotate）

### 产出
- [ ] 在笔记中记录 access.log 每个字段的含义
- [ ] 写下你故意制造错误时 nginx -t 的报错原文

---

## Day 4 — OpenSSH 加固（上）

### 学什么
- SSH 密钥认证原理
- sshd_config 关键参数
- 为什么禁用密码登录

### 动手任务
**任务 A：生成密钥对（在你本地电脑上做，不是服务器）**
```bash
# 在你本地的 Linux/Mac/Git Bash 里：
ssh-keygen -t ed25519 -C "my-ubuntu-server"
# 一路回车（或设一个密钥密码增加安全性）
# 生成两个文件:
#   ~/.ssh/id_ed25519       私钥（绝对不能泄露）
#   ~/.ssh/id_ed25519.pub   公钥（要放到服务器上）
```

**任务 B：把公钥放到服务器**
```bash
# 方法1（推荐，如果本地有 ssh-copy-id）：
ssh-copy-id <用户名>@<服务器IP>

# 方法2（手动）：
# 先用密码登录服务器，然后：
mkdir -p ~/.ssh
chmod 700 ~/.ssh
# 把公钥内容追加进去：
echo "你的公钥内容" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

**任务 C：验证密钥登录**
```bash
# 退出后重新登录，应该不用输密码了
ssh <用户名>@<服务器IP>
```

> ⚠️ **重要**：先确认密钥能登录，再禁用密码登录！否则可能把自己锁在外面。

### 产出
- [ ] 密钥登录成功（不用输密码）
- [ ] 在笔记中画图说明：公钥加密 → 私钥解密 的认证过程

---

## Day 5 — OpenSSH 加固（下）+ 防火墙

### 学什么
- sshd_config 安全加固
- ufw 防火墙配置
- fail2ban 防暴力破解

### 动手任务
**任务 A：加固 SSH 配置**
```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak  # 先备份！

sudo nano /etc/ssh/sshd_config
# 修改以下参数：
#   Port 22                 # 可改成 2222 增加安全性（可选）
#   PermitRootLogin no      # 禁止 root 直接登录
#   PasswordAuthentication no  # 禁用密码登录（前提：密钥已能用）
#   PubkeyAuthentication yes
#   AllowUsers <你的用户名>  # 只允许特定用户登录

# 测试配置语法（不会重启服务）
sudo sshd -t

# 重载（注意：用 reload 不是 restart，更安全）
sudo systemctl reload ssh
```

> ⚠️ **保险措施**：改完先别关当前 SSH 会话，另开一个终端测试登录。能登进去再关旧会话。

**任务 B：配置 ufw 防火墙**
```bash
# 先放行 SSH（否则一开防火墙就把自己锁外面了！）
sudo ufw allow 22/tcp         # 或你改的端口
sudo ufw allow 80/tcp         # 放行 HTTP
sudo ufw allow 8080/tcp       # 放行第二个站点

# 启用防火墙
sudo ufw enable
sudo ufw status verbose

# 测试：从外部还能 SSH 和访问网页吗？
```

**任务 C：配置 fail2ban**
```bash
sudo nano /etc/fail2ban/jail.local
# 写入：
# [sshd]
# enabled = true
# port = 22
# maxretry = 3
# bantime = 3600

sudo systemctl restart fail2ban
sudo fail2ban-client status sshd   # 查看 SSH 防护状态
```

### 产出
- [ ] `ufw status` 显示 22、80、8080 端口放行
- [ ] `fail2ban-client status sshd` 显示 jail 正在运行
- [ ] 从另一台机器用密码登录被拒绝（密钥仍可登录）

---

## Day 6 — 综合实战：Nginx + HTTPS + 防火墙联调

### 学什么
- 用 openssl 生成自签证书
- Nginx 配置 HTTPS
- 把前面所有知识串起来

### 动手任务
**任务 A：生成自签证书**
```bash
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/nginx.key \
  -out /etc/nginx/ssl/nginx.crt \
  -subj "/C=CN/ST=Beijing/L=Beijing/O=MyLab/CN=myserver.local"
```

**任务 B：配置 HTTPS 站点**
```bash
sudo nano /etc/nginx/sites-available/default
# 修改为：
# server {
#     listen 80;
#     listen 443 ssl;
#     server_name _;
#
#     ssl_certificate /etc/nginx/ssl/nginx.crt;
#     ssl_certificate_key /etc/nginx/ssl/nginx.key;
#
#     root /var/www/html;
#     index index.html;
# }

sudo nginx -t
sudo systemctl reload nginx
sudo ufw allow 443/tcp   # 防火墙放行 HTTPS
```

**任务 C：验证全链路**
```bash
# HTTP 自动跳 HTTPS（这个你自己写规则）...
curl -k https://localhost          # -k 忽略自签证书警告
```

### 产出
- [ ] 浏览器 `https://<IP>` 能访问（有证书警告是正常的）
- [ ] 笔记里写清：证书、私钥、nginx 配置三者关系

---

## Day 7 — 复盘 + 笔记整理

### 任务
1. **写一篇博客式笔记**，覆盖以下问题：
   - systemd 管理服务的 5 个核心命令
   - Nginx 配置文件层级和加载顺序
   - SSH 密钥认证的工作原理
   - ufw 防火墙的工作机制和默认策略
   - fail2ban 如何保护 SSH

2. **画一张架构图**：从浏览器发出请求 → 防火墙 → Nginx → 静态文件 → 返回响应，标注每一经过的组件和配置

3. **清点和归档**：
   ```bash
   # 备份你的所有配置
   tar czf week1-configs-backup.tar.gz \
     /etc/nginx/ /etc/ssh/sshd_config \
     /etc/fail2ban/jail.local /etc/ufw/user.rules
   ```

4. **预告第二周**：PostgreSQL 数据库 + Samba 文件共享

---

## 本周技能检查表

完成本周后，你应该能不查资料回答以下问题：

- [ ] 如何让一个服务开机自启？
- [ ] `systemctl reload` 和 `restart` 的区别？
- [ ] Nginx 配置改完要做什么才能生效？
- [ ] SSH 密钥认证比密码认证安全在哪？
- [ ] 为什么要先放行 SSH 端口再开 ufw？
- [ ] fail2ban 是怎么发现暴力破解的？
- [ ] 自签证书和 Let's Encrypt 证书的区别？
- [ ] `nginx -t` 报错时服务会挂吗？为什么？

能答出 6 个以上，本周过关 ✅

---

## 依赖包一览（对应 requirements.txt）

| 包名 | 所属 | 用途 |
|------|------|------|
| nginx | Web 服务 | 本周主角 |
| openssl | Web 服务 | 生成自签证书 |
| openssh-server | SSH | 远程登录服务端 |
| openssh-client | SSH | 本地 SSH 客户端 |
| ufw | 安全 | 防火墙 |
| fail2ban | 安全 | 防暴力破解 |
| auditd | 安全 | 操作审计（选学）|
| logrotate | 运维 | 日志轮转 |
| curl, wget | 基础 | 下载/测试 |
| vim, nano | 基础 | 文本编辑 |
| htop, tmux | 基础 | 进程监控/终端复用 |
| net-tools | 网络 | ifconfig/netstat |
| dnsutils | 网络 | dig/nslookup |
| nmap | 网络 | 端口扫描 |
| tcpdump | 网络 | 抓包分析 |
| telnet | 网络 | 端口连通性测试 |
| tree, git | 基础 | 目录树/版本控制 |