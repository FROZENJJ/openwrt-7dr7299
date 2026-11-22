# TP-Link TL-7DR7299 (v1) 闭源 Wi-Fi 固件云编译包

本配置包基于 [padavanonly/immortalwrt-mt798x-6.6](https://github.com/padavanonly/immortalwrt-mt798x-6.6) 的 `mt798x-mt799x-6.6-mtwifi` 分支，专为 **TP-Link TL-7DR7299 (v1)** 定制，适合通过 **GitHub Actions** 免费一键云编译。

## 内置功能一览

* **无线与加速**：MediaTek 闭源 `mtwifi` 驱动 + TurboACC（HNAT/WED 硬件加速与全锥形 NAT）
* **基础网络**：PPPoE 拨号（适配 2000M 宽带）、完整 IPv6、UPnP
* **核心插件**：
  * **阿里云 DDNS**：`ddns-go` (`luci-app-ddns-go`)
  * **异地组网**：[EasyTier](https://github.com/EasyTier/luci-app-easytier) + 同批编译的 `kmod-tun`
  * **科学上网**：[PassWall](https://github.com/Openwrt-Passwall/openwrt-passwall)（仅保留 **Xray** 核心，精简体积）+ `dnsmasq-full` + `kmod-nft-tproxy`
  * **DNS 加速**：[SmartDNS](https://github.com/pymumu/smartdns)
* **USB 3.0 与 Docker**：USB 3.0 / UAS 驱动、`ext4` / `exFAT` / `NTFS3`、磁盘管理（`DiskMan`）、局域网共享（`Samba4`）、`dockerd` + `docker-compose` + `DockerMan`

## 一、GitHub Actions 云编译步骤

1. 在 GitHub 上新建一个**空白仓库**（公开或私有均可，例如 `openwrt-7dr7299`）。
2. 解压本压缩包，将里面的 `.github/`、`configs/`、`scripts/` 和 `README.md` 推送（或通过网页 Upload files）到仓库根目录。
   * 注意：若使用网页上传，`.github/workflows/build-7dr7299.yml` 需要在网页手动建目录或直接用 `git push` 推送（推荐用 `git push`，不会漏掉隐藏目录 `.github`）。
3. 进入仓库 **Settings → Actions → General → Workflow permissions**，勾选 **Read and write permissions** 并保存（用于自动发布 Release）。
4. 进入仓库 **Actions** 页面，点击左侧 **Build TP-Link 7DR7299 Closed-Source WiFi ImmortalWrt** → 点击右侧 **Run workflow**。
   * 可按需修改默认后台 IP（默认 `192.168.6.1`）以及是否启用 Docker（默认勾选）。
5. 等待约 45～70 分钟编译完成后，在仓库右侧 **Releases** 页面下载 `immortalwrt-mediatek-filogic_a73-tplink_tl-7dr7299-v1-squashfs-sysupgrade.itb`。

## 二、刷机前提提醒

* 若当前还是原厂固件，需先按社区免拆教程走完：`官方固件 → debug 固件 → OpenWrt 过渡固件 → 刷入第三方 BL2 与 U-Boot（FIP）`（参考[猫点饭 7DR7299 教程](https://mao.fan/article/582)）。
* 已有第三方 U-Boot 后，在 U-Boot 恢复界面或现有 ImmortalWrt 的「系统 → 备份与升级」中上传 `.itb` 固件（首次跨分支建议不保留配置）。

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
4. **若编译时报闪存超限**
   * 128MB 闪存在同时打入 Docker + Xray + EasyTier 时空间较紧凑；若日志提示镜像超出分区大小，可在运行 workflow 时先取消勾选 `include_docker` 编译基础版，或在 `configs/7dr7299-custom.config` 中去掉 `CONFIG_PACKAGE_docker-compose=y` 再重跑。
