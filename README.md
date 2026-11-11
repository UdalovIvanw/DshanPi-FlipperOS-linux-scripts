# DshanPi-FlipperOS-linux-scripts

Helper scripts for running **Flipper OS** (Debian, kernel 7.4.0-rc1) on the **100ASK DshanPi A1** (Rockchip RK3576).

Both scripts are run on a host Linux machine against the **root partition of the SD card** (Btrfs with `@*` subvolumes / profiles). They do not need to run on the board itself.

## Scripts

| Script | Purpose |
|--------|---------|
| `fix-usb-emmc.sh` | Fixes the xhci kernel panic and eMMC CQE errors by patching the board DTB and the BLS boot entries. |
| `fix-wifi-firmware.sh` | Installs the Realtek RTL8852CE (`rtw8852c`) Wi-Fi firmware into every Flipper OS profile. |

## Requirements

- A Linux host with `sudo`
- The Flipper OS root partition (Btrfs) on an SD card, e.g. `/dev/sdX3`
- For `fix-usb-emmc.sh`: `dtc` (provides `fdtput` / `fdtget`)
- For `fix-wifi-firmware.sh`: `zstd`, and the Realtek firmware installed on the host in `/usr/lib/firmware/rtw89/` (package `linux-firmware-realtek`)

> Double-check the device name before running anything. The scripts mount the partition you pass and modify files on it.

## fix-usb-emmc.sh

```bash
sudo ./fix-usb-emmc.sh /dev/sdX3
```

What it does, for every profile (`@*`) containing a 7.4.0 kernel:

- Disables `usb@23000000` (avoids the xhci kernel panic) and keeps `usb@23400000` enabled.
- Removes `supports-cqe` from the eMMC node `/soc/mmc@2a330000`, which fixes `mmc0: running CQE recovery` errors.
- Patches `rk3576-100ask-dshanpi-a1.dtb`; the original is saved once as `*.dtb.orig`.
- In `/boot/loader/entries/*7.4.0*.conf` it removes `usbcore.nousb=1` and adds `clk_ignore_unused pd_ignore_unused` to the kernel options.

To revert, copy `rk3576-100ask-dshanpi-a1.dtb.orig` back over the `.dtb`.

## fix-wifi-firmware.sh

```bash
sudo ./fix-wifi-firmware.sh /dev/sdX3
```

What it does:

- Takes `rtw8852c_fw*` from the host's `/usr/lib/firmware/rtw89/` (decompressing `.zst` files if needed).
- Copies the firmware into `/usr/lib/firmware/rtw89/` of every `@*` profile on the SD card.

After booting, the RTL8852CE adapter should come up as `wlan0`.

## Tested on

- Board: 100ASK DshanPi A1 (RK3576)
- Kernel: 7.4.0-rc1
- OS: Flipper OS (Debian)
- Bootloader: custom U-Boot (BLS boot entries)

## License
MIT license
