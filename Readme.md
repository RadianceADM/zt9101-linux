# About

Forked from https://github.com/yjun123/ZT9101_vendor_linux_driver/

Based on version ZT9101_android_V1.2.1800.20241115

350b:9101 ZTopInc 802.11n NIC WiFi Linux driver

https://codeberg.org/sallecta/driver_wifi_ztopinc


# Build

```
make
```

# Install

```
sudo insmod ./zt9101_ztopmac_usb.ko cfg=./wifi.cfg
```

# Uninstall

```
sudo rmmod zt9101_ztopmac_usb.ko
```


