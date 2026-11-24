#!/usr/bin/env bash
set -euo pipefail

# 128 MiB NAND contains a 119.5 MiB UBI partition. Reserve space for
# UBI overhead, bad blocks and the writable overlay.
max_bytes=$((96 * 1024 * 1024))
device=tplink_tl-7dr7299-v1
version=${1:-6.6}
required=(kmod-mt_wifi7 kmod-mt_hwifi kmod-mt7992 kmod-tun
  luci-theme-vantage luci-app-vantage luci-i18n-vantage-zh-cn
  luci-app-fastnet fastnet linkease-app-entry
  luci-app-crontab-wizard luci-app-sysctl)
forbidden='easytier|easytier-noweb|luci-app-easytier|luci-i18n-easytier[^ ]*'

case "$version" in
  6.6) subtarget=filogic_a73 ;;
  6.12)
    subtarget=filogic
    required+=(kmod-dsa-rtl837x kmod-phy-rtl8261d kmod-sfp fitblk mtwifi-cfg-ucode wifi-profile opkg)
    forbidden+='|kmod-mt7996e|kmod-mt7992-firmware|kmod-switch-rtl837x|swconfig|apk[^ ]*|dockerd|docker|docker-compose|luci-app-dockerman'
    ;;
  *) echo "Unsupported firmware series: $version" >&2; exit 1 ;;
esac

target_dir="bin/targets/mediatek/$subtarget"
shopt -s nullglob
images=("$target_dir"/*-"$device"-squashfs-sysupgrade.itb)
if (( ${#images[@]} != 1 )); then
  echo "::error::Expected one 7DR7299 v1 sysupgrade image in $target_dir"
  exit 1
fi
image=${images[0]}
manifest="${image%-squashfs-sysupgrade.itb}.manifest"

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

for package in "${required[@]}"; do
  if ! grep -q "^$package - " "$manifest"; then
    echo "::error::Required package $package is missing from the 7DR7299 v1 image"
    exit 1
  fi
done

if grep -E "^($forbidden) - " "$manifest"; then
  echo "::error::Unexpected packages in the $version image"
  exit 1
fi

if [[ "$version" == 6.12 ]]; then
  prefix=${image%-squashfs-sysupgrade.itb}
  [[ -s "$prefix-initramfs-recovery.itb" ]] || {
    echo "::error::Missing 7DR7299 v1 RAM recovery image"
    exit 1
  }
  grep -Eq '^kernel - 6\.12\.' "$manifest" || {
    echo "::error::The package manifest does not identify a 6.12 kernel"
    exit 1
  }
  metadata=$(mktemp)
  trap 'rm -f "$metadata"' EXIT
  staging_dir/host/bin/fwtool -i "$metadata" "$image"
  python3 - "$metadata" <<'PY'
import json
import sys

with open(sys.argv[1]) as data:
    metadata = json.load(data)
assert metadata["supported_devices"] == ["tplink,tl-7dr7299-v1"], metadata
assert metadata["version"]["target"] == "mediatek/filogic", metadata
PY
fi
