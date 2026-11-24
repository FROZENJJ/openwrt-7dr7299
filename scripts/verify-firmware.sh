#!/usr/bin/env bash
set -euo pipefail

# 128 MiB NAND contains a 119.5 MiB UBI partition. Reserve space for
# UBI overhead, bad blocks and the writable overlay.
max_bytes=$((96 * 1024 * 1024))
target_dir=bin/targets/mediatek/filogic_a73
device=tplink_tl-7dr7299-v1
image="$target_dir/immortalwrt-mediatek-filogic_a73-$device-squashfs-sysupgrade.itb"
manifest="$target_dir/immortalwrt-mediatek-filogic_a73-$device.manifest"

if [[ ! -s "$image" || ! -s "$manifest" ]]; then
  echo "::error::Missing 7DR7299 v1 sysupgrade image or package manifest"
  exit 1
fi

image_bytes=$(wc -c < "$image")
echo "7DR7299 v1 sysupgrade: $image_bytes bytes (limit $max_bytes bytes)"
if (( image_bytes > max_bytes )); then
  echo "::error::7DR7299 v1 sysupgrade exceeds the 96 MiB release limit"
  exit 1
fi

for package in kmod-mt_wifi7 kmod-mt_hwifi kmod-mt7992 kmod-tun \
  luci-theme-vantage luci-app-vantage luci-i18n-vantage-zh-cn \
  luci-app-fastnet fastnet linkease-app-entry \
  luci-app-crontab-wizard luci-app-sysctl; do
  if ! grep -q "^$package - " "$manifest"; then
    echo "::error::Required package $package is missing from the 7DR7299 v1 image"
    exit 1
  fi
done

if grep -Eq '^(easytier|luci-app-easytier|luci-i18n-easytier)([ -]|$)' "$manifest"; then
  echo "::error::EasyTier must be installed separately"
  exit 1
fi
