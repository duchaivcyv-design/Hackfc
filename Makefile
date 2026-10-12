ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = fcintl
fcintl_FILES = Tweak.xm
fcintl_CFLAGS = -fobjc-arc
fcintl_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 FIFAMobile 2>/dev/null || true"
