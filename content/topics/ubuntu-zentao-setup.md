---
slug: ubuntu-zentao-setup
title: 禅道 ZenTao 介绍与 Ubuntu 服务器搭建 · 打造成你的测试管理系统
date: 2026-10-14
tags: [禅道, ZenTao, 测试管理, 项目管理, Docker, Ubuntu, 自动化测试]
summary: 从禅道是什么讲起，手把手在 Ubuntu 服务器用 Docker 部署禅道开源版，并配置成专属测试管理系统（用例/测试单/Bug），再接上 pytest + zentaoatf 自动化回传，形成测试管理闭环。
---

> 本篇是「Ubuntu Server 技能提升路线图」的实战延伸，和你前面已搭好的 **Docker + Jenkins + pytest** 直接衔接：
> - **禅道** 管"测试资产"——测试用例、测试单、Bug；
> - **pytest** 管"测试执行"——真正把用例跑起来；
> - **zentaoatf**（禅道自动化测试框架）把 pytest 结果自动回传到禅道用例；
> - **Jenkins** 负责定时/触发调度整条流水线。
>
> 目标——**照着做，1 小时内拥有一套跑在你自己服务器上的测试管理系统**，数据全留本地，不依赖任何商业 SaaS。

## 一、禅道是什么（先认识它）

禅道（ZenTao）是**国产开源项目管理软件**，在浏览器里就能管「产品 / 项目 / 测试 / 文档 / 组织」。

- **开源版免费**、可私有部署：数据留在你自己的服务器，过得了内网/审计。本文用开源版 **22.5**（2026 年发版）。
- **测试管理是禅道的核心强项**，不是附属功能：它把「需求 → 用例 → 测试单 → Bug」做成了一条可追踪的闭环。
- 一个 Bug 能**反向关联到具体需求和测试用例**；一条用例能知道它被哪些测试单执行过、通过率多少——这正是零散 Excel / 群聊管测试做不到的。

```
需求(Product) ──拆──▶ 测试用例(Case) ──编入──▶ 测试单(TestTask)
   ▲                                            │
   │                                            ▼
   └──────────── Bug ───────────────────── 执行结果(通过/失败)
```

## 二、为什么它能成为"适合你的测试管理系统"

| 你现在的痛点 | 禅道给出的解法 |
|---|---|
| 用例散在 Excel / 聊天记录 | 统一"用例库"，按模块树组织，可检索、可复用 |
| 不知道该验哪条需求 | 用例能关联需求，需求变更时一键看影响范围 |
| Bug 在群里传来传去丢上下文 | Bug 自带重现步骤、附件、严重程度，并关联用例 |
| 自动化测试跑了但没沉淀 | zentaoatf 把 pytest 结果回写禅道用例"自动化"状态 |
| 想私有部署、数据不出内网 | 开源版一键/Docker 自托管，零授权费 |

## 三、服务器准备（Ubuntu Server）

最低配置建议：**2 核 4G**（禅道 + 数据库建议 4G 内存更稳），Ubuntu 20.04 / 22.04 / 24.04 均可。

```bash
# 1) 更新系统
sudo apt update && sudo apt -y upgrade

# 2) 你已学过 SSH 密钥登录 + 关密码登录 + UFW，这里只放服务端口
#    用 Docker 方式我们映射 8080；若用 nginx 反代则放 80/443
sudo ufw allow 8080/tcp
sudo ufw allow 22/tcp
sudo ufw enable

# 3) 确认 Docker 已装（你前面 W12 已装过；没装则先装）
docker --version          # 有输出即 OK
docker run --rm hello-world
```

> 生产建议：在 8080 前再放一层 **nginx + HTTPS**，别裸暴露。本文先把链路跑通，HTTPS 见文末"进阶"。

## 四、方式一：Docker 部署（推荐，衔接你的 Docker 知识）

官方镜像 `easysoft/zentao`，开源版标签 `22.5`。下面用 **docker-compose + 外置 MariaDB**，长期运维最干净。

```bash
# 建工作目录
mkdir -p ~/zentao && cd ~/zentao
```

`docker-compose.yml`（**照抄**）：

```yaml
version: "3.8"

services:
  db:
    image: mariadb:10.6
    container_name: zentao-db
    environment:
      MARIADB_ROOT_PASSWORD: Zt@2026Root          # 改成你自己的强密码
      MARIADB_DATABASE: zentao
      MARIADB_USER: zentao
      MARIADB_PASSWORD: Zt@2026User               # 改成你自己的强密码
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    volumes:
      - ./mysql:/var/lib/mysql
    restart: unless-stopped

  zentao:
    image: easysoft/zentao:22.5
    container_name: zentao
    depends_on:
      - db
    environment:
      ZT_DB_HOST: db
      ZT_DB_NAME: zentao
      ZT_DB_USER: zentao
      ZT_DB_PASS: Zt@2026User                    # 与上面 MARIADB_PASSWORD 一致
    ports:
      - "8080:80"
    volumes:
      - ./data:/data                             # 禅道附件/配置持久化
    restart: unless-stopped
```

启动并验证：

```bash
docker compose up -d
docker compose ps          # 两个容器都 Up 即 OK
docker logs -f zentao      # 首次启动会初始化，看到 "Zentao started" 即可
```

浏览器打开 **http://你的服务器IP:8080** —— 进入安装向导。

> **想更省事？** 用禅道**内置 MySQL**（不用外置 db 容器）：把上面 `db` 段删掉，禅道容器加一行 `MYSQL_INTERNAL=true` 即可，数据仍在 `./data` 卷里。适合单机试玩。

## 五、方式二：官方一键安装包（最省事备选）

如果你不想碰 Docker，禅道提供**自带 Apache+MySQL+PHP 的集成包**，解压即用。

```bash
# 下载 Linux 一键包（以 22.5 为例，去官网下载页取最新链接）
cd /tmp
wget https://www.zentao.net/dl/zentao-22.5-linux.tar.gz
sudo tar -zxvf zentao-22.5-linux.tar.gz -C /opt     # 必须解压到 /opt

# 启动（集成包自带 zbox 控制脚本）
sudo /opt/zentao/zbox/ztli.sh start
```

访问 **http://你的服务器IP**（默认 80 端口）。升级/停止用同一个 `ztli.sh`。

> 还有官方"一行安装"：`curl -sfL https://pkg.zentao.net/devops.sh | sh -`（默认装开源版最新稳定）。生产环境建议先看脚本再跑。

## 六、初始化安装向导（两种方式都会走到这）

1. 浏览器打开地址 → 点「开始安装」→ 同意协议。
2. **环境检查**：PHP/数据库扩展全绿即通过。
3. **数据库配置**：
   - 用外置库（方式一）：主机 `db`、库 `zentao`、用户/密码填 compose 里的值；
   - 用内置库（MYSQL_INTERNAL）：直接设一个 root 密码即可。
4. **设置管理员**：账号 `admin`，密码务必改成强密码（这是你测试系统的"钥匙"）。
5. 点「登录」进后台。

## 七、把它配置成"你的测试管理系统"（核心实操）

进系统后，按下面顺序把禅道变成专属测试台：

### 7.1 建产品
「产品」视图 → 新建产品（如 `MyTestProject`），填名称、代号。**测试是挂在产品下的**，所以先有产品。

### 7.2 搭测试用例模块树
「测试」→「用例」→ 左侧模块树「维护模块」，按你的系统分层：
```
MyTestProject
├─ 登录模块
├─ 订单模块
└─ 支付模块
```

### 7.3 写测试用例
「用例」→「建用例」：填标题、步骤、预期结果、用例类型（功能/接口/性能）。例：

| 用例标题 | 步骤 | 预期 |
|---|---|---|
| 登录-正确账号可登录 | 1.打开登录页 2.输入正确账号密码 3.点登录 | 跳转到首页，右上角显示用户名 |

### 7.4 编测试套件（Suite）
「测试」→「套件」→ 新建套件，把相关用例**批量加入**。套件 = "这一轮要测的一组用例"。

### 7.5 派测试单（TestTask）
「测试」→「测试单」→ 新建：选产品、选用例范围、指派给测试员、设起止时间。测试员执行后逐条标"通过/失败"。

### 7.6 提 Bug 并关联
测试失败时，「测试」页直接「转 Bug」或「Bug」视图新建：填**重现步骤**、严重程度、优先级，并**关联对应用例和需求**。这样复盘时一眼看清"哪个需求、哪条用例、出了什么 Bug"。

### 7.7 看测试报表
「测试」→「报表」：用例覆盖率、Bug 分布、各模块通过率一目了然——这就是你"测试管理系统"的 dashboard。

## 八、接上你的自动化测试（关键：zentaoatf）

禅道自带 **zentaoatf**（自动化测试框架），能让 pytest 用例和禅道用例**双向关联**，跑完自动把结果回写禅道。流程：

```bash
pip install zentaoatf          # 安装客户端

# 配置禅道地址与管理员 token（在 后台→API→生成一个 token）
export ZT_URL=http://你的服务器IP:8080
export ZT_TOKEN=你的token
```

在 pytest 用例里关联禅道用例 ID（示意，具体装饰器以你禅道版本的官方手册为准）：

```python
# test_login.py
import zentaoatf  # 引入后启用关联能力

@zentaoatf.case(id=123)        # 123 = 禅道里那条"登录-正确账号可登录"用例 ID
def test_login_ok():
    assert login("alice", "pwd123") is True
```

```bash
# 跑测试，结果自动回传到禅道用例的"自动化"状态
pytest test_login.py
```

> ⚠️ **核对官方文档**：zentaoatf 的装饰器/CLI 参数会随版本微调，部署后请以你禅道版本的官方手册为准（后台「帮助」或 https://www.zentao.net/book ）。上面的代码是**通用示意**，先把 pytest 用例写好，再按官方文档接入回传即可。

## 九、与 Jenkins / pytest 流水线打通（闭环）

把你上一个 CI/CD 专题的 `Jenkinsfile` 加一段"跑测试并回传禅道"：

```groovy
stage('Test & Report to ZenTao') {
    steps {
        sh 'pip install -r requirements.txt zentaoatf'
        sh 'pytest tests/ --junitxml=report.xml'   // 本地跑 + 结果回传禅道
        junit 'report.xml'                          // Jenkins 也保留报告
    }
}
```

这样：**push 代码 → Jenkins 触发 → pytest 跑 → 结果写回禅道用例 → Bug 自动关联**，你的"测试管理系统"就活了。

## 十、备份与维护

```bash
# 备份数据卷（停服更稳）
docker compose stop
tar -czf zentao-backup-$(date +%F).tar.gz ./data ./mysql
docker compose start

# 数据库单独备一份
docker exec zentao-db mysqldump -uroot -pZt@2026Root zentao > zentao-db.sql
```

- **升级**：`docker compose pull` 拉新镜像后 `up -d`；或集成包用 `ztli.sh` 升级。
- **清理**：后台「系统」→「备份」可自动保留 N 份；附件大的话定期归档。

## 十一、常见坑排错表

| 现象 | 原因 / 解法 |
|---|---|
| 8080 打不开 | UFW 没放行 `sudo ufw allow 8080`；或容器没起 `docker compose ps` |
| 安装向导卡在"环境检查" | 缺 PHP 扩展（一键包自带，Docker 官方镜像也自带；自建 PHP 才需手动装） |
| 连不上数据库 | compose 里 `ZT_DB_PASS` 与 `MARIADB_PASSWORD` 必须一致；db 容器要先起 |
| 禅道中文乱码 | 数据库字符集务必 `utf8mb4`（本文 compose 已配） |
| 内存不足 OOM | 升到 4G；或换内置库减少一个容器 |
| zentaoatf 回传失败 | 检查 `ZT_URL` 可达、`ZT_TOKEN` 未过期、用例 ID 存在 |
| 访问很慢 | 磁盘 IO 或内存swap，加 swap 或升配 |

## 十二、小结与下一步

到这里你拥有了一套**私有、免费、可自动化的测试管理系统**：禅道管用例与 Bug，pytest 跑执行，zentaoatf 回传，Jenkins 调度。

- 下一步可把禅道接入你 **W13 的 Ansible**，实现"一条命令在多台测试机部署禅道"；
- 或把禅道用例和 **pytest 学习路线图** 的练习项目打通，边学边沉淀成真实用例库。

> 本篇与以下专题互链，建议串起来看：`ubuntu-cicd-docker-jenkins`（CI/CD 底座）、`ubuntu-pytest-roadmap`（测试怎么写）、本文（测试怎么管）。
