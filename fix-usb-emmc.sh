#!/usr/bin/env bash
# Для DshanPi A1 + Flipper OS (ядро 7.4.0-rc1):
#  - отключает usb@23000000 (паника xhci), оставляет usb@23400000;
#  - убирает supports-cqe у eMMC (/soc/mmc@2a330000): иначе ошибки 'mmc0: running CQE recovery';
#  - убирает usbcore.nousb=1 из записей 7.4.0 и добавляет clk_ignore_unused pd_ignore_unused.
# Запуск: sudo ./fix-usb-dtb.sh /dev/sdX3     (раздел root, btrfs)
set -euo pipefail
DEV="${1:?укажите раздел root на SD, например /dev/sda3}"
[ "$(id -u)" -eq 0 ] || { echo "запустите через sudo"; exit 1; }
command -v fdtput >/dev/null || { echo "нужен пакет dtc (fdtput)"; exit 1; }

MNT=$(mktemp -d)
trap 'umount "$MNT" 2>/dev/null || true; rmdir "$MNT" 2>/dev/null || true' EXIT
mount "$DEV" "$MNT"

for dtb in "$MNT"/@*/usr/lib/linux-image-7.4.0*/rockchip/rk3576-100ask-dshanpi-a1.dtb; do
  [ -f "$dtb" ] || continue
  [ -f "$dtb.orig" ] || cp "$dtb" "$dtb.orig"           # резервная копия один раз
  fdtput -t s "$dtb" /soc/usb@23000000 status disabled
  fdtput -t s "$dtb" /soc/usb@23400000 status okay
  if fdtget -p "$dtb" /soc/mmc@2a330000 2>/dev/null | grep -qx supports-cqe; then
    fdtput -d "$dtb" /soc/mmc@2a330000 supports-cqe
    echo "  eMMC: supports-cqe удалён"
  fi
  echo "DTB исправлен: ${dtb#"$MNT"/}"
done

for conf in "$MNT"/boot/loader/entries/*7.4.0*.conf; do
  [ -f "$conf" ] || continue
  sed -i -e 's/ usbcore\.nousb=1//' \
         -e '/^options/{/clk_ignore_unused/!s/$/ clk_ignore_unused pd_ignore_unused/}' "$conf"
  grep -H '^options' "$conf"
done
sync
echo "готово"
