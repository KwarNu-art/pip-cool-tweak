# Use latest installed iPhoneOS SDK on the machine/CI runner
TARGET := iphone:clang:latest:12.0
ARCHS := arm64
INSTALL_TARGET_PROCESSES := SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := Pip

Pip_FILES := Sources/Tweak.xm Sources/PipHUD.m Sources/PipStats.m Sources/PipPrefs.m
Pip_CFLAGS := -fobjc-arc -Wno-unused-variable -Wno-deprecated-declarations
Pip_FRAMEWORKS := UIKit Foundation QuartzCore CoreGraphics
Pip_PRIVATE_FRAMEWORKS :=

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard || true"
