#import "Headers.h"

static NSMutableDictionary *extensions;
static NSUserDefaults *preferences;
static SBBulletinBannerController *bulletinBannerController;
static SBBannerController *bannerController;

id<CouriaExtension> CouriaExtension(NSString *application)
{
    return extensions[application];
}

BOOL CouriaRegistered(NSString *application)
{
    return [application isEqualToString:MobileSMSIdentifier] || CouriaExtension(application);
}

void CouriaUpdateBulletinRequest(BBBulletinRequest *bulletinRequest)
{
    id<CouriaExtension> extension = CouriaExtension(bulletinRequest.sectionID);
    [bulletinRequest setContextValue:bulletinRequest.sectionID forKey:CouriaIdentifier".application"];
    [bulletinRequest setContextValue:[extension getUserIdentifier:bulletinRequest] forKey:CouriaIdentifier".user"];
    [bulletinRequest setContextValue:@{
        @"canSendPhotos": @([extension respondsToSelector:@selector(canSendPhotos)] ? extension.canSendPhotos : NO)
    } forKey:CouriaIdentifier".options"];
    if ([bulletinRequest.sectionID isEqualToString:MobileSMSIdentifier]) {
        void (^ updateAction)(BBAction *, NSUInteger, BOOL *) = ^(BBAction *action, NSUInteger index, BOOL *stop) {
            if ([action.remoteServiceBundleIdentifier isEqualToString:@"com.apple.mobilesms.notification"] && [action.remoteViewControllerClassName isEqualToString:@"CKInlineReplyViewController"]) {
                action.remoteViewControllerClassName = @"CouriaInlineReplyViewController_MobileSMSApp";
            }
        };
        [bulletinRequest.actions.allValues enumerateObjectsUsingBlock:updateAction];
        [bulletinRequest.supplementaryActions enumerateObjectsUsingBlock:updateAction];
        if (bulletinRequest.supplementaryActions.count == 0) {
            BBAction *action = [BBAction actionWithIdentifier:CouriaIdentifier".action"];
            action.appearance = [BBAppearance appearanceWithTitle:CouriaLocalizedString(@"REPLY_NOTIFICATION_ACTION")];
            action.remoteServiceBundleIdentifier = @"com.apple.mobilesms.notification";
            action.remoteViewControllerClassName = @"CouriaInlineReplyViewController_MobileSMSApp";
            bulletinRequest.supplementaryActions = @[action];
        }
    } else if (CouriaRegistered(bulletinRequest.sectionID)) {
        BBAction *action = [BBAction actionWithIdentifier:CouriaIdentifier".action"];
        action.appearance = [BBAppearance appearanceWithTitle:CouriaLocalizedString(@"REPLY_NOTIFICATION_ACTION")];
        action.remoteServiceBundleIdentifier = @"com.apple.mobilesms.notification";
        action.remoteViewControllerClassName = @"CouriaInlineReplyViewController_ThirdPartyApp";
        bulletinRequest.supplementaryActions = @[action];
    }
}

void CouriaPresentViewController(NSString *application, NSString *user)
{
    if (CouriaRegistered(application) && bannerController._bannerContext == nil) {
        BBBulletinRequest *bulletin = [[BBBulletinRequest alloc]init];
        [bulletin generateNewBulletinID];
        bulletin.sectionID = application;
        bulletin.title = CouriaLocalizedString(@"NEW_MESSAGE");
        bulletin.defaultAction = [BBAction actionWithLaunchBundleID:application];
        CouriaUpdateBulletinRequest(bulletin);
        [bulletin setContextValue:user forKey:[application isEqualToString:MobileSMSIdentifier] ? @"CKBBUserInfoKeyChatIdentifier" : CouriaIdentifier".user"];
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
