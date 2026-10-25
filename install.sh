#!/bin/bash
# Install the ZT9101 USB Wi-Fi driver with DKMS (rebuilt automatically on kernel updates),
# plus its firmware and config. Usage: sudo ./install.sh
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run as root: sudo ./install.sh"; exit 1; }
cd "$(dirname "$0")"
command -v dkms >/dev/null || { echo "Install dkms and your kernel headers first (see README)."; exit 1; }
V=$(sed -n 's/^PACKAGE_VERSION="\(.*\)"/\1/p' src/dkms.conf)
D=/usr/src/zt9101-$V

rm -rf "$D" && cp -r src "$D"
install -d /lib/firmware/zt9101 /etc/zt9101
install -m 644 src/fw/*.bin /lib/firmware/zt9101/
[ -f /etc/zt9101/wifi.cfg ] || sed \
    -e 's#^fw=.*#fw=/lib/firmware/zt9101/ZT9101_fw_c1ab8ba.bin#' \
    -e 's#^fw1=.*#fw1=/lib/firmware/zt9101/ZT9101V30_fw_8546b3a.bin#' \
    src/wifi.cfg > /etc/zt9101/wifi.cfg
echo "options zt9101_ztopmac_usb cfg=/etc/zt9101/wifi.cfg" > /etc/modprobe.d/zt9101.conf
command -v restorecon >/dev/null && restorecon -R /lib/firmware/zt9101 /etc/zt9101 /etc/modprobe.d/zt9101.conf || true

dkms remove "zt9101/$V" --all >/dev/null 2>&1 || true
dkms install "zt9101/$V"

if modprobe zt9101_ztopmac_usb 2>/dev/null; then
    echo "Driver loaded. Plug in the adapter (or replug it) and connect with: nmcli --ask dev wifi connect <SSID>"
elif mokutil --sb-state 2>/dev/null | grep -q 'SecureBoot enabled'; then
    echo "Secure Boot rejected the module: enroll the DKMS signing key once (see README, 'Secure Boot')."
else
    echo "modprobe failed - check: dmesg | tail"
fi
