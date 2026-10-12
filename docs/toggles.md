# Toggles

Mỗi toggle ghi vào `NSUserDefaults` của tweak, prefix `fci_`.

## Enabled
OFF → tweak nằm im, game chạy nguyên gốc.

## Coins / Gems / XP / Stamina
Override giá trị đọc từ `NSUserDefaults` của game.

## Speed / AutoWin
Bật đường chạy riêng trong game loop.

## Unlock All
Mở khoá inventory + roster.

## Anti Check
Bật toàn bộ lớp chống soi (`stat`, `access`, `sysctl`, `dlopen`).

## Hide Frida / Hide JB / Hide Deb
Tắt riêng từng tầng khi cần debug.

## Reset

```bash
rm /var/mobile/Library/Preferences/com.ollie.fcintl.plist
killall -9 SpringBoard
```
