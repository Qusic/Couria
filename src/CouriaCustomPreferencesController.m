#import "CouriaCustomPreferencesController.h"

@implementation CouriaCustomPreferencesController

- (NSArray *)specifiers
{
    if (_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:[[self.specifier.userInfo lastPathComponent]stringByDeletingPathExtension] target:self];
    }
    return _specifiers;
}

- (NSBundle *)bundle
{
    return [NSBundle bundleWithPath:[self.specifier.userInfo stringByDeletingLastPathComponent]];
}

@end
