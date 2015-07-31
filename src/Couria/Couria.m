#import "../Headers.h"

static NSMutableDictionary *extensions;
static NSUserDefaults *preferences;

CHDeclareClass(SBApplicationController)
CHDeclareClass(SBIconViewMap)
CHDeclareClass(SBBulletinBannerController)
CHDeclareClass(SBBannerController)

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
    SBApplication *application = [CHSharedInstance(SBApplicationController) applicationWithBundleIdentifier:applicationIdentifier];
    return application.displayName;
}

UIImage *CouriaApplicationIcon(NSString *applicationIdentifier, BOOL small)
{
    SBApplicationIcon *icon = [[CHClass(SBIconViewMap) homescreenMap].iconModel applicationIconForBundleIdentifier:applicationIdentifier];
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
            [bulletinRequest._allActions enumerateObjectsUsingBlock:^(BBAction *action, NSUInteger index, BOOL *stop) {
                if ([action.remoteServiceBundleIdentifier isEqualToString:MessagesNotificationViewServiceIdentifier] && [action.remoteViewControllerClassName isEqualToString:@"CKInlineReplyViewController"]) {
                    action.remoteViewControllerClassName = @"CouriaInlineReplyViewController_MobileSMSApp";
                    action.authenticationRequired = [preferences boolForKey:[applicationIdentifier stringByAppendingString:AuthenticationRequiredSetting]];
                }
            }];
            if (bulletinRequest._allSupplementaryActions.count == 0) {
                BBAction *action = [BBAction actionWithIdentifier:CouriaIdentifier ActionDomain];
                action.actionType = 7;
                action.appearance = [BBAppearance appearanceWithTitle:CouriaLocalizedString(@"REPLY_NOTIFICATION_ACTION")];
                action.remoteServiceBundleIdentifier = MessagesNotificationViewServiceIdentifier;
                action.remoteViewControllerClassName = @"CouriaInlineReplyViewController_MobileSMSApp";
                action.authenticationRequired = [preferences boolForKey:[applicationIdentifier stringByAppendingString:AuthenticationRequiredSetting]];
                action.activationMode = 1;
                [bulletinRequest setSupplementaryActions:@[action]];
            }
        } else {
            [bulletinRequest.supplementaryActionsByLayout.allKeys enumerateObjectsUsingBlock:^(NSNumber *layout, NSUInteger index, BOOL *stop) {
                [bulletinRequest setSupplementaryActions:nil forLayout:layout.integerValue];
            }];
            BBAction *action = [BBAction actionWithIdentifier:CouriaIdentifier ActionDomain];
            action.actionType = 7;
            action.appearance = [BBAppearance appearanceWithTitle:CouriaLocalizedString(@"REPLY_NOTIFICATION_ACTION")];
            action.remoteServiceBundleIdentifier = MessagesNotificationViewServiceIdentifier;
            action.remoteViewControllerClassName = @"CouriaInlineReplyViewController_ThirdPartyApp";
            action.authenticationRequired = [preferences boolForKey:[applicationIdentifier stringByAppendingString:AuthenticationRequiredSetting]];
            action.activationMode = 1;
            [bulletinRequest setSupplementaryActions:@[action]];
        }
    }
}

void CouriaPresentViewController(NSString *application, NSString *user)
{
    if (CouriaEnabled(application) && CHSharedInstance(SBBannerController)._bannerContext == nil) {
        BBBulletinRequest *bulletin = [[BBBulletinRequest alloc]init];
        [bulletin generateNewBulletinID];
        bulletin.sectionID = application;
        bulletin.title = CouriaLocalizedString(@"NEW_MESSAGE");
        bulletin.defaultAction = [BBAction actionWithLaunchBundleID:application];
        CouriaUpdateBulletinRequest(bulletin);
        [bulletin setContextValue:user forKey:[application isEqualToString:MobileSMSIdentifier] ? CKBBUserInfoKeyChatIdentifierKey : CouriaIdentifier UserDomain];
        BBAction *action = bulletin.supplementaryActions.firstObject;
        dispatch_async(dispatch_get_main_queue(), ^{
            [CHSharedInstance(SBBulletinBannerController) modallyPresentBannerForBulletin:bulletin action:action];
        });
    }
}

void CouriaDismissViewController(void)
{
    SBBannerController *bannerController = CHSharedInstance(SBBannerController);
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
        CHLoadLateClass(SBApplicationController);
        CHLoadLateClass(SBIconViewMap);
        CHLoadLateClass(SBBulletinBannerController);
        CHLoadLateClass(SBBannerController);
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
        CouriaNotificationsInit();
        CouriaGesturesInit();
    }
}
