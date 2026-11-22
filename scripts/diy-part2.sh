#!/usr/bin/env bash
set -euo pipefail

LAN_IP="${1:-10.0.1.1}"

# 1. 修改默认后台 IP 为 10.0.1.1
if [ -f package/base-files/files/bin/config_generate ]; then
  sed -i "s/192\.168\.[0-9]\+\.1/${LAN_IP}/g" package/base-files/files/bin/config_generate
fi

# 2. 写入首次开机自动配置脚本（主机名、DHCP、主题、时区、初始密码）
mkdir -p files/etc/uci-defaults
cat << 'EOF' > files/etc/uci-defaults/99-custom-settings
#!/bin/sh

uci set system.@system[0].hostname='DIOsOpenwrt'
uci set system.@system[0].zonename='Asia/Shanghai'
uci set system.@system[0].timezone='CST-8'
uci commit system

uci set dhcp.lan.start='20'
uci set dhcp.lan.limit='200'
uci commit dhcp

uci set luci.main.lang='zh_cn'
if [ -d /www/luci-static/argon ]; then
  uci set luci.main.mediaurlbase='/luci-static/argon'
fi
uci commit luci

(echo "password"; sleep 1; echo "password") | passwd root >/dev/null 2>&1 || true

exit 0
EOF
chmod +x files/etc/uci-defaults/99-custom-settings

echo "Configured default LAN IP: ${LAN_IP}, Hostname: DIOsOpenwrt, DHCP start: 20"
if [ -f package/base-files/files/bin/config_generate ]; then
  sed -i "s/192\.168\.[0-9]\+\.1/${LAN_IP}/g" package/base-files/files/bin/config_generate
fi

echo "Configured default LAN IP: ${LAN_IP}"
