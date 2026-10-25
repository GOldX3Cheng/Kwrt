#!/bin/bash

shopt -s extglob

SHELL_FOLDER=$(dirname $(readlink -f "$0"))

rm -rf package/boot package/firmware/ipq-wifi target/linux/generic target/linux/qualcommax package/firmware/ath11k-firmware package/kernel/mac80211 package/kernel/nat46

git_clone_path 25.12-nss https://github.com/LiBwrt/openwrt-6.x target/linux/generic target/linux/qualcommax package/boot package/firmware/ipq-wifi package/firmware/ath11k-firmware package/kernel/mac80211 package/kernel/nat46

wget -N https://github.com/LiBwrt/LibWrt/raw/refs/heads/25.12-nss/include/image-commands.mk -P include/
wget -N https://github.com/LiBwrt/LibWrt/raw/refs/heads/25.12-nss/config/Config-ipq.in -P config/
wget -N https://github.com/LiBwrt/LibWrt/raw/refs/heads/25.12-nss/Config.in -P ./

rm -rf feeds/kiddin9/shortcut-fe

git clone https://github.com/qosmio/nss-packages.git package/nss-packages
git clone https://github.com/qosmio/sqm-scripts-nss.git package/sqm-scripts-nss

sed -i "/ECM_INTERFACE_RAWIP_ENABLE/d"  package/nss-packages/qca-nss-ecm/Makefile
rm -rf package/nss-packages/nss-userspace-oss

sed -i "s/luci uboot-envtools wpad-openssl/luci uboot-envtools wpad-mbedtls/" target/linux/qualcommax/Makefile

# ==================================================
# 追加：luci-app-wolultra（Kwrt 官方源自带没有，直接放进 package/）
# ==================================================
rm -rf package/luci-app-wolultra
tmpdir="$(mktemp -d)"
git clone --depth 1 https://github.com/VIKINGYFY/packages.git "$tmpdir" || exit 1
cp -rf "$tmpdir/luci-app-wolultra" package/
rm -rf "$tmpdir"
[ -f package/luci-app-wolultra/Makefile ] && echo "[OK] luci-app-wolultra 已就位" || { echo "[FAIL] luci-app-wolultra 缺失"; exit 1; }

# ==================================================
# 修 op-packages 历史遗留：luci-app-adguardhome 的 00_makefile.patch
# 其改动（include $(TOPDIR)/feeds/luci/luci.mk、LUCI_DEPENDS）已在 Makefile 内，
# 而 LuCI 包构建目录里没有 Makefile，补丁必然 "No file to patch" 导致编译中断
# ==================================================
if [ -f feeds/kiddin9/luci-app-adguardhome/patches/00_makefile.patch ]; then
  rm -f feeds/kiddin9/luci-app-adguardhome/patches/00_makefile.patch
  echo "[OK] 已移除 luci-app-adguardhome 的失效补丁"
fi

# ==================================================
# 精简 Kwrt 自带 DEFAULT_PACKAGES：去掉 upnp / 风扇 / wifi 历史
# （与当前 immortalwrt 那版保持一致；advancedplus/quickstart 等 UI 外壳保留）
# ==================================================
sed -i 's/ luci-app-upnp//' include/target.mk
sed -i 's/ luci-app-fan//' include/target.mk
sed -i 's/ luci-app-wifihistory//' include/target.mk
grep -n "DEFAULT_PACKAGES:=" include/target.mk
