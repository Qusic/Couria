#import "Headers.h"

NSString *CouriaLocalizedString(NSString *string)
{
    return [[NSBundle bundleWithPath:LocalizationsDirectoryPath]localizedStringForKey:string value:string table:nil];
}
