#import "Headers.h"

static NSMutableDictionary *extensions;
static NSUserDefaults *preferences;
static SBApplicationController *applicationController;
static SBIconModel *iconModel;
static SBBulletinBannerController *bulletinBannerController;
static SBBannerController *bannerController;

NSDictionary *CouriaExtensions(void)
{
    return extensions;
}

NSUserDefaults *CouriaPreferences(void)
{
    return preferences;
}

id<CouriaExtension> CouriaExtension(NSString *application)
{
    return extensions[application];
}

BOOL CouriaEnabled(NSString *application)
{
    return ([application isEqualToString:MobileSMSIdentifier] || CouriaExtension(application)) && [preferences boolForKey:[application stringByAppendingString:EnabledSetting]];
}

NSString *CouriaApplicationName(NSString *applicationIdentifier)
{
    SBApplication *application = [applicationController applicationWithBundleIdentifier:applicationIdentifier];
    return application.displayName;
}

UIImage *CouriaApplicationIcon(NSString *applicationIdentifier, BOOL small)
{
    SBApplicationIcon *icon = [iconModel applicationIconForBundleIdentifier:applicationIdentifier];
    return [icon getIconImage:small ? 0 : 2];
}

void CouriaUpdateBulletinRequest(BBBulletinRequest *bulletinRequest)
{
    NSString *applicationIdentifier = bulletinRequest.sectionID;
    if (CouriaEnabled(applicationIdentifier)) {
        id<CouriaExtension> extension = CouriaExtension(applicationIdentifier);
        [bulletinRequest setContextValue:applicationIdentifier forKey:CouriaIdentifier ApplicationDomain];
        [bulletinRequest setContextValue:[extension getUserIdentifier:bulletinRequest] forKey:CouriaIdentifier UserDomain];
        [bulletinRequest setContextValue:@{
            CanSendPhotosOption: @([extension respondsToSelector:@selector(canSendPhotos)] ? extension.canSendPhotos : NO)
        } forKey:CouriaIdentifier OptionsDomain];
        if ([applicationIdentifier isEqualToString:MobileSMSIdentifier]) {
            void (^ updateAction)(BBAction *, NSUInteger, BOOL *) = ^(BBAction *action, NSUInteger index, BOOL *stop) {
                if ([action.remoteServiceBundleIdentifier isEqualToString:MessagesNotificationViewServiceIdentifier] && [action.remoteViewControllerClassName isEqualToString:@"CKInlineReplyViewController"]) {
                    action.remoteViewControllerClassName = @"CouriaInlineReplyViewController_MobileSMSApp";
                    action.authenticationRequired = [preferences boolForKey:[applicationIdentifier stringByAppendingString:AuthenticationRequiredSetting]];
                }
            };
            [bulletinRequest.actions.allValues enumerateObjectsUsingBlock:updateAction];
            [bulletinRequest.supplementaryActions enumerateObjectsUsingBlock:updateAction];
            if (bulletinRequest.supplementaryActions.count == 0) {
                BBAction *action = [BBAction actionWithIdentifier:CouriaIdentifier ActionDomain];
                action.appearance = [BBAppearance appearanceWithTitle:CouriaLocalizedString(@"REPLY_NOTIFICATION_ACTION")];
                action.remoteServiceBundleIdentifier = MessagesNotificationViewServiceIdentifier;
                action.remoteViewControllerClassName = @"CouriaInlineReplyViewController_MobileSMSApp";
                action.authenticationRequired = [preferences boolForKey:[applicationIdentifier stringByAppendingString:AuthenticationRequiredSetting]];
                bulletinRequest.supplementaryActions = @[action];
            }
        } else {
            BBAction *action = [BBAction actionWithIdentifier:CouriaIdentifier ActionDomain];
            action.appearance = [BBAppearance appearanceWithTitle:CouriaLocalizedString(@"REPLY_NOTIFICATION_ACTION")];
            action.remoteServiceBundleIdentifier = MessagesNotificationViewServiceIdentifier;
            action.remoteViewControllerClassName = @"CouriaInlineReplyViewController_ThirdPartyApp";
            action.authenticationRequired = [preferences boolForKey:[applicationIdentifier stringByAppendingString:AuthenticationRequiredSetting]];
            bulletinRequest.supplementaryActions = @[action];
        }
    }
}

void CouriaPresentViewController(NSString *application, NSString *user)
{
    if (CouriaEnabled(application) && bannerController._bannerContext == nil) {
        BBBulletinRequest *bulletin = [[BBBulletinRequest alloc]init];
        [bulletin generateNewBulletinID];
        bulletin.sectionID = application;
        bulletin.title = CouriaLocalizedString(@"NEW_MESSAGE");
        bulletin.defaultAction = [BBAction actionWithLaunchBundleID:application];
        CouriaUpdateBulletinRequest(bulletin);
        [bulletin setContextValue:user forKey:[application isEqualToString:MobileSMSIdentifier] ? CKBBUserInfoKeyChatIdentifierKey : CouriaIdentifier UserDomain];
        BBAction *action = bulletin.supplementaryActions[0];
        dispatch_async(dispatch_get_main_queue(), ^{
            [bulletinBannerController modallyPresentBannerForBulletin:bulletin action:action];
        });
    }
}

void CouriaDismissViewController(void)
{
    if (bannerController._bannerContext != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [bannerController dismissBannerWithAnimation:YES reason:1];
        });
    }
}

@implementation Couria

+ (instancetype)sharedInstance
{
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc]init];
        extensions = [NSMutableDictionary dictionary];
        preferences = [[NSUserDefaults alloc]initWithSuiteName:CouriaIdentifier];
        CouriaRegisterDefaults(preferences, MobileSMSIdentifier);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            applicationController = (SBApplicationController *)[NSClassFromString(@"SBApplicationController") sharedInstance];
            iconModel = ((SBIconViewMap *)[NSClassFromString(@"SBIconViewMap") homescreenMap]).iconModel;
            bulletinBannerController = (SBBulletinBannerController *)[NSClassFromString(@"SBBulletinBannerController") sharedInstance];
            bannerController = (SBBannerController *)[NSClassFromString(@"SBBannerController") sharedInstance];
        });
    });
    return sharedInstance;
}

- (void)registerExtension:(id<CouriaExtension>)extension forApplication:(NSString *)applicationIdentifier
{
    if (extension != nil && applicationIdentifier != nil && ![applicationIdentifier isEqualToString:MobileSMSIdentifier]) {
        [extensions setObject:extension forKey:applicationIdentifier];
        [[CouriaExtras sharedInstance]registerExtrasForApplication:applicationIdentifier];
        CouriaRegisterDefaults(preferences, applicationIdentifier);
    }
}

- (void)unregisterExtensionForApplication:(NSString *)applicationIdentifier
{
    if (applicationIdentifier != nil && ![applicationIdentifier isEqualToString:MobileSMSIdentifier]) {
        [extensions removeObjectForKey:applicationIdentifier];
        [[CouriaExtras sharedInstance]unregisterExtrasForApplication:applicationIdentifier];
    }
}

- (void)presentControllerForApplication:(NSString *)applicationIdentifier user:(NSString *)userIdentifier
{
    CouriaPresentViewController(applicationIdentifier, userIdentifier);
}

- (void)handleBulletin:(BBBulletin *)bulletin
{
    CouriaPresentViewController(bulletin.sectionID, [CouriaExtension(bulletin.sectionID) getUserIdentifier:bulletin]);
}

@end

@implementation CouriaMessage
@end

CHConstructor
{
    @autoreleasepool {
        [Couria sharedInstance];
        [[CouriaService sharedInstance]run];
        [[CouriaExtras sharedInstance]registerExtrasForApplication:MobileSMSIdentifier];
    }
}
