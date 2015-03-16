TWEAK_NAME = Couria CouriaUI
BUNDLE_NAME = CouriaPreferences

Couria_FILES = src/Couria.m src/Notifications.m src/Extras.m
Couria_FRAMEWORKS =
Couria_PRIVATE_FRAMEWORKS = BulletinBoard ChatKit
Couria_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

CouriaUI_FILES = src/ViewService.m src/ConversationView.m
CouriaUI_FRAMEWORKS = UIKit
CouriaUI_PRIVATE_FRAMEWORKS = ChatKit
CouriaUI_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

CouriaPreferences_FILES = src/Preferences.m
CouriaPreferences_FRAMEWORKS = UIKit Social
CouriaPreferences_PRIVATE_FRAMEWORKS = Preferences
CouriaPreferences_INSTALL_PATH = /Library/PreferenceBundles

export TARGET = iphone:clang
export ARCHS = armv7 arm64
export TARGET_IPHONEOS_DEPLOYMENT_VERSION = 8.0
export ADDITIONAL_OBJCFLAGS = -fobjc-arc -fvisibility=hidden
export SCHEMA = debug

default: all package install

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
