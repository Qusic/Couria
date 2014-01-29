#import "Headers.h"
#import "CouriaPreferencesController.h"
#import "CouriaExtensionPreferencesController.h"
#import <Social/Social.h>

@interface CouriaPreferencesController ()

@property(retain) NSMutableDictionary *extensions;
@property(retain) NSMutableDictionary *themes;
@property(retain) NSMutableArray *translationCredits;

@end

@implementation CouriaPreferencesController

- (instancetype)init
{
    self = [super init];
	if (self) {
        _extensions = [NSMutableDictionary dictionary];
        NSArray *extensionIdentifiers = CouriaPreferencesGetExtensions();
        for (NSString *extensionIdentifier in extensionIdentifiers) {
            PSSpecifier *extensionSpecifier = [PSSpecifier preferenceSpecifierNamed:CouriaPreferencesGetExtensionDisplayName(extensionIdentifier)
                                                                             target:self set:NULL get:NULL
                                                                             detail:CouriaExtensionPreferencesController.class
                                                                               cell:PSLinkCell
                                                                               edit:Nil];
            [extensionSpecifier setIdentifier:extensionIdentifier];
            [extensionSpecifier setProperty:extensionIdentifier forKey:@"iconCache"];
            [extensionSpecifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:extensionIdentifier format:0 scale:[UIScreen mainScreen].scale] forKey:@"iconImage"];
            _extensions[extensionIdentifier] = extensionSpecifier;
        }

        _themes = [NSMutableDictionary dictionary];
        NSArray *themeIdentifiers = CouriaPreferencesGetThemes();
        for (NSString *themeIdentifier in themeIdentifiers) {
            PSSpecifier *themeSpecifier = [PSSpecifier preferenceSpecifierNamed:CouriaPreferencesGetThemeDisplayName(themeIdentifier)
                                                                         target:self set:NULL get:NULL
                                                                         detail:Nil
                                                                           cell:PSTitleValueCell
                                                                           edit:Nil];
            [themeSpecifier setIdentifier:themeIdentifier];
            _themes[themeIdentifier] = themeSpecifier;
        }

        _translationCredits = [NSMutableArray array];
        for (NSString *string in [[self.class translationCreditsData].allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
            PSSpecifier *dataSpecifier = [PSSpecifier preferenceSpecifierNamed:string
                                                                        target:self set:NULL
                                                                           get:@selector(getValueForTranslationCreditsSpecifier:)
                                                                        detail:Nil
                                                                          cell:PSTitleValueCell
                                                                          edit:Nil];
            [dataSpecifier setIdentifier:string];
            [_translationCredits addObject:dataSpecifier];
        }
	}
	return self;
}

- (NSArray *)specifiers
{
	if (_specifiers == nil) {
        NSMutableArray *specifiers = [NSMutableArray array];
        [specifiers addObject:[PSSpecifier groupSpecifierWithName:CouriaLocalizedString(@"EXTENSIONS")]];
        if (_extensions.count > 0) {
            [specifiers addObjectsFromArray:_extensions.allValues];
        } else {
            [specifiers addObject:[PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"NO_INSTALLED_ITEMS")
                                                                 target:self set:NULL get:NULL
                                                                 detail:Nil
                                                                   cell:PSStaticTextCell
                                                                   edit:Nil]];
        }
        [specifiers addObject:[PSSpecifier groupSpecifierWithName:CouriaLocalizedString(@"THEMES")]];
        if (_themes.count > 0) {
            [specifiers addObjectsFromArray:_themes.allValues];
        } else {
            [specifiers addObject:[PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"NO_INSTALLED_ITEMS")
                                                                 target:self set:NULL get:NULL
                                                                 detail:Nil
                                                                   cell:PSStaticTextCell
                                                                   edit:Nil]];
        }
        PSSpecifier *about = [PSSpecifier groupSpecifierWithName:CouriaLocalizedString(@"ABOUT")];
        [about setProperty:@"\nCouria © 2014 Qusic" forKey:@"footerText"];
        [about setProperty:@(YES) forKey:@"isStaticText"];
        PSSpecifier *twitter = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"TWITTER")
                                                              target:self set:NULL get:NULL
                                                              detail:Nil
                                                                cell:PSButtonCell
                                                                edit:Nil];
        [twitter setIdentifier:@"Twitter"];
        twitter->action = @selector(doActionForSpecifier:);
        PSSpecifier *donate = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"DONATE")
                                                             target:self set:NULL get:NULL
                                                             detail:Nil
                                                               cell:PSButtonCell
                                                               edit:Nil];
        [donate setIdentifier:@"Donate"];
        donate->action = @selector(doActionForSpecifier:);
        PSSpecifier *translationCredits = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"TRANSLATION_CREDITS")
                                                                         target:self set:NULL get:NULL
                                                                         detail:Nil
                                                                           cell:PSButtonCell
                                                                           edit:Nil];
        [translationCredits setIdentifier:@"TranslationCredits"];
        translationCredits->action = @selector(doActionForSpecifier:);
        [specifiers addObjectsFromArray:@[about, twitter, donate, translationCredits]];

        _specifiers = specifiers;
    }
	return _specifiers;
}

- (void)loadView
{
    [super loadView];
    ((UIViewController *)self).navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"o(≧▽≦)o" style:UIBarButtonItemStyleBordered target:self action:@selector(composeTweet:)];
}

- (void)doActionForSpecifier:(PSSpecifier *)specifier
{
    NSString *identifier = specifier.identifier;
    if ([identifier isEqualToString:@"Twitter"]) {
        [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"https://twitter.com/QusicS"]];
    } else if ([identifier isEqualToString:@"Donate"]) {
        [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=PJ93RW7TLKZZ4"]];
    } else if ([identifier isEqualToString:@"TranslationCredits"]) {
        if ([[self.specifiers.lastObject identifier]isEqualToString:@"TranslationCredits"]) {
            [self addSpecifiersFromArray:_translationCredits animated:YES];
        } else {
            for (PSSpecifier *specifier in _translationCredits) {
                [self removeSpecifier:specifier animated:YES];
            }
        }
    }
}

- (void)composeTweet:(UIBarButtonItem *)buttonItem
{
    NSString *serviceType = nil;
    if ([[NSLocale preferredLanguages][0]isEqualToString:@"zh-Hans"]) {
        serviceType = SLServiceTypeSinaWeibo;
    } else {
        serviceType = SLServiceTypeTwitter;
    }
    SLComposeViewController *composeSheet = [SLComposeViewController composeViewControllerForServiceType:serviceType];
    [composeSheet setInitialText:CouriaLocalizedString(@"SHARE_TEXT")];
    [(UIViewController *)self presentViewController:composeSheet animated:YES completion:nil];
}

+ (NSDictionary *)translationCreditsData
{
    return @{@"Deutsch": @"Tim Klute",
             @"Español": @"MXNMike",
             @"Français": @"Léo",
             @"Italiano": @"Bruno Di Marco",
             @"Nederlands": @"Alphyraz",
             @"Русский": @"Victor Ryabov",
             @"Svenska": @"Mattias W",
             @"繁體中文": @"Hiraku",
             @"日本語": @"wakinchan",
             @"العربية": @"Mohamed El Fawal"};
}

- (id)getValueForTranslationCreditsSpecifier:(PSSpecifier *)specifier
{
    return [self.class translationCreditsData][specifier.identifier];
}

@end