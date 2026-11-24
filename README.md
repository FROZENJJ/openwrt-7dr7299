# TP-Link TL-7DR7299 v1 固件

适用于 **TP-Link TL-7DR7299 硬件 v1**，保留 MediaTek MT7992 闭源 Wi‑Fi 驱动。日常使用选 **6.6**。已有第三方 U‑Boot、能够恢复固件并愿意验证网口和无线，再考虑 **6.12 预览版**。

## 选哪个版本

| 版本 | 适合谁 | 无线与网络 | 下载 |
| --- | --- | --- | --- |
| **Linux 6.6.94 · 日用版** | 首次安装本项目固件，或用作家里唯一一台主路由 | ImmortalWrt 24.10 系列，MT7992 闭源驱动，RTL837x 使用 swconfig | [6.6 日用版 · 60.38 MiB](https://github.com/FROZENJJ/openwrt-7dr7299/releases/tag/6.6.94-vantage-no-docker-20261124) |
| **Linux 6.12.116 · 预览版** | 想测试 25.12 软件环境或 DSA 网口配置，有条件恢复 6.6 | ImmortalWrt 25.12-SNAPSHOT，MT7992 闭源驱动，RTL837x 使用 DSA | [6.12 预览版 · 55.24 MiB](https://github.com/FROZENJJ/openwrt-7dr7299/releases/tag/6.12.116-vantage-no-docker-preview-20261124) |

表中体积为 sysupgrade 镜像大小。6.12 沿用该机型的 NAND 分区和无线校准位置，已完成构建及镜像校验。启动、WAN/LAN、SFP、Wi‑Fi 和硬件转发仍待真机验证，因此以 GitHub **Pre-release** 发布。

## 下载和升级

1. 看机身标签，确认型号是 **TL-7DR7299 v1**，并确认已装与该机型匹配的第三方 U‑Boot。原厂固件需要先走对应的过渡和引导安装流程。 [7DR7299 刷机教程](https://mao.fan/article/582)
2. 在选定版本的 **Assets** 中下载文件名包含 `tplink_tl-7dr7299-v1` 且以 `squashfs-sysupgrade.itb` 结尾的镜像，用同页 `sha256sums` 核对。Windows 可运行 `Get-FileHash .\文件名 -Algorithm SHA256`。
3. 备份当前配置和可用固件，通过网线进入 LuCI 的「系统 → 备份与升级」上传镜像。**在 6.6 和 6.12 间切换时取消保留配置**，刷好后重新配置 WAN、VLAN 和 Wi‑Fi。遇到机型或镜像校验失败时停止升级。
4. 干净启动后从 LAN 打开 `http://10.0.1.1`，用户名为 `root`。本页链接的 6.6 日用版初始密码为 `password`，登录后立即更改。6.12 预览版首次登录使用空密码，接上 WAN 前在 LuCI 设置密码。

`initramfs-recovery.itb` 用于具备相应功能的第三方 U‑Boot 启动恢复系统，具体入口以所装 U‑Boot 为准。日常升级用 `squashfs-sysupgrade.itb`，预览测试前确认能进入恢复界面并备好 6.6 镜像。项目按 **128 MiB NAND、119.5 MiB UBI** 布局构建，发布时限制 sysupgrade 镜像不超过 **96 MiB**。

## 后台和插件

- 两个版本的无 Docker 配方均包含 Vantage 主题、中文状态仪表盘、计划任务和内核参数页面。可在「系统 → 语言和界面」切换 Bootstrap。两版也内置 PassWall（Xray）、SmartDNS、DDNS‑Go、UPnP、DiskMan 和 Samba4。
- 在「服务 → FastNet」启动内网测速，网页默认地址为 `http://10.0.1.1:3200/webui/`。用 FastNet 比较局域网吞吐，用无线状态页的 RSSI（dBm）比较信号强度。
- 两版均预留同批编译的 `kmod-tun`，EasyTier 可另外安装。核对 IPK 依赖和 `/overlay` 可用空间后，在 LuCI 的软件包页面先上传 `easytier`，再上传 `luci-app-easytier`。 [EasyTier 官方 LuCI 下载](https://github.com/EasyTier/luci-app-easytier/releases)
- **6.6** 使用 `opkg` 和 ImmortalWrt 24.10 用户态软件源。**6.12** 保留 `opkg`，可以逐包安装依赖匹配的 `aarch64_cortex-a53` 或 `all` IPK。Kiddin9 25.12 有对应架构的包，当前索引没提供 `Packages.sig`，预览版默认未启用该源。普通 LuCI 插件也要核对依赖，内核模块只能用本固件同次编译的包。 [Kiddin9 25.12 软件包目录](https://dl.openwrt.ai/releases/25.12/packages/aarch64_cortex-a53/kiddin9/)

## 自行编译

- **6.6**　Fork 本仓库，在自己的 Actions 页面手动运行 `Build TP-Link 7DR7299 No-Docker (USB Docker Kernel Ready)`。源码来自 [padavanonly 的 6.6 分支](https://github.com/padavanonly/immortalwrt-mt798x-6.6/tree/mt798x-mt799x-6.6-mtwifi)。
- **6.12**　使用 Ubuntu 或 WSL2 的 Linux 文件系统，把本仓库与 OpenWrt 源码分别存放。进入固定提交的底座源码目录，依次执行下面的命令。 [6.12 Wi‑Fi 7 底座](https://github.com/chasey-dev/immortalwrt-mt798x-rebase/tree/dca94685cd73309b9902b1976aab4b2deccf86eb) · [TL-7DR7299 v1 板级移植](https://github.com/coolsnowwolf/lede/commit/1d585dc90248b09ff61358e504edf2a302d3493a)

```sh
# 在两个工作目录的共同父目录执行
git clone https://github.com/FROZENJJ/openwrt-7dr7299.git firmware-7dr7299
git init openwrt-6.12
git -C openwrt-6.12 fetch --depth=1 \
  https://github.com/chasey-dev/immortalwrt-mt798x-rebase.git \
  dca94685cd73309b9902b1976aab4b2deccf86eb
git -C openwrt-6.12 checkout --detach FETCH_HEAD
cd openwrt-6.12
bash ../firmware-7dr7299/scripts/diy-part1.sh
./scripts/feeds update -a
./scripts/feeds install -a
bash ../firmware-7dr7299/scripts/prepare-6.12.sh
make defconfig
make download -j8
make -j6
bash ../firmware-7dr7299/scripts/verify-firmware.sh 6.12
```

6.12 产物在 `bin/targets/mediatek/filogic/`。Release 附带软件包清单、构建配置信息和 SHA‑256 校验值，便于比对不同次构建。
