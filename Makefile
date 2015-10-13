TWEAK_NAME = Couria CouriaUI
BUNDLE_NAME = CouriaPreferences

Couria_FILES = $(wildcard src/Couria/*.m)
Couria_FRAMEWORKS = UIKit
Couria_PRIVATE_FRAMEWORKS = BulletinBoard AppSupport ChatKit
Couria_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

CouriaUI_FILES = $(wildcard src/CouriaUI/*.m)
CouriaUI_FRAMEWORKS = UIKit CoreGraphics AddressBook MobileCoreServices
CouriaUI_PRIVATE_FRAMEWORKS = ChatKit AppSupport IMCore IMFoundation AssetsLibraryServices Search
CouriaUI_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

CouriaPreferences_FILES = $(wildcard src/Preferences/*.m)
CouriaPreferences_RESOURCE_DIRS = res
CouriaPreferences_FRAMEWORKS = UIKit CoreGraphics QuartzCore Social
CouriaPreferences_PRIVATE_FRAMEWORKS = Preferences AppSupport ChatKit
CouriaPreferences_INSTALL_PATH = /Library/PreferenceBundles

Color-Picker-for-iOS_FILES = $(wildcard external/Color-Picker-for-iOS/ColorPicker/*.m)
Color-Picker-for-iOS_CFLAGS = -include external/Color-Picker-for-iOS/Project/Hayashi311ColorPickerSample/Hayashi311ColorPickerSample-Prefix.pch
CouriaPreferences_FILES += $(Color-Picker-for-iOS_FILES)
$(foreach file, $(Color-Picker-for-iOS_FILES), $(eval $(file)_CFLAGS = $(Color-Picker-for-iOS_CFLAGS)))

export TARGET = iphone:clang
export ARCHS = armv7 arm64
export TARGET_IPHONEOS_DEPLOYMENT_VERSION = 8.0
export ADDITIONAL_OBJCFLAGS = -fobjc-arc -fvisibility=hidden
export INSTALL_TARGET_PROCESSES = SpringBoard MessagesNotificationViewService

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)pref="$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences"; mkdir -p "$$pref"; cp CouriaPreferences.plist "$$pref/Couria.plist"$(ECHO_END)
	@(echo "Generating localization resources..."; twine generate-all-string-files loc/strings.txt "$(THEOS_STAGING_DIR)/$(CouriaPreferences_INSTALL_PATH)/CouriaPreferences.bundle" --create-folders --format apple)
