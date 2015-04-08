#import "Headers.h"

@interface CouriaPreferencesController : PSListController
@property (retain) NSUserDefaults *preferences;
@property (retain) CPDistributedMessagingCenter *messagingCenter;
@property (retain) NSArray *translationCreditsSpecifiers;
@end

@interface CouriaExtensionPreferencesController : PSListController
@end

@implementation CouriaPreferencesController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.preferences = [[NSUserDefaults alloc]initWithSuiteName:CouriaIdentifier];
        self.messagingCenter = [CPDistributedMessagingCenter centerNamed:CouriaIdentifier];
    }
    return self;
}

- (NSArray *)specifiers
{
    if (_specifiers == nil) {
        NSMutableArray *specifiers = [NSMutableArray array];
        [specifiers addObject:[PSSpecifier groupSpecifierWithName:CouriaLocalizedString(@"EXTENSIONS")]];
        NSArray *extensions = [NSKeyedUnarchiver unarchiveObjectWithData:[self.messagingCenter sendMessageAndReceiveReplyName:ListExtensionsMessage userInfo:nil error:NULL][ExtensionsKey]];
        if (extensions.count > 0) {
            [extensions enumerateObjectsUsingBlock:^(NSDictionary *extension, NSUInteger index, BOOL *stop) {
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
        [specifiers addObject:[PSSpecifier groupSpecifierWithName:CouriaLocalizedString(@"ABOUT")]];
        [specifiers addObject:({
            PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:@"@QusicS" target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
            [specifier setIdentifier:@"twitter"];
            [specifier setProperty:CouriaImage(@"Twitter") forKey:@"iconImage"];
            specifier->action = @selector(actionForSpecifier:);
            specifier;
        })];
        [specifiers addObject:({
            PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:@"Couria" target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
            [specifier setIdentifier:@"github"];
            [specifier setProperty:CouriaImage(@"Github") forKey:@"iconImage"];
            specifier->action = @selector(actionForSpecifier:);
            specifier;
        })];
        [specifiers addObject:({
            PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"DONATE") target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
            [specifier setIdentifier:@"donate"];
            [specifier setProperty:CouriaImage(@"PayPal") forKey:@"iconImage"];
            specifier->action = @selector(actionForSpecifier:);
            specifier;
        })];
        [specifiers addObject:({
            PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:CouriaLocalizedString(@"TRANSLATION_CREDITS") target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
            [specifier setIdentifier:@"translationCredits"];
            [specifier setProperty:CouriaImage(@"Languages") forKey:@"iconImage"];
            specifier->action = @selector(actionForSpecifier:);
            specifier;
        })];
        [specifiers addObject:({
            PSSpecifier *specifier = [PSSpecifier emptyGroupSpecifier];
            [specifier setProperty:@"Couria © 2015 Qusic" forKey:@"footerText"];
            specifier;
        })];
        _specifiers = specifiers;
        NSMutableArray *translationCreditsSpecifiers = [NSMutableArray array];
        [[self.translationCreditsData.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]enumerateObjectsUsingBlock:^(NSString *language, NSUInteger index, BOOL *stop) {
            [translationCreditsSpecifiers addObject:({
                PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:language target:self set:NULL get:@selector(getValueForTranslationCreditsSpecifier:) detail:Nil cell:PSTitleValueCell edit:Nil];
                [specifier setIdentifier:language];
                specifier;
            })];
        }];
        _translationCreditsSpecifiers = translationCreditsSpecifiers;
    }
    return _specifiers;
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

@end

@implementation CouriaExtensionPreferencesController

- (NSArray *)specifiers
{
    if (_specifiers == nil) {
        _specifiers = @[
        ];
    }
    return _specifiers;
}

@end
