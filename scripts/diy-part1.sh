#!/usr/bin/env bash
set -euo pipefail

# 添加 PassWall 官方 feeds（packages 放前面优先索引）
sed -i '/passwall/d' feeds.conf.default
echo 'src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main' >> feeds.conf.default
echo 'src-git passwall https://github.com/Openwrt-Passwall/openwrt-passwall.git;main' >> feeds.conf.default

# 仅导入需要的包，避免覆盖 24.10 的基础库及 LuCI feed。
import_packages() (
  local repo="$1" revision="$2"
  shift 2
  local archive package_name
  local members=()
  archive="$(mktemp)"
  trap 'rm -f "$archive"' EXIT

  curl -fsSL --retry 3 "https://codeload.github.com/$repo/tar.gz/$revision" -o "$archive"
  for package_name in "$@"; do
    members+=("${repo##*/}-$revision/$package_name")
  done
  tar -xzf "$archive" --strip-components=1 -C package "${members[@]}"
)

import_packages anothaDev/luci-theme-vantage a7ff63b715bca51effb5ab2d488dfff6cff1b16a \
  luci-theme-vantage luci-app-vantage
import_packages kiddin9/op-packages bb5f83e9b993c05a0ba7ebabc4bb4540b4363a52 \
  fastnet luci-app-fastnet luci-lib-linkeaseauth linkease-app-entry \
  luci-app-crontab-wizard luci-app-sysctl

# 校验 FastNet 和网关的上游预编译运行时。
sed -i 's/^PKG_HASH:=skip$/PKG_HASH:=7201986d9b01b83ba6eb3fd0080916caf31a01fb26a0fcc216c53a6e6297b8ba/' \
  package/fastnet/Makefile
sed -i '/^LINKEASE_RUNTIME_ARCH:=arm64$/{n;s/^PKG_HASH:=skip$/PKG_HASH:=ef4a48e999339bdd6c2a802ce1c1fbcb885ad28c7ed63315a21d4034d1e66a2c/;}' \
  package/linkease-app-entry/Makefile
