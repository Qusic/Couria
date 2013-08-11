id CouriaPreferencesGetUserDefaultForKey(NSString *application, NSString *key)
{
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:UserDefaultsPlistPath];
    return defaults[application][key];
}

void CouriaPreferencesSetUserDefaultForKey(NSString *application, NSString *key, id value)
{
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:UserDefaultsPlistPath]];
    NSMutableDictionary *applicationDefaults = [NSMutableDictionary dictionary];
    [applicationDefaults addEntriesFromDictionary:defaults[application]];
    [applicationDefaults setObject:value forKey:key];
    [defaults setObject:applicationDefaults forKey:application];
    [defaults writeToFile:UserDefaultsPlistPath atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(UserDefaultsChangedNotification), NULL, NULL, TRUE);
}

NSArray *CouriaPreferencesGetExtensions(void)
{
    NSArray *extensionIdentifiers = [[CPDistributedMessagingCenter centerNamed:CouriaIdentifier]sendMessageAndReceiveReplyName:RegisteredApplicationsMessage userInfo:nil][ApplicationsKey];
    return extensionIdentifiers;
}

NSArray *CouriaPreferencesGetThemes(void)
{
    NSMutableArray *themeIdentifiers = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *themeURLs = [fileManager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:ThemesDirectoryPath] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants|NSDirectoryEnumerationSkipsPackageDescendants|NSDirectoryEnumerationSkipsHiddenFiles error:nil];
    for (NSURL *themeURL in themeURLs) {
        [themeIdentifiers addObject:themeURL.lastPathComponent];
    }
    return themeIdentifiers;
}

NSString *CouriaPreferencesGetExtensionDisplayName(NSString *extension)
{
    NSDictionary *installationCache = [NSDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Caches/com.apple.mobile.installation.plist"];
    NSString *displayName = installationCache[@"System"][extension][@"CFBundleDisplayName"];
    if (displayName == nil) {
        displayName = installationCache[@"User"][extension][@"CFBundleDisplayName"];
    }
    if (displayName == nil) {
        displayName = extension;
    }
    return displayName;
}

NSString *CouriaPreferencesGetThemeDisplayName(NSString *theme)
{
    NSString *displayName = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/%@", ThemesDirectoryPath, theme, @"Theme.plist"]][@"ThemeName"];
    if (displayName == nil) {
        displayName = theme;
    }
    return displayName;
}
