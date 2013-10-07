#import "UIImage+Couria.h"

@implementation UIImage (Couria)

+ (UIImage *)imageNamed:(NSString *)name bundle:(NSBundle *)bundle
{
    if (bundle == nil) {
        bundle = [NSBundle mainBundle];
    }
    
    NSString *extension = name.pathExtension;
    name = [name stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", extension]
                                           withString:@""
                                              options:NSBackwardsSearch | NSAnchoredSearch
                                                range:NSMakeRange(0, name.length)];
    
    NSString *modifier = @"";
    NSUInteger scale = (NSUInteger)round([UIScreen mainScreen].scale);
    if (scale != 1) {
        modifier = [NSString stringWithFormat:@"@%lux", (unsigned long)scale];
    }

    NSString *resolutionDependentName = [NSString stringWithFormat:@"%@%@", name, modifier];
    
    NSString *path = [bundle pathForResource:resolutionDependentName ofType:extension];
    if (path == nil) {
        path = [bundle pathForResource:name ofType:extension];
    }
    
    if (path == nil) {
        return nil;
    } else {
        return [UIImage imageWithContentsOfFile:path];
    }
}

@end
