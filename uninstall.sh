#!/bin/bash
# Remove the ZT9101 driver, firmware and config. Usage: sudo ./uninstall.sh
set -uo pipefail
[ "$(id -u)" = 0 ] || { echo "Run as root: sudo ./uninstall.sh"; exit 1; }
V=$(sed -n 's/^PACKAGE_VERSION="\(.*\)"/\1/p' "$(dirname "$0")/src/dkms.conf")
modprobe -r zt9101_ztopmac_usb 2>/dev/null
dkms remove "zt9101/$V" --all 2>/dev/null
rm -rf "/usr/src/zt9101-$V" /lib/firmware/zt9101 /etc/zt9101 /etc/modprobe.d/zt9101.conf
systemctl disable --now zt9101-watchdog.timer 2>/dev/null
rm -f /usr/local/sbin/zt9101-watchdog /etc/systemd/system/zt9101-watchdog.{service,timer} /etc/NetworkManager/conf.d/90-zt9101.conf
systemctl daemon-reload
echo "Removed."
