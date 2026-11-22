#!/usr/bin/env bash
set -euo pipefail

LAN_IP="${1:-192.168.6.1}"

# 修改默认管理地址
if [ -f package/base-files/files/bin/config_generate ]; then
  sed -i "s/192\.168\.[0-9]\+\.1/${LAN_IP}/g" package/base-files/files/bin/config_generate
fi

echo "Configured default LAN IP: ${LAN_IP}"
