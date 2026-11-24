# TP-Link TL-7DR7299 (v1) 闭源 Wi-Fi 固件云编译包

本配置包基于 [padavanonly/immortalwrt-mt798x-6.6](https://github.com/padavanonly/immortalwrt-mt798x-6.6) 的 `mt798x-mt799x-6.6-mtwifi` 分支，专为 **TP-Link TL-7DR7299 (v1)** 定制，适合通过 **GitHub Actions** 免费一键云编译。

## 内置功能一览

* **无线与加速**：MediaTek 闭源 `mtwifi` 驱动 + TurboACC（HNAT/WED 硬件加速与全锥形 NAT）
* **基础网络**：PPPoE 拨号（适配 2000M 宽带）、完整 IPv6、UPnP
* **后台界面**：Vantage 主题和简体中文仪表盘，显示网络路径、客户端和吞吐量。附带计划任务、内核参数、软件包管理、`nano` 和 `htop`。可在 LuCI 的「系统 → 语言和界面」切回 Bootstrap。
* **核心插件**：
  * **阿里云 DDNS**：`ddns-go` (`luci-app-ddns-go`)
  * **科学上网**：[PassWall](https://github.com/Openwrt-Passwall/openwrt-passwall)（仅保留 **Xray** 核心，精简体积）+ `dnsmasq-full` + `kmod-nft-tproxy`
  * **DNS 加速**：[SmartDNS](https://github.com/pymumu/smartdns)
  * **内网测速**：FastNet，包含网页测速服务和 LuCI 设置页。
* **USB 3.0**：USB 3.0 / UAS 驱动、`ext4` / `exFAT` / `NTFS3`、DiskMan 和 Samba4。Docker 程序为可选构建项。

## 一、GitHub Actions 云编译步骤

1. 在 GitHub 上新建一个**空白仓库**（公开或私有均可，例如 `openwrt-7dr7299`）。
2. 解压本压缩包，将里面的 `.github/`、`configs/`、`scripts/` 和 `README.md` 推送（或通过网页 Upload files）到仓库根目录。
   * 注意：若使用网页上传，`.github/workflows/build-7dr7299.yml` 需要在网页手动建目录或直接用 `git push` 推送（推荐用 `git push`，不会漏掉隐藏目录 `.github`）。
3. 进入仓库 **Settings → Actions → General → Workflow permissions**，勾选 **Read and write permissions** 并保存（用于自动发布 Release）。
4. 进入 **Actions** 并运行 **Build TP-Link 7DR7299 No-Docker (USB Docker Kernel Ready)**。默认后台 IP 为 `10.0.1.1`，默认发布标签为 `6.6-vantage-no-docker`。
5. 构建和检查通过后，在 **Releases** 下载 `immortalwrt-mediatek-filogic_a73-tplink_tl-7dr7299-v1-squashfs-sysupgrade.itb`。

### 镜像体积

TL‑7DR7299 v1 有 128 MiB NAND，设备树分给 UBI 的空间为 119.5 MiB。两个工作流都将 sysupgrade 文件限制在 **96 MiB**，为 UBI 开销、坏块和可写空间留出余量。构建还会检查闭源无线、Vantage、FastNet 等软件包是否出现在清单里，以及镜像里是否误带 EasyTier。镜像缺失、超限或清单不符时，工作流停止上传。

## 二、刷机前提提醒

* 若当前还是原厂固件，需先按社区免拆教程走完：`官方固件 → debug 固件 → OpenWrt 过渡固件 → 刷入第三方 BL2 与 U-Boot（FIP）`（参考[猫点饭 7DR7299 教程](https://mao.fan/article/582)）。
* 本机已安装第三方 U-Boot。正在使用此系列 6.6 固件时，备份后可从 ImmortalWrt 的「系统 → 备份与升级」上传 `squashfs-sysupgrade.itb`。

## 三、刷机后关键配置要点

1. **2000M 宽带与 8 网口当交换机**
   * 将光猫 2.5G/10G 口接到 7DR7299 的 10G 口或 2.5G 口作 WAN 口拨号；其余网口留在 `br-lan` 网桥即可作为交换机使用。
   * 若有多台高速内网设备（如 NAS），优先接入空闲的 **10G 口**。
2. **USB 挂载与 Docker 目录迁移**
   * 在「系统 → 磁盘管理（DiskMan）」中将外接 USB SSD/高耐用 U 盘格式化为 **`ext4`**，在「挂载点」挂载到 `/mnt/sda1`。
   * 在「Docker → 配置」中将 **Docker 根目录（`data-root`）** 改为 `/mnt/sda1/docker`，保存并重启 `dockerd`，确认镜像不占用板载 128MB 闪存。
   * 后续如需部署 AdGuardHome，直接在 Docker 中以 `host` 网络模式运行即可。
3. **PassWall + SmartDNS 配合**
   * 建议让 SmartDNS 监听独立端口（如 `6053`）专门做国内 DNS 测速解析，在 PassWall 中将国内 DNS 指向 `127.0.0.1#6053`，国外域名交由 PassWall/Xray 分流解析，避免 DNS 环路。
4. **FastNet 内网测速**
   * 在「服务 → FastNet」打开网页，或在局域网客户端访问 `http://路由器IP:3200/webui/`。测速值是客户端到路由器的实际吞吐。对比 Wi‑Fi 信号时，同时记录闭源无线状态里的 RSSI，并使用相同信道、带宽和摆位。

## 四、软件源与 EasyTier 后装

此固件使用 ImmortalWrt 24.10 系列的 `aarch64_cortex-a53` 用户态软件源和 `opkg`。ImmortalWrt 下载站未提供此自编译 `filogic_a73` 的目标专用索引，启动时会清理这两条失效条目。内核模块使用本固件同批产物。Kiddin9 的 24.10 在线索引目前返回 404，FastNet、计划任务和内核参数从固定的 Kiddin9 源码版本随本固件构建。 [ImmortalWrt 软件源](https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/aarch64_cortex-a53/) · [Kiddin9 24.10 索引](https://dl.openwrt.ai/packages-24.10/aarch64_cortex-a53/kiddin9/Packages.gz) · [Kiddin9 插件源码](https://github.com/kiddin9/op-packages/tree/bb5f83e9b993c05a0ba7ebabc4bb4540b4363a52)

EasyTier 预留同批编译的 `kmod-tun`。如需安装，在电脑上解开 EasyTier 官方发布的 `EasyTier-v2.6.4-aarch64_cortex-a53-22.03.7.zip`，通过 LuCI「系统 → 软件包 → 上传软件包」先安装 `easytier_2.6.4_aarch64_cortex-a53.ipk`，再安装 `luci-app-easytier_2.6.4_all.ipk`。两包的架构和声明依赖已核对，安装前先检查可写空间，服务运行效果以真机为准。 [EasyTier v2.6.4 发布页](https://github.com/EasyTier/luci-app-easytier/releases/tag/v2.6.4)
