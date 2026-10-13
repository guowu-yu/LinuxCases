#!/usr/bin/env bash
# ====================================================================
# Ubuntu Server 第一周环境一键安装脚本
# 主题: Nginx + OpenSSH 安全加固
# 适用: Ubuntu 22.04 / 24.04 Server
# 用法: sudo bash install.sh
# ====================================================================
set -euo pipefail

# ---- 颜色输出 ----
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
log()  { echo -e "${GREEN}[INSTALL]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# ---- 权限检查 ----
if [[ $EUID -ne 0 ]]; then
  echo "请用 sudo 运行: sudo bash install.sh"
  exit 1
fi

log "更新软件源..."
apt update -y

# ---- 1. 基础工具 ----
log "安装基础工具 (curl, vim, htop, tmux, git...)"
apt install -y \
  curl wget vim nano \
  htop tmux tree \
  bash-completion unzip git

# ---- 2. 网络诊断工具 ----
log "安装网络诊断工具 (net-tools, dnsutils, nmap, tcpdump)"
apt install -y \
  net-tools dnsutils \
  telnet nmap tcpdump

# ---- 3. 防火墙与安全 ----
log "安装防火墙与安全工具 (ufw, fail2ban)"
apt install -y ufw fail2ban

# ---- 4. OpenSSH ----
log "确认 OpenSSH 已安装"
apt install -y openssh-server openssh-client

# ---- 5. Nginx ----
log "安装 Nginx"
apt install -y nginx openssl

# ---- 6. 系统审计（选学）----
log "安装审计工具 (auditd, logrotate)"
apt install -y auditd logrotate

# ---- 清理 ----
log "清理 apt 缓存"
apt clean
apt autoremove -y

# ---- 验证安装 ----
echo ""
echo "========================================"
echo "  安装完成，版本信息如下："
echo "========================================"
echo "nginx     : $(nginx -v 2>&1)"
echo "sshd      : $(sshd -V 2>&1 | head -1 || ssh -V 2>&1)"
echo "ufw       : $(ufw version 2>&1 | head -1)"
echo "fail2ban  : $(fail2ban-client --version 2>&1 | head -1)"
echo "docker    : 暂未安装（第3周再装）"
echo "========================================"
echo ""
echo "下一步:"
echo "  1. 启动 Nginx:  sudo systemctl status nginx"
echo "  2. 浏览器访问本机 IP，应看到 Nginx 欢迎页"
echo "  3. 按 week1-plan.md 开始 Day 1 学习"
echo ""