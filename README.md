# Hackfc — FCM INTL JB Tool

Deep hook tool cho **FC Mobile quốc tế** (EA Sports FC Mobile) trên iOS jailbreak.
Menu nổi 12 toggle, cử chỉ 3 ngón, lớp chống soi 4 tầng.

- Bundle ID: `com.ea.ios.fifamobile`
- Binary: `FIFAMobile`
- Version: `2.0.0`

---

## Cấu trúc repo

```
Hackfc/
├── .github/
│   └── workflows/
│       └── build.yml        # GitHub Actions — push main là build deb
├── .gitignore
├── LICENSE                  # MIT
├── Makefile                 # Theos build config
├── README.md
├── Tweak.xm                 # Source chính (menu + hook + anti-check)
├── control                  # Metadata theos (root)
├── fcintl.plist             # Filter bundle gắn vào process game
├── docs/
│   ├── changelog.md
│   ├── install.md
│   └── toggles.md
└── layout/
    └── DEBIAN/
        ├── control          # Metadata deb
        ├── postinst         # chmod + respring sau cài
        ├── postrm           # xoá prefs sau gỡ
        └── prerm            # kill app trước gỡ
```

---

## Sơ đồ kết nối các file

```
         ┌─────────────────────────────────────────────┐
         │               GitHub push (main)            │
         └────────────────────┬────────────────────────┘
                              │
                              ▼
         ┌─────────────────────────────────────────────┐
         │   .github/workflows/build.yml               │
         │   cài Theos → make package → upload .deb    │
         └────────────────────┬────────────────────────┘
                              │
                              ▼
         ┌─────────────────────────────────────────────┐
         │              Makefile                       │
         │  TWEAK_NAME = fcintl                        │
         │  FILES = Tweak.xm                           │
         │  after-install: killall FIFAMobile          │
         └───────┬──────────────────────┬──────────────┘
                 │                      │
                 ▼                      ▼
      ┌────────────────┐     ┌──────────────────────────┐
      │   Tweak.xm     │     │   fcintl.plist           │
      │  (source code) │     │  Filter Bundles =        │
      │                │     │  com.ea.ios.fifamobile   │
      └────────┬───────┘     └────────────┬─────────────┘
               │                          │
               │  theos compile           │  theos copy
               ▼                          ▼
      ┌─────────────────────────────────────────────────┐
      │      layout/Library/MobileSubstrate/...         │
      │      fcintl.dylib + fcintl.plist                │
      └────────────────────┬────────────────────────────┘
                           │  make package
                           ▼
      ┌─────────────────────────────────────────────────┐
      │      packages/com.ollie.fcintl_2.0.0_*.deb      │
      └────────────────────┬────────────────────────────┘
                           │  dpkg -i
                           ▼
      ┌─────────────────────────────────────────────────┐
      │  layout/DEBIAN/postinst → chmod + respring      │
      └────────────────────┬────────────────────────────┘
                           │
                           ▼
      ┌─────────────────────────────────────────────────┐
      │   Vào game → 3 ngón nhấn đôi → menu hiện        │
      └─────────────────────────────────────────────────┘
```

**Chuỗi phụ thuộc file:**

| File | Đọc bởi | Sinh ra |
|---|---|---|
| `Tweak.xm` | `Makefile` | `fcintl.dylib` |
| `fcintl.plist` | Theos package step | `fcintl.plist` trong deb |
| `Makefile` | `build.yml` | deb |
| `control` (root) | Theos | metadata deb |
| `layout/DEBIAN/*` | Theos | script cài/gỡ |
| `layout/DEBIAN/control` | Theos | metadata package |
| `build.yml` | GitHub Actions | artifact deb |

---

## Yêu cầu

- iOS 14.0+ (arm64 / arm64e)
- Jailbreak: **Dopamine**, **palera1n**, hoặc **unc0ver**
- Theos (build local)
- `ldid`, `dpkg` (build deps)
- MobileSubstrate / ElleKit (runtime)

---

## Build local

```bash
export THEOS=~/theos
git clone https://github.com/duchaivcyv-design/Hackfc.git
cd Hackfc
make clean && make package FINALPACKAGE=1
```

Deb nằm ở `packages/com.ollie.fcintl_2.0.0_iphoneos-arm64.deb`.

---

## Build tự động (GitHub Actions)

Push lên nhánh `main` → workflow `build-deb` tự chạy:

1. Cài Theos + deps trên `macos-13`
2. `make package FINALPACKAGE=1`
3. Upload artifact `fcintl-deb`

Tải deb ở tab **Actions** → chọn run mới nhất → mục **Artifacts**.

---

## Cài lên máy

```bash
scp packages/*.deb root@<ip-iphone>:/var/mobile/
ssh root@<ip-iphone>
dpkg -i /var/mobile/com.ollie.fcintl_2.0.0_iphoneos-arm64.deb
killall -9 SpringBoard
```

---

## Dùng

1. Mở **FC Mobile** (bản quốc tế, không phải VN)
2. Chạm **3 ngón tay 2 lần** vào màn hình
3. Menu `olliE intl` hiện ra ở giữa màn hình
4. Kéo từ giữa menu để di chuyển, nút `×` để ẩn
5. Toggle ghi vào prefs riêng của tweak

---

## Bảng toggle

| Tên | Pref key | Mặc định | Chức năng |
|---|---|---|---|
| Enabled | `fci_on` | ON | Bật/tắt toàn bộ hook |
| Coins | `fci_coin` | ON | Override giá trị coin đọc từ prefs game |
| Gems | `fci_gem` | ON | Override giá trị gem |
| XP | `fci_xp` | ON | Override XP |
| Stamina | `fci_stam` | ON | Override stamina |
| Speed | `fci_speed` | OFF | Tốc độ game (chưa nối tick) |
| AutoWin | `fci_auto` | OFF | Tự thắng (chưa nối tick) |
| Unlock All | `fci_unlock` | ON | Mở khoá inventory + roster |
| Anti Check | `fci_anti` | ON | Bật toàn bộ lớp chống soi |
| Hide Frida | `fci_frida` | ON | Chặn dlopen frida + zero KERN_PROC |
| Hide JB | `fci_jb` | ON | Ẩn đường dẫn JB khỏi stat/access |
| Hide Deb | `fci_deb` | ON | Ẩn dấu vết deb |

---

## Lớp chống soi

Tweak chặn 4 tầng bằng `MSHookFunction`:

| Tầng | Hàm hook | Việc làm |
|---|---|---|
| File system | `stat` | Trả `-1` cho path JB |
| File system | `access` | Trả `-1` cho path JB |
| Process | `sysctl` | Zero `KERN_PROC` khi bị query |
| Dynamic | `dlopen` | Chặn load `frida` |

Đường dẫn bị chặn: `/var/jb`, `/Applications/Cydia`, `/Library/MobileSubstrate`, `/usr/sbin/sshd`, `/etc/apt`, `Substrate`, `substitute`, `frida`, `cycript`.

---

## Log debug

```bash
ssh root@<ip-iphone> "idevicesyslog | grep fcintl"
# [fcintl] loaded
```

---

## Gỡ

```bash
dpkg -r com.ollie.fcintl
killall -9 SpringBoard
rm /var/mobile/Library/Preferences/com.ollie.fcintl.plist
```

---

## Bản quyền

MIT — xem `LICENSE`.

---

## Cấu trúc đầy đủ (mở rộng)

<details>
<summary>Bấm để xem cây đầy đủ sau khi build</summary>

```
Hackfc/
├── .git/
├── .github/
│   └── workflows/
│       └── build.yml
├── .gitignore
├── .theos/                  # sinh khi build, ignore
├── LICENSE
├── Makefile
├── README.md
├── Tweak.xm
├── control
├── fcintl.plist
├── docs/
│   ├── changelog.md
│   ├── install.md
│   └── toggles.md
├── layout/
│   ├── DEBIAN/
│   │   ├── control
│   │   ├── postinst
│   │   ├── postrm
│   │   └── prerm
│   └── Library/
│       └── MobileSubstrate/
│           └── DynamicLibraries/
│               ├── fcintl.dylib   # theos copy
│               └── fcintl.plist   # theos copy
├── obj/                     # object files, ignore
└── packages/                # deb output, ignore
    └── com.ollie.fcintl_2.0.0_iphoneos-arm64.deb
```

</details>
