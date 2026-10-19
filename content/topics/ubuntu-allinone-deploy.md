---
slug: ubuntu-allinone-deploy
title: Ubuntu Server 一键部署：Docker + Jenkins + 禅道 完整实战教程
date: 2026-10-20
tags: [Ubuntu, Docker, Jenkins, 禅道, ZenTao, 一键部署, CI/CD, 测试管理]
summary: 一条脚本在最新 Ubuntu Server 上自动装好 Docker，再用一份 docker-compose 同时拉起 Jenkins 与禅道，并把 pytest→Jenkins→zentaoatf→禅道 的测试管理闭环打通，适合照抄落地。
---

> 本篇是你前面三个专题的**总集成**：`ubuntu-cicd-docker-jenkins`（Docker+Jenkins）、`ubuntu-zentao-setup`（禅道）、`ubuntu-pytest-roadmap`（pytest）。
> 目标——**在一台干净的最新版 Ubuntu Server 上，一条命令装好 Docker，一份 compose 同时跑起 Jenkins 与禅道，并把三者串成自动化测试管理闭环**。
> 全程可照抄，预计 20–30 分钟（含镜像拉取）。

## 一、整体架构与端口规划

```
            ┌─────────────────────────────────────────────┐
  浏览器 ──▶ │  你的 Ubuntu Server                          │
            │                                             │
            │  :8080  Jenkins  (jenkins/jenkins:lts-jdk17) │
            │  :9090  禅道 ZenTao (easysoft/zentao:22.5)    │
            │  :3306  MariaDB (仅供禅道, 不对外)            │
            └─────────────────────────────────────────────┘
                     │ Jenkins 挂载 /var/run/docker.sock
                     ▼
              在容器内也能 docker build（跑 pytest+镜像）
                     │ zentaoatf 回传结果
                     ▼
              禅道用例库 / Bug 看板
```

| 服务 | 镜像 | 宿主机端口 | 用途 |
|---|---|---|---|
| Jenkins | `jenkins/jenkins:lts-jdk17` | 8080 | CI/CD 调度、跑 pytest |
| 禅道 | `easysoft/zentao:22.5` | 9090 | 测试管理（用例/Bug/测试单） |
| MariaDB | `mariadb:10.6` | 3306(仅内网) | 禅道数据库 |

> 端口避坑：禅道容器内部是 80，映射到宿主机 **9090**（避开 Jenkins 的 8080 与常见 80 冲突）。

## 二、一键安装脚本（系统准备 + 装 Docker）

新建 `setup.sh`，把"更新系统、装 Docker、放行防火墙、建目录"一次性做完：

```bash
#!/usr/bin/env bash
set -e
echo "== 1. 更新系统 =="
sudo apt update && sudo apt -y upgrade

echo "== 2. 安装 Docker（官方便捷脚本，含 compose v2）=="
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER        # 当前用户免 sudo 用 docker（重登录后生效）

echo "== 3. 放行防火墙 =="
sudo ufw allow 22/tcp
sudo ufw allow 8080/tcp             # Jenkins
sudo ufw allow 9090/tcp             # 禅道
sudo ufw --force enable

echo "== 4. 创建工作目录 =="
mkdir -p ~/devstack && cd ~/devstack
echo "done. 下一步：把 docker-compose.yml 放到 ~/devstack 后执行 docker compose up -d"
```

执行：

```bash
chmod +x setup.sh && ./setup.sh
# 装完 Docker 后建议重登录一次，使 docker 组生效：
exit   # 然后重新 SSH 登录
```

## 三、一份 docker-compose 编排三个服务

在 `~/devstack/docker-compose.yml`（**照抄**）：

```yaml
version: "3.8"

services:
  # ---------- 禅道数据库 ----------
  zentao-db:
    image: mariadb:10.6
    container_name: zentao-db
    environment:
      MARIADB_ROOT_PASSWORD: Zt@2026Root        # 改成你的强密码
      MARIADB_DATABASE: zentao
      MARIADB_USER: zentao
      MARIADB_PASSWORD: Zt@2026User             # 与禅道 ZT_DB_PASS 一致
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    volumes:
      - ./zentao-mysql:/var/lib/mysql
    restart: unless-stopped

  # ---------- 禅道 ZenTao ----------
  zentao:
    image: easysoft/zentao:22.5
    container_name: zentao
    depends_on:
      - zentao-db
    environment:
      ZT_DB_HOST: zentao-db
      ZT_DB_NAME: zentao
      ZT_DB_USER: zentao
      ZT_DB_PASS: Zt@2026User
    ports:
      - "9090:80"
    volumes:
      - ./zentao-data:/data
    restart: unless-stopped

  # ---------- Jenkins ----------
  jenkins:
    image: jenkins/jenkins:lts-jdk17
    container_name: jenkins
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock   # 让 Jenkins 容器内也能 docker build
    restart: unless-stopped

volumes:
  jenkins_home:
```

启动并验证：

```bash
cd ~/devstack
docker compose up -d
docker compose ps          # 三个都 Up 即 OK
docker compose logs -f jenkins   # 首次启动看初始密码
```

> 若 `docker pull` 中途 `connection reset by peer`（国内常见抖动），直接重跑 `docker compose up -d` 即可，已下的层会续传。

## 四、初始化两个 Web 服务

### 4.1 Jenkins 解锁
浏览器开 `http://服务器IP:8080`，初始密码：
```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```
复制粘贴 → 装「推荐插件」→ 建管理员账号。

### 4.2 禅道安装向导
浏览器开 `http://服务器IP:9090` → 同意协议 → 环境检查 → 数据库填：
- 主机 `zentao-db`、库 `zentao`、用户/密码填 compose 里的 `zentao` / `Zt@2026User`
- 设 admin 强密码 → 登录后台。

## 五、把三者打通成测试管理闭环（核心）

链路：**pytest 写用例 → Jenkins 定时/Webhook 触发 → 容器内跑 pytest（顺带 docker build）→ zentaoatf 把结果回写禅道 → 禅道看板追踪 Bug**。

### 5.1 禅道里建好"测试资产"
参照 `ubuntu-zentao-setup`：建产品 → 建用例模块树 → 写测试用例（记下用例 ID，如 `123`）。

### 5.2 pytest 用例关联禅道（zentaoatf）
```bash
pip install zentaoatf
export ZT_URL=http://服务器IP:9090
export ZT_TOKEN=你的token        # 禅道后台→API 生成
```
```python
# test_login.py
import zentaoatf

@zentaoatf.case(id=123)          # 关联禅道用例 123
def test_login_ok():
    assert login("alice", "pwd123") is True
```
> 装饰器/CLI 以你禅道版本的官方手册为准，部署后核对后台「帮助」。

### 5.3 Jenkinsfile 串起整条流水线
```groovy
pipeline {
    agent { docker { image 'python:3.11-slim' } }   // 临时容器，互不污染
    stages {
        stage('Checkout')      { steps { checkout scm } }
        stage('Install')       { steps { sh 'pip install -r requirements.txt zentaoatf' } }
        stage('Test+Report')    { steps { sh 'pytest tests/ --junitxml=report.xml' } }  // 结果自动回写禅道
        stage('Build Image') {
            when { branch 'main' }
            steps { sh 'docker build -t myapp:$BUILD_ID . && docker push myapp:$BUILD_ID' }
        }
    }
    post {
        always  { junit 'report.xml' }
        failure { mail to: 'you@example.com', subject: '构建失败' }
    }
}
```

## 六、验证整条链路

1. 推一次代码到 Git 仓库 → Jenkins 触发构建（或手动「Build Now」）。
2. 看 Jenkins 控制台：pytest 跑完、`report.xml` 收集。
3. 进禅道 → 那条用例 `123` 的「自动化」状态变成「通过/失败」。
4. 故意改坏一个断言让测试失败 → 禅道用例变红 → 提 Bug 关联该用例。
全绿 + 禅道同步 = 闭环成功。

## 七、备份与维护

```bash
# 全量备份（停服更稳）
cd ~/devstack && docker compose stop
tar -czf stack-backup-$(date +%F).tar.gz zentao-data zentao-mysql
docker compose start
# Jenkins 数据在卷 jenkins_home，单独备份：
docker run --rm -v jenkins_home:/src -v $PWD:/dst busybox tar czf /dst/jenkins-home.tar.gz -C /src .
```

- **升级**：`docker compose pull` 后 `up -d`；禅道/ Jenkins 大版本升级先看官方升级文档。
- **换源**：若某镜像站不稳，编辑 compose 里镜像为 `docker.1ms.run/jenkins/jenkins:lts-jdk17` 之类再 `pull`。

## 八、常见坑排错表

| 现象 | 原因 / 解法 |
|---|---|
| `docker: command not found` | setup.sh 装完需**重登录**使 docker 组生效 |
| pull 时 `connection reset by peer` | 国内抖动，重跑 `docker compose up -d` 续传；或加 `max-concurrent-downloads:1` |
| 禅道装向导连不上库 | compose 里 `ZT_DB_PASS` 与 `MARIADB_PASSWORD` 必须一致；`zentao-db` 要先起 |
| Jenkins 容器内不能 docker | 确认挂载了 `/var/run/docker.sock`；该方式有权限风险，生产可改 dind/kaniko |
| 9090 打不开 | UFW 放行 `9090`；或换别的宿主机端口 |
| zentaoatf 回传失败 | `ZT_URL` 可达、`ZT_TOKEN` 未过期、用例 ID 存在 |
| 中文乱码 | 数据库字符集 `utf8mb4`（compose 已配） |

> 本篇与以下专题互链，建议串看：`ubuntu-cicd-docker-jenkins`、`ubuntu-zentao-setup`、`ubuntu-pytest-roadmap`。
