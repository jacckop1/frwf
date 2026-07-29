# KiraLocket standalone dynamic library
# Built as a plain Objective-C runtime library: no Logos and no Substrate link dependency.

ARCHS ?= arm64
TARGET ?= iphone:clang:latest:14.0
THEOS_PACKAGE_SCHEME ?= rootless

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = KiraLocket

KiraLocket_FILES = \
	KiraEntry.m \
	KiraRuntime.m \
	KiraSettingsViewController.m \
	KiraLockManager.m \
	KiraGalleryCoordinator.m \
	KiraUtilities.m

KiraLocket_FRAMEWORKS = UIKit Foundation LocalAuthentication PhotosUI Photos
KiraLocket_CFLAGS = -fobjc-arc -Wall -Wextra -Werror=return-type
KiraLocket_LDFLAGS = -Wl,-dead_strip
KiraLocket_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

include $(THEOS_MAKE_PATH)/library.mk
