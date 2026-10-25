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
# luci-app-adguardhome 改用 luci 源版本
# 原因：kiddin9 源那份自带 13 个历史补丁（00_makefile 因构建目录无 Makefile、
# 01_init 因 init 脚本已变动而必然打不上），而 luci 源里的官方版本无补丁、依赖正确
if [ -d feeds/luci/applications/luci-app-adguardhome ]; then
  rm -rf package/feeds/kiddin9/luci-app-adguardhome
  rm -rf feeds/kiddin9/luci-app-adguardhome
  ./scripts/feeds install -f -p luci luci-app-adguardhome
  echo "[OK] luci-app-adguardhome 已切换为 luci 源版本（无历史补丁）"
  ls -l package/feeds/luci/luci-app-adguardhome || true
fi

# 精简 Kwrt 自带 DEFAULT_PACKAGES：去掉 upnp / 风扇 / wifi 历史
# （与当前 immortalwrt 那版保持一致；advancedplus/quickstart 等 UI 外壳保留）
# ==================================================
sed -i 's/ luci-app-upnp//' include/target.mk
sed -i 's/ luci-app-fan//' include/target.mk
sed -i 's/ luci-app-wifihistory//' include/target.mk
grep -n "DEFAULT_PACKAGES:=" include/target.mk
