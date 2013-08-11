#import "CouriaCustomPreferencesController.h"

@implementation CouriaCustomPreferencesController

- (NSArray *)specifiers
{
    if (_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:[[_specifier.userInfo lastPathComponent]stringByDeletingPathExtension] target:self];
    }
    return _specifiers;
}

- (id)bundle
{
    return [NSBundle bundleWithPath:[_specifier.userInfo stringByDeletingLastPathComponent]];
}

@end
