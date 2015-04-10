#import "Headers.h"

static NSUserDefaults *preferences;
static CPDistributedMessagingCenter *messagingCenter;

@interface CouriaPreferencesController : PSListController
@property (retain, nonatomic) NSArray *extensionsSpecifiers;
@property (retain, nonatomic) NSArray *aboutSpecifiers;
@property (retain, nonatomic) NSArray *translationCreditsSpecifiers;
@end

@interface CouriaExtensionPreferencesController : PSListController
@property (retain, nonatomic) NSArray *mainSettingsSpecifiers;
@property (retain, nonatomic) NSArray *themeSettingsSpecifiers;
@end

@implementation CouriaPreferencesController

- (NSArray *)extensionsSpecifiers
{
    if (_extensionsSpecifiers == nil) {
        NSMutableArray *specifiers = [NSMutableArray array];
        NSArray *extensions = [NSKeyedUnarchiver unarchiveObjectWithData:[messagingCenter sendMessageAndReceiveReplyName:ListExtensionsMessage userInfo:nil error:NULL][ExtensionsKey]];
        if (extensions.count > 0) {
            [extensions enumerateObjectsUsingBlock:^(NSDictionary *extension, NSUInteger index, BOOL *stop) {
                CouriaRegisterDefaults(preferences, extension[IdentifierKey]);
                [specifiers addObject:({
                    PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:extension[NameKey] target:self set:NULL get:NULL detail:CouriaExtensionPreferencesController.class cell:PSLinkCell edit:Nil];
                    [specifier setIdentifier:extension[IdentifierKey]];
                    [specifier setProperty:extension[IconKey] forKey:@"iconImage"];
                    specifier;
                })];
            }];
        } else {
            [specifiers addObject:[PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"NO_INSTALLED_ITEMS") target:self set:NULL get:NULL detail:Nil cell:PSStaticTextCell edit:Nil]];
        }
        _extensionsSpecifiers = specifiers;
    }
    return _extensionsSpecifiers;
}

- (NSArray *)aboutSpecifiers
{
    if (_aboutSpecifiers == nil) {
        _aboutSpecifiers = @[({
            PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:@"@QusicS" target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
            [specifier setIdentifier:@"twitter"];
            [specifier setProperty:CouriaImage(@"Twitter") forKey:@"iconImage"];
            specifier->action = @selector(actionForSpecifier:);
            specifier;
        }), ({
            PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:@"Couria" target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
            [specifier setIdentifier:@"github"];
            [specifier setProperty:CouriaImage(@"Github") forKey:@"iconImage"];
            specifier->action = @selector(actionForSpecifier:);
            specifier;
        }), ({
            PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"DONATE") target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
            [specifier setIdentifier:@"donate"];
            [specifier setProperty:CouriaImage(@"PayPal") forKey:@"iconImage"];
            specifier->action = @selector(actionForSpecifier:);
            specifier;
        }), ({
            PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"TRANSLATION_CREDITS") target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
            [specifier setIdentifier:@"translationCredits"];
            [specifier setProperty:CouriaImage(@"Languages") forKey:@"iconImage"];
            specifier->action = @selector(actionForSpecifier:);
            specifier;
        })];
    }
    return _aboutSpecifiers;
}

- (NSArray *)translationCreditsSpecifiers
{
    if (_translationCreditsSpecifiers == nil) {
        NSMutableArray *specifiers = [NSMutableArray array];
        [[self.translationCreditsData.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]enumerateObjectsUsingBlock:^(NSString *language, NSUInteger index, BOOL *stop) {
            [specifiers addObject:({
                PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:language target:self set:NULL get:@selector(getValueForTranslationCreditsSpecifier:) detail:Nil cell:PSTitleValueCell edit:Nil];
                [specifier setIdentifier:language];
                specifier;
            })];
        }];
        _translationCreditsSpecifiers = specifiers;
    }
    return _translationCreditsSpecifiers;
}

- (NSArray *)specifiers
{
    if (_specifiers == nil) {
        NSMutableArray *specifiers = [NSMutableArray array];
        [specifiers addObject:[PSSpecifier groupSpecifierWithName:CouriaLocalizedString(@"EXTENSIONS")]];
        [specifiers addObjectsFromArray:self.extensionsSpecifiers];
        [specifiers addObject:({
            PSSpecifier *specifier = [PSSpecifier groupSpecifierWithName:CouriaLocalizedString(@"ABOUT")];
            [specifier setProperty:@"Couria © 2015 Qusic" forKey:@"footerText"];
            specifier;
        })];
        [specifiers addObjectsFromArray:self.aboutSpecifiers];
        _specifiers = specifiers;
    }
    return _specifiers;
}

- (NSDictionary *)translationCreditsData
{
    return @{@"Dansk": @"Felix E. Drud",
             @"Deutsch": @"Tim Klute",
             @"Español": @"MXNMike",
             @"Français": @"Léo",
             @"Italiano": @"Bruno Di Marco",
             @"Nederlands": @"Alphyraz",
             @"Русский": @"Victor Ryabov",
             @"Svenska": @"Mattias W",
             @"Türkçe": @"aybo101 AppleTurk",
             @"繁體中文": @"Hiraku",
             @"日本語": @"wakinchan",
             @"한국어": @"Jeong Woo Yoon",
             @"العربية": @"Mohamed El Fawal"};
}

- (id)getValueForTranslationCreditsSpecifier:(PSSpecifier *)specifier
{
    return self.translationCreditsData[specifier.identifier];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"😘" style:UIBarButtonItemStylePlain target:self action:@selector(shareAction:)];
}

- (void)actionForSpecifier:(PSSpecifier *)specifier
{
    NSString *identifier = specifier.identifier;
    if ([identifier isEqualToString:@"twitter"]) {
        [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"https://twitter.com/QusicS"]];
    } else if ([identifier isEqualToString:@"github"]) {
        [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"https://github.com/Qusic/Couria"]];
    } else if ([identifier isEqualToString:@"donate"]) {
        [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=PJ93RW7TLKZZ4"]];
    } else if ([identifier isEqualToString:@"translationCredits"]) {
        if (![self containsSpecifier:self.translationCreditsSpecifiers.firstObject]) {
            [self insertContiguousSpecifiers:self.translationCreditsSpecifiers afterSpecifierID:@"translationCredits" animated:YES];
        } else {
            for (PSSpecifier *specifier in self.translationCreditsSpecifiers) {
                [self removeSpecifier:specifier animated:YES];
            }
        }
    }
}

- (void)shareAction:(UIBarButtonItem *)buttonItem
{
    NSString *serviceType = nil;
    if ([[NSLocale preferredLanguages][0]isEqualToString:@"zh-Hans"]) {
        serviceType = SLServiceTypeSinaWeibo;
    } else {
        serviceType = SLServiceTypeTwitter;
    }
    SLComposeViewController *composeSheet = [SLComposeViewController composeViewControllerForServiceType:serviceType];
    [composeSheet setInitialText:CouriaLocalizedString(@"SHARE_TEXT")];
    [self presentViewController:composeSheet animated:YES completion:nil];
}

@end

@implementation CouriaExtensionPreferencesController

- (NSArray *)mainSettingsSpecifiers
{
    if (_mainSettingsSpecifiers == nil) {
        _mainSettingsSpecifiers = @[({
            PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"ENABLED") target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:Nil cell:PSSwitchCell edit:Nil];
            [specifier setIdentifier:[self.specifier.identifier stringByAppendingString:EnabledSetting]];
            specifier;
        }), ({
            PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"AUTHENTICATION_REQUIRED") target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:Nil cell:PSSwitchCell edit:Nil];
            [specifier setIdentifier:[self.specifier.identifier stringByAppendingString:AuthenticationRequiredSetting]];
            specifier;
        })];
    }
    return _mainSettingsSpecifiers;
}

- (NSArray *)themeSettingsSpecifiers
{
    if (_themeSettingsSpecifiers == nil) {
        _themeSettingsSpecifiers = @[({
            PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"BUBBLE_THEME") target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:Nil cell:PSSegmentCell edit:Nil];
            [specifier setIdentifier:[self.specifier.identifier stringByAppendingString:BubbleThemeSetting]];
            [specifier setValues:@[@(CouriaBubbleThemeOriginal), @(CouriaBubbleThemeOutline), @(CouriaBubbleThemeCustom)] titles:@[CouriaLocalizedString(@"BUBBLE_THEME_ORIGINAL"), CouriaLocalizedString(@"BUBBLE_THEME_OUTLINE"), CouriaLocalizedString(@"BUBBLE_THEME_CUSTOM")]];
            specifier;
        }), ({
            PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"MY_BUBBLE_COLOR") target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:Nil cell:PSEditTextCell edit:Nil];
            [specifier setIdentifier:[self.specifier.identifier stringByAppendingString:CustomMyBubbleColorSetting]];
            [specifier setKeyboardType:UIKeyboardTypeASCIICapable autoCaps:UITextAutocapitalizationTypeNone autoCorrection:UITextAutocorrectionTypeNo];
            specifier;
        }), ({
            PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"MY_BUBBLE_TEXT_COLOR") target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:Nil cell:PSEditTextCell edit:Nil];
            [specifier setIdentifier:[self.specifier.identifier stringByAppendingString:CustomMyBubbleTextColorSetting]];
            [specifier setKeyboardType:UIKeyboardTypeASCIICapable autoCaps:UITextAutocapitalizationTypeNone autoCorrection:UITextAutocorrectionTypeNo];
            specifier;
        }), ({
            PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"OTHERS_BUBBLE_COLOR") target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:Nil cell:PSEditTextCell edit:Nil];
            [specifier setIdentifier:[self.specifier.identifier stringByAppendingString:CustomOthersBubbleColorSetting]];
            [specifier setKeyboardType:UIKeyboardTypeASCIICapable autoCaps:UITextAutocapitalizationTypeNone autoCorrection:UITextAutocorrectionTypeNo];
            specifier;
        }), ({
            PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"OTHERS_BUBBLE_TEXT_COLOR") target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:Nil cell:PSEditTextCell edit:Nil];
            [specifier setIdentifier:[self.specifier.identifier stringByAppendingString:CustomOthersBubbleTextColorSetting]];
            [specifier setKeyboardType:UIKeyboardTypeASCIICapable autoCaps:UITextAutocapitalizationTypeNone autoCorrection:UITextAutocorrectionTypeNo];
            specifier;
        })];
    }
    return _themeSettingsSpecifiers;
}

- (NSArray *)specifiers
{
    if (_specifiers == nil) {
        NSMutableArray *specifiers = [NSMutableArray array];
        [specifiers addObject:[PSSpecifier emptyGroupSpecifier]];
        [specifiers addObjectsFromArray:self.mainSettingsSpecifiers];
        [specifiers addObject:({
            PSSpecifier *specifier = [PSSpecifier groupSpecifierWithName:CouriaLocalizedString(@"BUBBLE_THEME")];
            [specifier setProperty:CouriaLocalizedString(@"BUBBLE_THEME_DESCRIPTION") forKey:@"footerText"];
            specifier;
        })];
        [specifiers addObjectsFromArray:self.themeSettingsSpecifiers];
        _specifiers = specifiers;
    }
    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier
{
    return [preferences objectForKey:specifier.identifier];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier
{
    [preferences setObject:value forKey:specifier.identifier];
}

@end

CHConstructor
{
    @autoreleasepool {
        preferences = [[NSUserDefaults alloc]initWithSuiteName:CouriaIdentifier];
        messagingCenter = [CPDistributedMessagingCenter centerNamed:CouriaIdentifier];
    }
}
