#import "Headers.h"

@interface CouriaPreferencesController : PSListController
@end

@implementation CouriaPreferencesController

- (NSArray *)specifiers
{
    if (_specifiers == nil) {
        PSSpecifier *specifier = [PSSpecifier groupSpecifierWithName:@"Beta Note"];
        [specifier setProperty:@"Couria should be stable with SMS and iMessage now but it is still in development and lacks some features, such as sending photos.\nBecause Couria API for third-party apps has not been done, currently there are no options to configure.\n\nBesides, Theming feature in previous versions is gone, obviously.\n\nCouria will continue being free and open-source (GPL license). After Couria API is finished, I will release the code at https://github.com/Qusic/Couria\n\nQusic (@QusicS on Twitter)" forKey:@"footerText"];
        _specifiers = @[specifier];
    }
    return _specifiers;
}

@end
