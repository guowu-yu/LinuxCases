---
title: 第 12 周：容器与虚拟化
slug: ubuntu-containers-virtualization
date: 2026-10-12
tags: [LXD, Docker, KVM, 容器, 第12周]
summary: 分清 LXD 系统容器、Docker 应用容器与 KVM 虚拟机，按场景选对虚拟化方式。
---

<p class="week-badge">WEEK 12 · 进阶阶段</p>

## 本周目标

- 分清三类虚拟化：系统容器、应用容器、虚拟机
- 用 Docker 容器化一个简单应用
- 用 LXD 起一台系统容器当轻量虚拟机用
- 知道何时该用哪一种

> 验收标准：一个微服务，你能说出该用 Docker、LXD 还是 KVM 跑，并说出理由。

## 三种方式对比

| 方式 | 隔离 | 开销 | 典型场景 |
| --- | --- | --- | --- |
| **Docker** | 进程级，共享内核 | 最小 | 应用打包、CI、微服务 |
| **LXD/Incus** | 系统容器，共享内核 | 小 | 轻量整机、多租户、跑 systemd |
| **KVM/QEMU** | 完整虚拟机 | 大 | 异构系统、强隔离、Windows |

## Docker 速览

```bash
sudo apt install -y docker.io
sudo usermod -aG docker $USER        # 重新登录生效

docker run --rm hello-world
docker run -d --name web -p 8080:80 nginx:alpine
docker ps
docker logs web -f
docker exec -it web sh
docker stop web && docker rm web
```

Dockerfile 示例：

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["python", "-m", "http.server", "8000"]
```

```bash
docker build -t myapp:1.0 .
docker run -d -p 8000:8000 myapp:1.0
```

## LXD 系统容器

LXD/Incus 跑的是"完整系统容器"，里头有 systemd，像台轻量虚拟机但快得多。

```bash
sudo snap install lxd
lxd init --auto
lxc launch ubuntu:24.04 vm1
lxc list
lxc exec vm1 -- bash
```

> 当你要多台 Ubuntu 做集群实验、又不想烧资源时，LXD 比 KVM 划算。

## KVM 虚拟机

强隔离、跑异构系统的选择：

```bash
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst
sudo virt-install --name test --ram 2048 --vcpus 2 --disk size=20 --cdrom ubuntu.iso --os-variant ubuntu24.04
virsh list --all
```

## 实战任务

1. 用 Dockerfile 把一个 Python web 服务打包成镜像，跑起来并在浏览器访问。
2. 用 LXD 起一台系统容器，进去装个 nginx，像管真机一样管它。
3. 对比 Docker 容器与 LXD 容器：一个里跑单进程、另一个里跑 systemd，记录差异。
4. 解释：为什么数据库服务常选虚机/LXD 而不选 Docker。

## 命令速查

| 命令 | 作用 |
| --- | --- |
| `docker build/run/ps/logs/exec` | 镜像与容器操作 |
| `docker run -d -p h:c img` | 后台跑 + 端口映射 |
| `lxc launch/list/exec` | 系统容器操作 |
| `virsh list/install` | KVM 虚机操作 |

## 常见坑

- **没加 docker 组**：每条 docker 都要 sudo，加组重登即可。
- **容器当虚拟机用**：Docker 容器默认一进程退出即结束，跑系统服务很别扭——那是 LXD 的活。
- **数据放容器里**：容器一删数据没了，重要数据用 volume 或挂宿主目录。

## 参考资料

- Docker 文档：https://docs.docker.com/
- LXD：https://linuxcontainers.org/lxd/

---

下一步：[第 13 周 · 自动化运维](ubuntu-automation-ansible.html)。会跑容器了，把重复操作交给自动化。