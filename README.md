# ZT9101 USB Wi-Fi driver for current Linux kernels

Linux driver for **ZTop ZT9101** 802.11n (2.4 GHz) USB Wi-Fi adapters, patched to build
and run on current kernels (6.13 → 7.2). These adapters are sold under generic names such
as "Wireless 11N USB Adapter"; `lsusb` shows:

```
350b:9101 ZTopInc 802.11n NIC
```

There is no driver for this chip in the mainline kernel. This is ZTop's vendor driver
(via the community forks credited below) with the fixes needed for modern kernels, DKMS
packaging, and an installer.

## Status

| Kernel | Distro | Result |
|---|---|---|
| 7.2.11 | Fedora 44 (Secure Boot on) | builds, loads, WPA2 connect, ~72 Mbit/s link |
| 6.19.10 | Fedora 44 | builds, loads |
| 7.0 | Ubuntu | builds (not run) |

Tested hardware: one adapter, `350b:9101`. The driver's ID table also lists `350b:9106`,
`350b:9086` and `2310:9086` (untested). Kernel 7.1 is untested; the 7.2 API switch is keyed
to `KERNEL_VERSION(7, 2, 0)`.

## Install

1. Build tools and headers for your running kernel:
   - Fedora: `sudo dnf install dkms gcc make kernel-devel-$(uname -r)`
     (Fedora **Server** also needs `sudo dnf install kernel-modules-$(uname -r)` — it ships
     without the Wi-Fi core module `cfg80211`)
   - Debian/Ubuntu: `sudo apt install dkms build-essential linux-headers-$(uname -r)`
2. `sudo ./install.sh`
3. If Secure Boot is on, enroll the DKMS signing key once (next section).
4. Connect: `nmcli --ask dev wifi connect "<SSID>"`

DKMS rebuilds the module automatically for every new kernel. Remove with `sudo ./uninstall.sh`.

## Secure Boot

The module is signed with your machine's DKMS key, which the firmware does not trust until
you enroll it ("Key was rejected by service" from `modprobe`):

```
sudo mokutil --import /var/lib/dkms/mok.pub       # Fedora; Ubuntu: /var/lib/shim-signed/mok/MOK.der
```

Choose a one-time password, reboot, and on the blue **MOK management** screen (10-second
window): any key → *Enroll MOK* → *Continue* → *Yes* → password → *Reboot*.
Nothing is echoed while typing the password. If a gaming keyboard drops keys there, use a
one-character password (`mokutil --generate-hash=1 > h; sudo mokutil --import … --hash-file h`).

## Notes and troubleshooting

- **2.4 GHz only.** The adapter cannot see 5 GHz networks.
- **No MAC address in the chip.** The driver logs `efuse read mac fail, use default addr` and
  makes up `b4:04:18:00:xx:xx` on every load, so DHCP hands out a new IP each boot. Give the
  connection a fixed MAC: `nmcli con mod "<SSID>" wifi.cloned-mac-address stable`.
- **Interface name follows the USB port** (`wlp0s20f0u5`, `wlp0s20f0u7`, …). `nmcli dev wifi
  connect` pins the new connection to the current name; unpin it so any port works:
  `nmcli con mod "<SSID>" connection.interface-name ""`.
- **After reloading `cfg80211`** (e.g. `modprobe -r zt9101_ztopmac_usb` also unloads it),
  restart `wpa_supplicant`; otherwise it falls back to Wireless Extensions and every scan fails
  with `ioctl[SIOCSIWSCAN]: Inappropriate ioctl for device`.
- Debug logging is off (`CONFIG_DEBUG_LEVEL = 3`, errors only). Level 0 prints per packet and
  roughly halves throughput.

## What was changed from upstream

See the commit history. In short:

- `EXTRA_CFLAGS` → `ccflags-y` (support removed in 6.15; include paths were dropped).
- `#elseif` typo → `#elif`; `del_timer()` → `timer_delete()`.
- cfg80211 API: `set_monitor_channel` net_device (6.13), `get_tx_power` link_id (6.14),
  `radio_idx` (6.17), key/station ops on `wireless_dev`, `remain_on_channel` rx_addr,
  `cfg80211_new_sta/del_sta` on `wireless_dev` (7.2).
- No-op the two Wireless Extensions helpers on kernels without WEXT (Fedora).
- `strncpy()` (removed in 7.2) → local helper with the same semantics.
- MAC address via `eth_hw_addr_set()`, fixing a kernel WARN and failed associations after
  NetworkManager changes the MAC.
- DKMS config, installer and uninstaller.

## Credits and license

- ZTop Microelectronics — vendor driver `ZT9101_android_V1.2.1800.20241115` and firmware.
- [yjun123/ZT9101_vendor_linux_driver](https://github.com/yjun123/ZT9101_vendor_linux_driver)
- [sallecta/driver_wifi_ztopinc](https://codeberg.org/sallecta/driver_wifi_ztopinc) — the
  fork this repository starts from (its README is kept as `UPSTREAM-README.md`).
- Kernel 6.13–7.2 fixes and packaging: Radiance Innovation Centers in the Philippines.

GPL-2.0, as upstream (`LICENSE`). The firmware files under `src/fw/` are ZTop's, as
distributed with the upstream driver.
