# Install

## 1. Build

```bash
export THEOS=~/theos
cd Hackfc
make clean && make package FINALPACKAGE=1
```

Deb ở `packages/com.ollie.fcintl_2.0.0_iphoneos-arm64.deb`.

## 2. Copy sang máy

```bash
scp packages/*.deb root@192.168.1.50:/var/mobile/
```

## 3. Cài

```bash
ssh root@192.168.1.50
dpkg -i /var/mobile/com.ollie.fcintl_2.0.0_iphoneos-arm64.deb
killall -9 SpringBoard
```

## 4. Kiểm tra

```bash
ls -l /Library/MobileSubstrate/DynamicLibraries/
# fcintl.dylib
# fcintl.plist
```

## 5. Log

```bash
ssh root@192.168.1.50 "idevicesyslog | grep fcintl"
```

## 6. Gỡ

```bash
dpkg -r com.ollie.fcintl
killall -9 SpringBoard
```
