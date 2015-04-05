#import "Headers.h"

@interface CouriaPreferencesController : PSListController
@end

@implementation CouriaPreferencesController

- (NSArray *)specifiers
{
    if (_specifiers == nil) {
        PSSpecifier *specifier = [PSSpecifier groupSpecifierWithName:@"Beta Note"];
        [specifier setProperty:@"Couria should be stable with SMS and iMessage now but it is still in development and lacks some features. Many people complained the old version crashed a lot and this time I hope it is finally resolved.\nBecause Couria API for third-party apps has not been done, currently there are no options to configure.\n\nBesides, theming feature using images in previous versions is gone, obviously. You may expect app-specific bubbles customization in a later update. I saw requests about that and it sounds reasonable.\n\nCouria will continue being free and open-source (GPL license). After Couria API is finished, I will release the code at https://github.com/Qusic/Couria\n\nQusic (@QusicS on Twitter)" forKey:@"footerText"];
        _specifiers = @[specifier];
    }
    return _specifiers;
}

@end
