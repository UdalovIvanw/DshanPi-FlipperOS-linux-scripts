#!/usr/bin/env bash
# Копирует прошивку Realtek rtw8852c (Wi-Fi RTL8852CE) в профили Flipper OS на SD-карте.
# Запуск: sudo ./fix-wifi-firmware.sh /dev/sdX3     (раздел root, btrfs)
set -euo pipefail
DEV="${1:?укажите раздел root на SD, например /dev/sda3}"
SRC=/usr/lib/firmware/rtw89
[ "$(id -u)" -eq 0 ] || { echo "запустите через sudo"; exit 1; }
ls "$SRC"/rtw8852c_fw* >/dev/null 2>&1 || { echo "нет $SRC/rtw8852c_fw* (установите linux-firmware-realtek)"; exit 1; }

TMP=$(mktemp -d); MNT=$(mktemp -d)
trap 'umount "$MNT" 2>/dev/null || true; rm -rf "$TMP" "$MNT"' EXIT

for f in "$SRC"/rtw8852c_fw*; do
  case "$f" in
    *.zst) zstd -dfq "$f" -o "$TMP/$(basename "${f%.zst}")" ;;
    *)     cp "$f" "$TMP/" ;;
  esac
done
ls -l "$TMP"

mount "$DEV" "$MNT"
for p in "$MNT"/@*; do
  [ -d "$p/usr/lib" ] || continue
  mkdir -p "$p/usr/lib/firmware/rtw89"
  cp "$TMP"/* "$p/usr/lib/firmware/rtw89/"
  echo "прошивка скопирована в $(basename "$p")"
done
sync
echo "готово"
