#import "CouriaExtensionPreferencesController.h"
#import "CouriaCustomPreferencesController.h"

@implementation CouriaExtensionPreferencesController

- (NSArray *)specifiers
{
    if (_specifiers == nil) {
        NSMutableArray *specifiers = [NSMutableArray array];
        PSSpecifier *enabled = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"ENABLED")
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:Nil
                                                                cell:PSSwitchCell
                                                                edit:Nil];
        [enabled setIdentifier:EnabledKey];
        [enabled setProperty:@(YES) forKey:@"enabled"];
        PSSpecifier *disableOnLockScreen = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"DISABLE_ON_LOCK_SCREEN")
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:Nil
                                                                cell:PSSwitchCell
                                                                edit:Nil];
        [disableOnLockScreen setIdentifier:DisableOnLockScreenKey];
        [disableOnLockScreen setProperty:@(YES) forKey:@"enabled"];
        PSSpecifier *theme = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"THEME")
                                                            target:self
                                                               set:@selector(setValue:forSpecifier:)
                                                               get:@selector(getValueForSpecifier:)
                                                            detail:PSListItemsController.class
                                                              cell:PSLinkListCell
                                                              edit:Nil];
        [theme setIdentifier:ThemeKey];
        NSArray *themeIdentifiers = CouriaPreferencesGetThemes();
        NSMutableArray *themeNames = [NSMutableArray array];
        for (NSString *themeIdentifier in themeIdentifiers) {
            [themeNames addObject:CouriaPreferencesGetThemeDisplayName(themeIdentifier)];
        }
        [theme setValues:themeIdentifiers titles:themeNames shortTitles:themeNames];
        PSSpecifier *textSize = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"TEXT_SIZE")
                                                               target:self
                                                                  set:@selector(setValue:forSpecifier:)
                                                                  get:@selector(getValueForSpecifier:)
                                                               detail:PSListItemsController.class
                                                                 cell:PSLinkListCell
                                                                 edit:Nil];
        [textSize setIdentifier:TextSizeKey];
        [textSize setValues:@[@(14), @(16), @(18), @(20), @(22), @(24)] titles:@[@"14 pt", @"16 pt", @"18 pt", @"20 pt", @"22 pt", @"24 pt"] shortTitles:@[@"14 pt", @"16 pt", @"18 pt", @"20 pt", @"22 pt", @"24 pt"]];
        PSSpecifier *passcode = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"PASSCODE")
                                                               target:self
                                                                  set:@selector(setValue:forSpecifier:)
                                                                  get:@selector(getValueForSpecifier:)
                                                               detail:Nil
                                                                 cell:PSSecureEditTextCell
                                                                 edit:Nil];
        [passcode setIdentifier:PasscodeKey];
        [passcode setKeyboardType:UIKeyboardTypeNumberPad autoCaps:UITextAutocapitalizationTypeNone autoCorrection:UITextAutocorrectionTypeNo];
        PSSpecifier *passcodeWhenLocked = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"REQUIRE_WHEN_LOCKED")
                                                                         target:self
                                                                            set:@selector(setValue:forSpecifier:)
                                                                            get:@selector(getValueForSpecifier:)
                                                                         detail:Nil
                                                                           cell:PSSwitchCell
                                                                           edit:Nil];
        [passcodeWhenLocked setIdentifier:RequirePasscodeWhenLockedKey];
        [passcodeWhenLocked setProperty:@(YES) forKey:@"enabled"];
        PSSpecifier *passcodeWhenUnlocked = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"REQUIRE_WHEN_UNLOCKED")
                                                                           target:self
                                                                              set:@selector(setValue:forSpecifier:)
                                                                              get:@selector(getValueForSpecifier:)
                                                                           detail:Nil
                                                                             cell:PSSwitchCell
                                                                             edit:Nil];
        [passcodeWhenUnlocked setIdentifier:RequirePasscodeWhenUnlockedKey];
        [passcodeWhenUnlocked setProperty:@(YES) forKey:@"enabled"];
        [specifiers addObjectsFromArray:@[[PSSpecifier emptyGroupSpecifier], enabled, disableOnLockScreen,
                                          [PSSpecifier emptyGroupSpecifier], theme, textSize,
                                          [PSSpecifier emptyGroupSpecifier], passcode, passcodeWhenLocked, passcodeWhenUnlocked]];
        NSString *plistPath = [NSString stringWithFormat:@"%@/%@/%@", ExtensionsDirectoryPath, self.specifier.identifier, @"Extension.plist"];
        if ([[NSFileManager defaultManager]fileExistsAtPath:plistPath]) {
            PSSpecifier *custom = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"OTHER_PREFERENCES")
                                                                 target:self set:NULL get:NULL
                                                                 detail:CouriaCustomPreferencesController.class
                                                                   cell:PSLinkCell
                                                                   edit:Nil];
            custom.userInfo = plistPath;
            [specifiers addObjectsFromArray:@[[PSSpecifier emptyGroupSpecifier], custom]];
        }
        
        _specifiers = specifiers;
    }
	return _specifiers;
}

- (id)getValueForSpecifier:(PSSpecifier *)specifier
{
    return CouriaPreferencesGetUserDefaultForKey(self.specifier.identifier, specifier.identifier);
}

- (void)setValue:(id)value forSpecifier:(PSSpecifier *)specifier
{
    CouriaPreferencesSetUserDefaultForKey(self.specifier.identifier, specifier.identifier, value);
}

@end
