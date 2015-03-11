TWEAK_NAME = Couria MessagesExtension
BUNDLE_NAME = CouriaPreferences

Couria_FILES = 
Couria_FRAMEWORKS = UIKit CoreGraphics QuartzCore MobileCoreServices MediaPlayer AudioToolbox
Couria_PRIVATE_FRAMEWORKS = AppSupport
Couria_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

MessagesExtension_FILES = src/MessagesExtension.mm
MessagesExtension_FRAMEWORKS = UIKit
MessagesExtension_PRIVATE_FRAMEWORKS = ChatKit IMCore Search
MessagesExtension_LIBRARIES = sqlite3
MessagesExtension_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

CouriaPreferences_FILES = 
CouriaPreferences_FRAMEWORKS = UIKit Social
CouriaPreferences_PRIVATE_FRAMEWORKS = Preferences AppSupport
CouriaPreferences_INSTALL_PATH = /Library/PreferenceBundles

export TARGET = iphone:clang
export ARCHS = armv7 arm64
export TARGET_IPHONEOS_DEPLOYMENT_VERSION = 8.0
export ADDITIONAL_OBJCFLAGS = -fobjc-arc -fvisibility=hidden

default: all package install

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
