TWEAK_NAME = Couria MessagesExtension
BUNDLE_NAME = CouriaPreferences

Couria_FILES = src/Couria.mm src/Couria-Hooks.mm src/Couria-Localization.mm src/CouriaController.m src/CouriaMessagesView.m src/CouriaMessageView.m src/CouriaMessageCell.m src/CouriaContactsView.m src/CouriaFieldView.m src/CouriaImageView.m src/CouriaImageViewerController.m src/CouriaMoviePlayerController.m src/CouriaMessage.m src/CouriaTheme.m src/CouriaSoundEffect.m src/CouriaExtras.m src/NSString+Couria.m src/UIScreen+Couria.m src/UIView+Couria.m src/UIImage+Couria.m src/UIColor+Couria.m src/CALayer+Couria.m external/JTSTextView/JTSTextView.m
Couria_FRAMEWORKS = UIKit CoreGraphics QuartzCore MobileCoreServices MediaPlayer AudioToolbox
Couria_PRIVATE_FRAMEWORKS = AppSupport
Couria_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

MessagesExtension_FILES = src/MessagesExtension.mm
MessagesExtension_FRAMEWORKS = UIKit
MessagesExtension_PRIVATE_FRAMEWORKS = ChatKit IMCore Search
MessagesExtension_LIBRARIES = sqlite3
MessagesExtension_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

CouriaPreferences_FILES = src/CouriaPreferences.mm src/CouriaPreferences-Localization.mm src/CouriaPreferencesController.m src/CouriaExtensionPreferencesController.m src/CouriaCustomPreferencesController.m
CouriaPreferences_FRAMEWORKS = UIKit Social
CouriaPreferences_PRIVATE_FRAMEWORKS = Preferences AppSupport
CouriaPreferences_INSTALL_PATH = /Library/PreferenceBundles

export TARGET=iphone:clang
export ARCHS = armv7 armv7s arm64
export TARGET_IPHONEOS_DEPLOYMENT_VERSION = 6.0
export ADDITIONAL_OBJCFLAGS = -fobjc-arc -fvisibility=hidden

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
