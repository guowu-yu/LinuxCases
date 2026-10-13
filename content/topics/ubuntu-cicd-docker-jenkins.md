---
slug: ubuntu-cicd-docker-jenkins
title: 实战：用 Docker + Jenkins 搭建自动化测试 CI/CD（新手照抄版）
date: 2026-10-13
tags: [CI/CD, Docker, Jenkins, 自动化测试, 运维实战]
summary: 一步一步、命令照抄即可在一台 Ubuntu 服务器上用 Docker 跑起 Jenkins，搭建能自动跑单元测试/集成测试的 CI/CD 流水线。
---

> 本篇是「Ubuntu Server 技能提升路线图」的实战延伸，把第 12 周（容器）和第 13 周（自动化运维）串成一条能立刻落地的线。目标：哪怕你是新手，照着下面的命令逐条复制执行，也能在一台干净的 Ubuntu 服务器上跑通一套"push 代码 → 自动跑测试 → 出报告"的 CI/CD。

## 你会搭出什么

```
开发者本地               Git 远程仓库              你的 Linux 服务器
  git push  ─────────▶  (GitHub/GitLab)  ─webhook▶  Jenkins 容器
                                                  （运行在 Docker 内）
                                                       │
                                                       ▼
                                                Pipeline 临时容器
                                         拉代码 → 单元测试 → 集成测试 → 构建镜像
                                                       │
                                                       ▼
                                                  测试报告 + 通知（邮件/钉钉）
```

最终效果：你往 Git 仓库 `push` 一次，服务器上的 Jenkins 就自动拉代码、装依赖、跑测试、生成报告，失败还会通知你。

---

## 0. 开始前要准备的东西

| 项目 | 说明 |
|------|------|
| 一台 Linux 服务器 | 推荐 **Ubuntu 22.04 LTS**，2 核 4G 起步，有公网 IP 或内网能访问 |
| 一个 Git 仓库 | GitHub / GitLab / Gitee 都行，用来放你的代码 |
| 一个域名（可选） | 没有也能用 `http://服务器IP:8080` 直接访问 |
| SSH 客户端 | 本地终端即可（Win 用 PowerShell/Git Bash，Mac/Linux 用终端） |

> 下文所有 `你的服务器IP` 都替换成你真实的服务器公网 IP 或域名。

---

## 1. 登录服务器并更新系统

```bash
# 用 root（或已有 sudo 的用户）登录
ssh root@你的服务器IP

# 更新软件源并升级（国内服务器可先把 apt 源换成阿里云/清华源，速度更快）
apt update && apt upgrade -y
```

验证：命令执行完没有红色报错即可。

---

## 2. 建一个普通用户（安全习惯，强烈建议）

不要一直用 root 跑服务。建一个专用用户 `deploy`：

```bash
adduser deploy          # 按提示设置密码，其他信息可一路回车
usermod -aG sudo deploy # 赋予 sudo 权限
```

之后建议切换成这个用户操作：

```bash
su - deploy
```

---

## 3. 配置 SSH 密钥登录（可选但推荐）

本地电脑执行（不是服务器）：

```bash
# 生成本地密钥（已有可跳过）
ssh-keycopy-id deploy@你的服务器IP   # 多数系统自带；没有就用下面两步
# 或手动：把本地 ~/.ssh/id_rsa.pub 内容追加到服务器的 ~/.ssh/authorized_keys
```

服务端加固（改 `/etc/ssh/sshd_config`，把 `PasswordAuthentication yes` 改成 `no`，再 `systemctl restart ssh`），禁止密码登录，防暴力破解。新手可先跳过，等熟悉后再做。

---

## 4. 开启防火墙

```bash
sudo ufw allow OpenSSH     # 先放行 SSH，避免把自己锁外面
sudo ufw allow 8080        # Jenkins Web 端口
sudo ufw enable            # 启用防火墙
sudo ufw status            # 确认规则
```

> 如果服务器在云上（阿里云/腾讯云/AWS），还要在**云控制台的安全组**里放行 8080 和 22 端口，只开防火墙不够。

---

## 5. 安装 Docker（官方源，Ubuntu）

逐条复制执行：

```bash
# 1) 安装依赖
sudo apt install -y ca-certificates curl gnupg lsb-release

# 2) 添加 Docker 官方 GPG 密钥
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 3) 添加 Docker 软件源
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4) 安装 Docker 引擎
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# 5) 验证
sudo docker run hello-world
```

验证：最后一步能拉起一个 hello-world 容器并打印欢迎信息，说明 Docker 装好了。

把当前用户加入 docker 组，免去每次加 `sudo`：

```bash
sudo usermod -aG docker $USER
newgrp docker     # 让当前终端立即生效（或重新登录）
docker ps         # 不再报权限错误即成功
```

---

## 6. 安装 Docker Compose

```bash
sudo apt install -y docker-compose-plugin
docker compose version     # 能看到版本号即成功
```

---

## 7. 用 Docker Compose 部署 Jenkins

建一个工作目录并写配置文件：

```bash
mkdir -p ~/jenkins && cd ~/jenkins
nano docker-compose.yml    # 把下面内容粘贴进去
```

`docker-compose.yml` 完整内容（直接复制）：

```yaml
services:
  jenkins:
    image: jenkins/jenkins:lts      # 长期支持版，稳定
    container_name: jenkins
    ports:
      - "8080:8080"                 # Web 管理界面
      - "50000:50000"               # Agent 通信端口
    volumes:
      - jenkins_home:/var/jenkins_home        # 持久化数据，容器删了数据还在
      - /var/run/docker.sock:/var/run/docker.sock   # 让 Jenkins 能调用宿主 Docker
    restart: unless-stopped         # 服务器重启后自动拉起
volumes:
  jenkins_home:
```

启动：

```bash
docker compose up -d        # -d 后台运行
docker compose ps           # 看到 jenkins 状态为 Up 即成功
docker compose logs -f      # 看启动日志（Ctrl+C 退出）
```

> 关于 `docker.sock` 挂载：这是最简单的"让 Jenkins 里也能跑 docker"方案，但相当于把宿主 Docker 控制权交给了 Jenkins 容器，生产环境建议改用 `jenkinsci/docker-in-docker` 或 `kaniko` 构建镜像。新手阶段先用这个最省事。

---

## 8. 第一次打开 Jenkins 并解锁

1. 浏览器访问 `http://你的服务器IP:8080`。
2. 页面提示输入管理员密码，回到服务器取：

   ```bash
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```

   复制输出的那串字符粘进网页。
3. 选择 **"安装推荐插件"**（Install suggested plugins），等它装完。
4. 创建第一个管理员用户（记好用户名密码）。
5. 实例配置保持默认，点"开始使用 Jenkins"。

---

## 9. 验证 Jenkins 能使用 Docker

```bash
docker exec -it jenkins docker version
```

能在 Jenkins 容器里看到 Docker 版本信息，说明挂载成功，后面流水线里就能直接 `docker build` 了。

---

## 10. 配置 Git 仓库凭据

让 Jenkins 能拉你的私有仓库：

1. Jenkins 首页 → **Manage Jenkins**（系统管理）→ **Credentials**（凭据）→ **System** → **Global credentials** → **Add Credentials**。
2. Kind 选 **Username with password**。
3. Username 填你的 Git 用户名；Password 填 **Personal Access Token**（GitHub 在 Settings → Developer settings → PAT 生成，勾 `repo` 权限；别用登录密码）。
4. ID 填 `git-lab`（好记），点 Create。

---

## 11. 准备一个可照抄的示例项目

如果你还没有现成项目，直接建一个最小 Python 项目，照抄下面 5 个文件，推到你的 Git 仓库，就能立刻看到 CI/CD 跑通。

**`app.py`**（被测代码）

```python
def add(a, b):
    return a + b

def divide(a, b):
    if b == 0:
        raise ValueError("不能除以 0")
    return a / b
```

**`test_app.py`**（测试）

```python
from app import add, divide
import pytest

def test_add():
    assert add(1, 2) == 3

def test_divide():
    assert divide(6, 3) == 2

def test_divide_zero():
    with pytest.raises(ValueError):
        divide(1, 0)
```

**`requirements.txt`**

```
pytest
```

**`Dockerfile`**（用来演示"构建镜像"这步）

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["pytest", "--junitxml=report.xml"]
```

**`Jenkinsfile`**（流水线定义，放在仓库根目录）

```groovy
pipeline {
    agent { docker { image 'python:3.11-slim' } }   // 每条流水线起一个临时容器跑测试
    stages {
        stage('拉取代码') {
            steps { checkout scm }
        }
        stage('安装依赖') {
            steps { sh 'pip install -r requirements.txt' }
        }
        stage('单元测试') {
            steps { sh 'pytest --junitxml=report.xml --cov=app --cov-report=xml' }
        }
        stage('集成测试') {
            steps {
                // 起一个依赖服务作 sidecar，例如数据库，测完自动销毁
                sh 'docker run -d --name db postgres:16 || true'
                sh 'echo "这里跑需要数据库的集成测试，例如 pytest tests/integration"'
            }
        }
        stage('构建并推送镜像') {
            when { branch 'main' }      // 只在 main 分支才构建
            steps {
                sh 'docker build -t myapp:$BUILD_ID .'
                sh 'docker tag myapp:$BUILD_ID myapp:latest'
            }
        }
    }
    post {
        always {
            junit 'report.xml'           // 把测试报告显示在 Jenkins 任务页
        }
        success {
            echo '构建与测试通过 ✅'
            // 想接钉钉/邮件通知，见第 15 步
        }
        failure {
            echo '构建或测试失败 ❌'
        }
    }
}
```

把这 5 个文件 `git push` 到你的仓库。

---

## 12. 在 Jenkins 创建 Pipeline 任务

1. 首页点 **New Item**（新建任务）→ 输入名称 `my-first-pipeline` → 选 **Pipeline** → OK。
2. 翻到 **Pipeline** 配置区：
   - Definition 选 **Pipeline script from SCM**（从仓库读取 Jenkinsfile）。
   - SCM 选 **Git**。
   - Repository URL 填你的仓库地址（如 `https://github.com/你的名/你的仓库.git`）。
   - Credentials 选第 10 步建的 `git-lab`。
   - Branch 填 `*/main`（按你默认分支改）。
   - Script Path 填 `Jenkinsfile`。
3. 点 **Save**。
4. 点 **Build Now**（立即构建），左下角会出现构建进度，点进去看控制台输出。

验证：构建变绿（Blue/成功），任务页出现 **Test Result** 和覆盖率，说明整套 CI/CD 跑通了。

---

## 13. 让 push 自动触发（Webhook）

不想每次手动点"立即构建"，配 Webhook 让它自动跑：

1. 打开你的 Git 仓库 → **Settings → Webhooks → Add webhook**（GitHub 路径；GitLab 在 Settings → Webhooks）。
2. Payload URL 填：`http://你的服务器IP:8080/github-webhook/`
   > 注意末尾的斜杠 `/` 不能省，否则 Jenkins 收不到。
3. Content type 选 `application/json`。
4. 触发事件勾 **Just the push event**（或默认的 push）。
5. 点 Add webhook，看到那个钩子前面是绿色对勾即配置成功。

6. 回到 Jenkins 任务配置 → **Build Triggers**（构建触发）→ 勾选 **GitHub hook trigger for GITScm polling** → Save。

测试：在你本地改一行代码 `git push`，几秒内 Jenkins 就会自动开始构建。

---

## 14. 查看测试报告

构建完成后进任务页：

- **Test Result**：看到每个测试用例的通过/失败（来自 `junit 'report.xml'`）。
- 如果装了 **JaCoCo** 或 **Coverage** 类插件，还能看覆盖率趋势。
- 报告没出来，先检查 `Jenkinsfile` 里 `junit` 后面的路径和 `pytest --junitxml=` 生成的文件名是否一致。

---

## 15. 失败通知（邮件 / 钉钉）

**邮件（Email Extension 插件）**

1. Manage Jenkins → Plugins → 搜 `Email Extension` 安装。
2. Manage Jenkins → System → 配置 SMTP（QQ/163 邮箱开 SMTP 服务拿授权码）。
3. 在 `Jenkinsfile` 的 `post` 里加：

```groovy
failure {
    mail to: 'you@example.com',
         subject: "构建失败：${env.JOB_NAME} #${env.BUILD_NUMBER}",
         body: "查看详情：${env.BUILD_URL}"
}
```

**钉钉**

1. 群聊里加机器人，拿到 Webhook 地址。
2. 装 `DingTalk` 插件，在 Jenkins 系统配置里填机器人 token。
3. `post` 里加 `dingTalk` 步骤（具体写法见插件说明，不同版本略有差异）。

---

## 16. 备份与安全

**备份 Jenkins 数据**（最重要，否则容器一删全没）：

```bash
# 在宿主机执行，把 jenkins_home 卷打包
docker run --rm -v jenkins_jenkins_home:/data -v $(pwd):/backup busybox \
  tar czf /backup/jenkins-backup-$(date +%F).tar.gz -C /data .
```

**安全要点**

- 暴露到公网的 Jenkins 一定要加账号密码 + 反向代理 HTTPS，别裸奔 8080。
- `docker.sock` 挂载有提权风险，正式环境改用 docker-in-docker 或 kaniko。
- 凭据只存在 Jenkins 凭据里，别写进 Jenkinsfile 明文。
- 定期清理构建历史（Manage Jenkins → 相应任务 → 丢弃旧构建），避免磁盘爆满。

---

## 17. 新手最常踩的 10 个坑（排错表）

| 现象 | 原因 | 解决 |
|------|------|------|
| 浏览器打不开 8080 | 防火墙/云安全组没开 | 回看第 4 步，云控制台也要开 |
| 取不到初始密码 | 容器名不是 `jenkins` | `docker ps` 看真实名字再 `docker exec` |
| 插件安装慢/超时 | 默认源在国外 | 换 Jenkins 国内插件源（清华/中科大） |
| webhook 不触发 | URL 漏了末尾 `/` 或服务器无公网 | 补 `/`；确认 IP 公网可达 |
| Jenkins 里 `docker` 命令找不到 | sock 没挂载 | 检查 compose 里 `/var/run/docker.sock` 那行 |
| 构建卡在 Clone | 凭据错/仓库私有 | 核对第 10 步凭据与仓库地址 |
| pytest 找不到 | agent 镜像没装依赖 | `Jenkinsfile` 里先 `pip install -r requirements.txt` |
| 测试报告空白 | junit 路径不匹配 | 保证 `pytest --junitxml=report.xml` 与 `junit 'report.xml'` 同名 |
| 磁盘满了 | 没清构建历史 | 配"丢弃旧构建"策略 |
| 容器重启数据丢 | 没挂数据卷 | 确认 `jenkins_home` 卷已挂载 |

---

## 下一步可以做什么

- 接入 **多分支流水线**（Multibranch Pipeline），让每个 PR 自动跑测试再合并。
- 用 **Docker Compose** 在流水线里起一整套依赖（数据库+缓存+消息队列）做端到端测试。
- 把"构建镜像→推 registry→服务器拉取重启"补全，做成真正的 CD（持续部署）。
- 参考路线图第 9 周把 Jenkins 前面加上 nginx + HTTPS，第 13 周用 Ansible 批量管理多台构建机。
