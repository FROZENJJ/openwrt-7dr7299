#!/usr/bin/env bash
set -euo pipefail

project=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
base=dca94685cd73309b9902b1976aab4b2deccf86eb
board_source=1d585dc90248b09ff61358e504edf2a302d3493a
switch_source=d72da634462e60f63b7391e3bea867bfdae6f4a8
upstream=https://raw.githubusercontent.com/coolsnowwolf/lede
old_board_source=30fbc1d6deba23c0e850185021e9ee42214925eb
old_upstream=https://raw.githubusercontent.com/padavanonly/immortalwrt-mt798x-6.6
soc=target/linux/mediatek
board=tplink,tl-7dr7299-v1

if [[ $(git rev-parse HEAD) != "$base" ]]; then
  echo "Run this script from the pinned 25.12 Wi-Fi 7 source tree ($base)" >&2
  exit 1
fi

fetch_file() {
  local source=$1 revision=$2 path=$3
  mkdir -p "$(dirname "$path")"
  curl -fsSL --retry 3 "$source/$revision/$path" -o "$path.tmp"
  mv "$path.tmp" "$path"
}

# Keep the PHY driver known to the 6.6 profile. The 6.12 tree's RTL8261N
# driver matches a different PHY ID from the board's RTL8261D.
board_dts="$soc/dts/mt7988a-tplink-tl-7dr7299-v1.dts"
fetch_file "$upstream" "$board_source" "$board_dts"
sed -i 's/label = "factory";/label = "Factory";/' "$board_dts"
fetch_file "$upstream" "$board_source" "$soc/patches-6.12/738-net-phy-reset-before-reading-id-when-requested.patch"
fetch_file "$upstream" "$switch_source" package/kernel/rtl837x-dsa/Makefile
fetch_file "$upstream" "$switch_source" package/kernel/rtl837x-dsa/patches/001-guard-optional-mxl862xx-tag-protocol.patch
sed 's/\r$//' "$project/patches/6.12/rtl837x-phylink-get-state.patch" \
  > package/kernel/rtl837x-dsa/patches/002-phylink-get-state.patch
fetch_file "$old_upstream" "$old_board_source" package/kernel/rtl8261d/Makefile

BOARD="$board" SOC="$soc" python3 - <<'PY'
import os
from pathlib import Path

board = os.environ["BOARD"]
soc = Path(os.environ["SOC"])


def insert_before(path, anchor, addition, count=1):
    content = path.read_text()
    if addition in content:
        return
    if content.count(anchor) != count:
        raise SystemExit(f"Expected {count} occurrences of the board insertion point in {path}")
    path.write_text(content.replace(anchor, addition + anchor))


insert_before(
    soc / "image/filogic.mk",
    "define Device/tplink_tl-7dr7230-v1\n",
    r"""define Device/tplink_tl-7dr7299-v1
  DEVICE_MODEL := TL-7DR7299
  DEVICE_VARIANT := v1
  DEVICE_DTS := mt7988a-tplink-tl-7dr7299-v1
  $(call Device/tplink_tl-7dr-common)
  DEVICE_DTS_LOADADDR := 0x47f00000
  KERNEL_LOADADDR := 0x48000000
  DEVICE_PACKAGES += kmod-dsa-rtl837x kmod-phy-rtl8261d kmod-sfp kmod-usb3 mt7988-wo-firmware
  ARTIFACTS :=
endef
TARGET_DEVICES += tplink_tl-7dr7299-v1

""",
)
board_files = soc / "filogic/base-files"
group = "\ttplink,tl-7dr7230-v1|\\\n"
insert_before(
    board_files / "etc/board.d/02_network",
    group,
    f'\t{board})\n\t\tucidef_set_interfaces_lan_wan "lan1 lan2 lan3 lan4 lan5 lan6 sfp" "eth1"\n\t\t;;\n',
)
insert_before(board_files / "lib/upgrade/platform.sh", group, f"\t{board}|\\\n", count=2)
PY

# Avoid setting a shared root password in the public preview image.
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-7dr7299-settings <<'EOF'
#!/bin/sh
uci -q delete network.lan.ipaddr
uci add_list network.lan.ipaddr='10.0.1.1/24'
uci commit network
uci set luci.main.lang='zh_cn'
uci set luci.main.mediaurlbase='/luci-static/vantage'
uci commit luci
exit 0
EOF
chmod 0755 files/etc/uci-defaults/99-7dr7299-settings

# The public 25.12 distribution feeds use APK. This build ships IPK
# for selected user-installed packages and uses no foreign binary feeds.
install -d files/etc/opkg
printf '%s\n' '# Install compatible IPK packages individually.' > files/etc/opkg/distfeeds.conf

# Keep the upstream radio profile options together with the shared app selection.
profile=defconfig/low-mem-512m/mt7988-mt7992-be7200.config
{
  awk '/^# +MTK SDK KMODS +#/{keep=1} keep && /^(CONFIG_|# CONFIG_)/' "$profile"
  sed -e 's/\r$//' -e '/^CONFIG_TARGET_/d' "$project/configs/7dr7299-no-docker.config"
  sed 's/\r$//' "$project/configs/7dr7299-6.12.config"
} | awk '
  /^(CONFIG_|# CONFIG_)/ {
    key = $0
    sub(/^# /, "", key)
    sub(/[= ].*$/, "", key)
    if (!(key in settings)) order[++n] = key
    settings[key] = $0
  }
  END { for (i = 1; i <= n; i++) print settings[order[i]] }
' > .config
