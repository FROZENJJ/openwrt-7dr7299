#!/usr/bin/env bash
set -euo pipefail

# 添加 PassWall 官方 feeds（packages 放前面优先索引）
sed -i '/passwall/d' feeds.conf.default
echo 'src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main' >> feeds.conf.default
echo 'src-git passwall https://github.com/Openwrt-Passwall/openwrt-passwall.git;main' >> feeds.conf.default

# 拉取 EasyTier 官方 OpenWrt LuCI 仓库
rm -rf package/luci-app-easytier
git clone --depth=1 https://github.com/EasyTier/luci-app-easytier.git package/luci-app-easytier
