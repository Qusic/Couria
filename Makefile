TWEAK_NAME = Couria CouriaUI
BUNDLE_NAME = CouriaPreferences

Couria_FILES = src/Couria.m src/Service.m src/Extras.m src/Notifications.m src/Gestures.m
Couria_FRAMEWORKS = UIKit
Couria_PRIVATE_FRAMEWORKS = BulletinBoard AppSupport ChatKit
Couria_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

CouriaUI_FILES = src/ViewService.m src/MobileSMSApp.m src/ThirdPartyApp.m src/ConversationView.m src/ContactsView.m src/PhotosView.m src/SearchAgent.m
CouriaUI_FRAMEWORKS = UIKit CoreGraphics AddressBook MobileCoreServices
CouriaUI_PRIVATE_FRAMEWORKS = ChatKit AppSupport IMCore IMFoundation Search
CouriaUI_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

CouriaPreferences_FILES = src/Preferences.m
CouriaPreferences_RESOURCE_DIRS = res
CouriaPreferences_FRAMEWORKS = UIKit Social
CouriaPreferences_PRIVATE_FRAMEWORKS = Preferences ChatKit
CouriaPreferences_INSTALL_PATH = /Library/PreferenceBundles

export TARGET = iphone:clang:8.1
export ARCHS = armv7 arm64
export TARGET_IPHONEOS_DEPLOYMENT_VERSION = 8.0
export ADDITIONAL_OBJCFLAGS = -fobjc-arc -fvisibility=hidden

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)prefs="$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences"; mkdir -p "$$prefs"; cp CouriaPreferences.plist "$$prefs/Couria.plist"$(ECHO_END)

stage::
	@(echo "Generating localization resources..."; loc/generate.sh "$(THEOS_STAGING_DIR)/$(CouriaPreferences_INSTALL_PATH)/CouriaPreferences.bundle")

after-install::
	install.exec "killall -9 SpringBoard"
