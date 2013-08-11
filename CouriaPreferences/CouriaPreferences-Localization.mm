NSString *CouriaLocalizedString(NSString *string)
{
    return [[NSBundle bundleWithPath:PreferenceBundlePath]localizedStringForKey:string value:string table:nil];
}
