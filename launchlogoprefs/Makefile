TARGET := iphone:clang:latest:14.0
SYSROOT = $(THEOS)/sdks/iPhoneOS14.2.sdk

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = LaunchLogoPrefs

LaunchLogoPrefs_FILES = LLPRootListController.m
LaunchLogoPrefs_FRAMEWORKS = UIKit
LaunchLogoPrefs_PRIVATE_FRAMEWORKS = Preferences
LaunchLogoPrefs_INSTALL_PATH = /Library/PreferenceBundles
LaunchLogoPrefs_CFLAGS = -fobjc-arc -Wdeprecated-declarations -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/bundle.mk
