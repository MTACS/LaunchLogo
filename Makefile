TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = backboardd Preferences
SYSROOT = $(THEOS)/sdks/iPhoneOS14.2.sdk
ARCHS = arm64 arm64e
DEBUG = 1
FINALPACKAGE = 0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LaunchLogo

LaunchLogo_FILES = LaunchLogo.xm
LaunchLogo_CFLAGS = -fobjc-arc
LaunchLogo_FRAMEWORKS = CoreFoundation
LaunchLogo_PRIVATE_FRAMEWORKS = ProgressUI BackBoardServices

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += launchlogoprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
