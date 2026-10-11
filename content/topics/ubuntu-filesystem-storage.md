---
title: 第 4 周：文件系统与存储管理
slug: ubuntu-filesystem-storage
date: 2026-10-12
tags: [磁盘, LVM, 挂载, fstab, 第4周]
summary: 从分区到 LVM，再到挂载与开机自动挂载，掌握 Ubuntu Server 存储管理的完整链路。
---

<p class="week-badge">WEEK 04 · 系统阶段</p>

## 本周目标

- 看懂块设备、分区表、文件系统三者的关系
- 用 LVM 创建逻辑卷，掌握扩容（含 xfs/ext4 在线扩展）
- 配置 `/etc/fstab` 实现开机自动挂载，并用 UUID 避免盘符漂移
- 识别 ext4 / xfs 的场景差异

> 验收标准：给机器加一块 20G 数据盘，分区→建卷→格式化→挂载→写 fstab→重启依然在。

## 存储三层模型

```
块设备 /dev/sdb
   └─ 分区 /dev/sdb1 （或直接整盘做 PV）
        └─ PV (Physical Volume)
             └─ VG (Volume Group)  ← 把多块盘揉成一个池
                  └─ LV (Logical Volume)  ← 从池里切出"虚拟盘"
                       └─ mkfs → 文件系统 ext4/xfs
                            └─ mount 到目录
```

> LVM 的价值：卷能**在线扩容**，把多块小盘拼成大盘，生产环境几乎必用。

## 认识磁盘与分区

```bash
# 看块设备
lsblk
sudo fdisk -l
sudo parted -l

# 看文件系统与挂载
df -hT
findmnt
```

分区工具选择：

| 工具 | 适用 | 说明 |
| --- | --- | --- |
| `fdisk` | MBR / 小盘 | 经典，最多 2TB |
| `gdisk` | GPT | 支持 GPT，大盘必选 |
| `parted` | 通用 / 脚本 | 可脚本化，推荐 |

```bash
# parted 给 /dev/sdb 建一个 GPT 全盘分区
sudo parted /dev/sdb mklabel gpt
sudo parted /dev/sdb mkpart primary ext4 0% 100%
```

## LVM 实战

```bash
# 1. 把分区做成 PV
sudo pvcreate /dev/sdb1
sudo pvs

# 2. 建 VG（名为 data）
sudo vgcreate data /dev/sdb1
sudo vgs

# 3. 从 VG 切一个 LV（名为 appdata，先用 15G）
sudo lvcreate -L 15G -n appdata data
sudo lvs

# 4. 格式化（ext4 或 xfs 二选一）
sudo mkfs.ext4 /dev/data/appdata
# 或
sudo mkfs.xfs /dev/data/appdata

# 5. 挂载
sudo mkdir -p /srv/appdata
sudo mount /dev/data/appdata /srv/appdata
```

## 扩容：LVM 最爽的时刻

场景：VG 里还有空闲空间，要把 appdata 从 15G 扩到 20G。

```bash
# 扩展 LV（自动用 VG 剩余空间）
sudo lvextend -L +5G /dev/data/appdata
# 或直接到 20G
sudo lvextend -L 20G /dev/data/appdata

# 扩展文件系统（区分格式）
sudo resize2fs /dev/data/appdata      # ext4 在线扩展
sudo xfs_growfs /srv/appdata          # xfs 必须挂载后扩展，用挂载点
```

> xfs 只能扩大不能缩小；ext4 可缩（但要卸载离线做）。规划盘体时想清楚。

## 开机自动挂载：/etc/fstab

```bash
# 拿 UUID（别用 /dev/sdb1，盘符会漂）
sudo blkid /dev/data/appdata
```

编辑 fstab：

```
UUID=1234abcd-....   /srv/appdata   ext4   defaults,noatime   0  2
```

字段：`设备  挂载点  类型  挂载选项  dump  fsck顺序`。验证不重启：

```bash
sudo mount -a         # 没报错就对了
sudo findmnt /srv/appdata
```

> **黄金习惯**：永远用 UUID；改完 fstab 一定 `mount -a` 验证，否则开机进不了系统。

## 实战任务

1. 加一块 20G 盘，用 parted 建 GPT 分区，做成 PV→VG→LV（15G）→ext4→挂 `/srv/data`。
2. 写好 fstab，`mount -a` 验证，`umount` 后重启，确认仍自动挂载。
3. 把 LV 扩到 20G，`resize2fs` 在线扩展，`df -h` 确认容量变化。
4. 解释为什么 fstab 不该用 `/dev/sdb1` 而该用 `UUID=`。

## 命令速查

| 命令 | 作用 |
| --- | --- |
| `lsblk` / `df -hT` | 看块设备 / 看文件系统 |
| `parted ... mkpart` | 建分区 |
| `pv/vg/lvcreate` | 创建 PV/VG/LV |
| `lvextend` | 扩容逻辑卷 |
| `resize2fs` / `xfs_growfs` | 扩展文件系统 |
| `mkfs.ext4` / `mkfs.xfs` | 格式化 |
| `blkid` | 查 UUID |
| `mount -a` | 验证 fstab |

## 常见坑

- **重启卡 emergency mode**：fstab 写错，没 `mount -a` 验证就重启。
- **盘符漂移**：重启后 `/dev/sdb` 变 `/dev/sdc`，用 UUID 一劳永逸。
- **xfs 缩容**：不支持，规划时别保守到非缩不可。
- **VG 没空间还 lvextend**：先 `vgextend data /dev/sdc1` 给池加料再扩。

## 参考资料

- LVM howto：https://tldp.org/HOWTO/LVM-HOWTO/
- `man fstab` / `man blkid`

---

下一步：[第 5 周 · 软件包与 APT](ubuntu-apt-packaging.html)。存储铺好了，该往机器上装东西了。