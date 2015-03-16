#import "Headers.h"

static NSMutableDictionary *dataSources;
static NSMutableDictionary *delegates;
static NSUserDefaults *preferences;
static SBBulletinBannerController *bulletinBannerController;
static SBBannerController *bannerController;

id<CouriaDataSource> CouriaDataSource(NSString *application)
{
    return dataSources[application];
}

id<CouriaDelegate> CouriaDelegate(NSString *application)
{
    return delegates[application];
}

BOOL CouriaRegistered(NSString *application)
{
    return [application isEqualToString:MobileSMSIdentifier] || (CouriaDataSource(application) && CouriaDelegate(application));
}

void CouriaUpdateBulletinRequest(BBBulletinRequest *bulletinRequest)
{
    [bulletinRequest setContextValue:bulletinRequest.sectionID forKey:CouriaIdentifier".application"];
    [bulletinRequest setContextValue:[CouriaDataSource(bulletinRequest.sectionID) getUserIdentifier:bulletinRequest] forKey:CouriaIdentifier".user"];
    if ([bulletinRequest.sectionID isEqualToString:MobileSMSIdentifier]) {
        static void (^ const updateAction)(BBAction *, NSUInteger, BOOL *) = ^(BBAction *action, NSUInteger index, BOOL *stop) {
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
        [bulletin setContextValue:user forKey:CouriaIdentifier".user"];
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
        dataSources = [NSMutableDictionary dictionary];
        delegates = [NSMutableDictionary dictionary];
        preferences = [[NSUserDefaults alloc]initWithSuiteName:CouriaIdentifier];
        bulletinBannerController = (SBBulletinBannerController *)[NSClassFromString(@"SBBulletinBannerController") sharedInstance];
        bannerController = (SBBannerController *)[NSClassFromString(@"SBBannerController") sharedInstance];
    });
    return sharedInstance;
}

- (void)registerDataSource:(id<CouriaDataSource>)dataSource delegate:(id<CouriaDelegate>)delegate forApplication:(NSString *)applicationIdentifier
{
    if (dataSource != nil && delegate != nil && applicationIdentifier != nil && ![applicationIdentifier isEqualToString:MobileSMSIdentifier]) {
        [dataSources setObject:dataSource forKey:applicationIdentifier];
        [delegates setObject:delegate forKey:applicationIdentifier];
        [[CouriaExtras sharedInstance]registerExtrasForApplication:applicationIdentifier];
    }
}

- (void)unregisterForApplication:(NSString *)applicationIdentifier
{
    if (applicationIdentifier != nil && ![applicationIdentifier isEqualToString:MobileSMSIdentifier]) {
        [dataSources removeObjectForKey:applicationIdentifier];
        [delegates removeObjectForKey:applicationIdentifier];
        [[CouriaExtras sharedInstance]unregisterExtrasForApplication:applicationIdentifier];
    }
}

- (void)presentControllerForApplication:(NSString *)applicationIdentifier user:(NSString *)userIdentifier
{
    CouriaPresentViewController(applicationIdentifier, userIdentifier);
}

- (void)handleBulletin:(BBBulletin *)bulletin
{
    CouriaPresentViewController(bulletin.sectionID, [CouriaDataSource(bulletin.sectionID) getUserIdentifier:bulletin]);
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
