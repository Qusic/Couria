#import "CaptainHook/CaptainHook.h"
#import "CouriaController.h"
#import "CouriaActivatorListener.h"

static NSMutableDictionary *DataSources;
static NSMutableDictionary *Delegates;
static NSDictionary *UserDefaults;
static CPDistributedMessagingCenter *CouriaMessagingCenter;
static NSOperationQueue *CouriaDelegateOperationQueue;

static CouriaController *CurrentCouriaController;

static void userDefaultsChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    [UserDefaults release];
    UserDefaults = [[NSDictionary dictionaryWithContentsOfFile:UserDefaultsPlistPath]retain];
}

@implementation Couria

+ (void)load
{
    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        DataSources = [[NSMutableDictionary dictionary]retain];
        Delegates = [[NSMutableDictionary dictionary]retain];
        CouriaMessagingCenter = [[CPDistributedMessagingCenter centerNamed:CouriaIdentifier]retain];
        [CouriaMessagingCenter runServerOnCurrentThread];
        [CouriaMessagingCenter registerForMessageName:RegisteredApplicationsMessage target:[Couria sharedInstance] selector:@selector(message:info:)];
        CouriaDelegateOperationQueue = [[NSOperationQueue alloc]init];
        CouriaDelegateOperationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, userDefaultsChangedCallback, CFSTR(UserDefaultsChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(UserDefaultsChangedNotification), NULL, NULL, TRUE);
    }
}

+ (Couria *)sharedInstance
{
    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        static Couria *sharedInstance;
        if (sharedInstance == nil) {
            sharedInstance = [[self.class alloc]init];
        }
        return sharedInstance;
    } else {
        return nil;
    }
}

- (void)registerDataSource:(id<CouriaDataSource>)dataSource delegate:(id<CouriaDelegate>)delegate forApplication:(NSString *)applicationIdentifier
{
    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        if (dataSource != nil && delegate != nil && applicationIdentifier != nil) {
            [DataSources setObject:dataSource forKey:applicationIdentifier];
            [Delegates setObject:delegate forKey:applicationIdentifier];
            [[CouriaActivatorListener sharedInstance]registerListenerForApplication:applicationIdentifier];
        }
    }
}

- (void)unregisterForApplication:(NSString *)applicationIdentifier
{
    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        if (applicationIdentifier != nil) {
            [DataSources removeObjectForKey:applicationIdentifier];
            [Delegates removeObjectForKey:applicationIdentifier];
            [[CouriaActivatorListener sharedInstance]unregisterListenerForApplication:applicationIdentifier];
        }
    }
}

- (NSDictionary *)message:(NSString *)message info:(NSDictionary *)info
{
    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        NSDictionary *response = nil;
        if ([message isEqualToString:RegisteredApplicationsMessage]) {
            response = @{ApplicationsKey : DataSources.allKeys};
        } else if ([message isEqualToString:WidgetApplicationsMessage]) {
            NSMutableArray *applications = [NSMutableArray array];
            for (NSString *applicationIdentifier in DataSources.allKeys) {
                if (CouriaCanHandle(applicationIdentifier) && CouriaGetContacts(applicationIdentifier, nil) != nil) {
                    [applications addObject:applicationIdentifier];
                }
            }
            response = @{ApplicationsKey : applications};
        }
        return response;
    } else {
        return nil;
    }
}

- (void)presentControllerForApplication:(NSString *)applicationIdentifier user:(NSString *)userIdentifier
{
    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        CouriaHandle(applicationIdentifier, userIdentifier);
    }
}

@end

BOOL CouriaIsApplicationRegistered(NSString *application)
{
    return DataSources[application] != nil && Delegates[application] != nil;
}

BOOL CouriaIsHandling(void)
{
    return CurrentCouriaController != nil;
}

BOOL CouriaCanHandle(NSString *application)
{
    return CouriaIsApplicationRegistered(application) && [CouriaGetUserDefaultForKey(application, EnabledKey)boolValue];
}

BOOL CouriaCanHandleBulletin(BBBulletin *bulletin)
{
    return CouriaCanHandle(bulletin.sectionID) && CouriaGetUserIdentifier(bulletin) != nil;
}

void CouriaHandle(NSString *application, NSString *userIdentifier)
{
    if (!CouriaCanHandle(application)) {
        return;
    }
    if (userIdentifier == nil && CouriaGetContacts(application, nil) == nil) {
        return;
    }
    if (CouriaIsHandling()) {
        return;
    }
    CurrentCouriaController = [[CouriaController alloc]initWithApplication:application user:userIdentifier dismissHandler:^{
        [CurrentCouriaController release];
        CurrentCouriaController = nil;
    }];
    [CurrentCouriaController present];
}

void CouriaHandleBulletin(BBBulletin *bulletin)
{
    CouriaHandle(bulletin.sectionID, CouriaGetUserIdentifier(bulletin));
    CouriaHandleNewBulletin(bulletin);
}

void CouriaHandleNewBulletin(BBBulletin *bulletin)
{
    [[NSNotificationCenter defaultCenter]postNotification:[NSNotification notificationWithName:@NewBulletinPublishedNotification object:nil userInfo:@{BulletinKey : bulletin}]];
}

CouriaController *CouriaCurrentController(void)
{
    return CurrentCouriaController;
}

NSString *CouriaGetUserIdentifier(BBBulletin *bulletin)
{
    NSString *userIdentifier = [DataSources[bulletin.sectionID]getUserIdentifier:bulletin];
    return userIdentifier;
}

NSString *CouriaGetNickname(NSString *application, NSString *userIdentifier)
{
    if (userIdentifier.length == 0) {
        return nil;
    }
    NSString *nickname = nil;
    if ([DataSources[application]respondsToSelector:@selector(getNickname:)]) {
        nickname = [DataSources[application]getNickname:userIdentifier];
    }
    return nickname ? : userIdentifier;
}

NSArray *CouriaGetMessages(NSString *application, NSString *userIdentifier)
{
    if (userIdentifier.length == 0) {
        return nil;
    }
    NSMutableArray *messages = nil;
    if ([DataSources[application]respondsToSelector:@selector(getMessages:)]) {
        messages = [NSMutableArray array];
        for (id message in [DataSources[application]getMessages:userIdentifier]) {
            if ([message conformsToProtocol:@protocol(CouriaMessage)]) {
                [messages addObject:message];
            }
        }
    }
    return messages;
}

UIImage *CouriaGetAvatar(NSString *application, NSString *userIdentifier)
{
    if (userIdentifier.length == 0) {
        return nil;
    }
    UIImage *avatar = nil;
    if ([DataSources[application]respondsToSelector:@selector(getAvatar:)]) {
        avatar = [DataSources[application]getAvatar:userIdentifier];
    }
    return avatar;
}

NSArray *CouriaGetContacts(NSString *application, NSString *keyword)
{
    if (keyword == nil) {
        keyword = @"";
    }
    NSArray *contacts = nil;
    if ([DataSources[application]respondsToSelector:@selector(getContacts:)]) {
        contacts = [DataSources[application]getContacts:keyword];
    }
    return contacts;
}

void CouriaSendMessage(NSString *application, NSString *userIdentifier, id<CouriaMessage> message)
{
    if (userIdentifier.length == 0) {
        return;
    }
    CouriaMarkRead(application, userIdentifier);
    [CouriaDelegateOperationQueue addOperationWithBlock:^{
        [Delegates[application]sendMessage:message toUser:userIdentifier];
    }];
}

void CouriaMarkRead(NSString *application, NSString *userIdentifier)
{
    if (userIdentifier.length == 0) {
        return;
    }
    BBServer *bbServer = (BBServer *)[NSClassFromString(@"BBServer")sharedInstance];
    NSSet *bulletinsSet = [bbServer _allBulletinsForSectionID:application];
    NSMutableArray *readBulletins = [NSMutableArray array];
    for (BBBulletin *bulletin in bulletinsSet) {
        if ([CouriaGetUserIdentifier(bulletin)isEqualToString:userIdentifier]) {
            [readBulletins addObject:bulletin];
        }
    }
    if (CouriaShouldClearReadNotifications(application)) {
        SBAwayBulletinListController *awayBulletinController = [NSClassFromString(@"SBAwayController")sharedAwayController].awayView.bulletinController;
        LIBulletinListController *lockinfoBulletinListController = ((LIController *)[NSClassFromString(@"LIController")sharedInstance]).widgetController.bulletinController;
        BOOL isIOS7 = iOS7();
        for (BBBulletin *bulletin in readBulletins) {
            if (isIOS7) {
                [bbServer removeBulletinID:bulletin.bulletinID fromSection:bulletin.sectionID inFeed:0xFF];
            } else {
                [bbServer removeBulletinID:bulletin.bulletinID fromListSection:bulletin.sectionID];
            }
            [awayBulletinController observer:nil removeBulletin:bulletin];
            [lockinfoBulletinListController observer:nil removeBulletin:bulletin];
        }
    }
    if (CouriaShouldDecreaseBadgeNumber(application)) {
        SBIconModel *iconModel = CHIvar([NSClassFromString(@"SBIconController")sharedInstance], _iconModel, SBIconModel *);
        SBApplicationIcon *applicationIcon = [iconModel applicationIconForDisplayIdentifier:application];
        NSInteger unreadCount = applicationIcon.badgeValue - readBulletins.count;
        if (unreadCount < 0) { unreadCount = 0; }
        [applicationIcon setBadge:unreadCount > 0 ? @(unreadCount).stringValue : @""];
    }
    if ([Delegates[application]respondsToSelector:@selector(markRead:)]) {
        [CouriaDelegateOperationQueue addOperationWithBlock:^{
            [Delegates[application]markRead:userIdentifier];
        }];
    }
}

BOOL CouriaCanSendPhoto(NSString *application)
{
    BOOL sendPhoto = NO;
    if ([Delegates[application]respondsToSelector:@selector(canSendPhoto)]) {
        sendPhoto = [Delegates[application]canSendPhoto];
    }
    return sendPhoto;
}

BOOL CouriaCanSendMovie(NSString *application)
{
    BOOL sendMovie = NO;
    if ([Delegates[application]respondsToSelector:@selector(canSendMovie)]) {
        sendMovie = [Delegates[application]canSendMovie];
    }
    return sendMovie;
}

BOOL CouriaShouldClearReadNotifications(NSString *application)
{
    BOOL clearReadNotifications = YES;
    if ([Delegates[application]respondsToSelector:@selector(shouldClearReadNotifications)]) {
        clearReadNotifications = [Delegates[application]shouldClearReadNotifications];
    }
    return clearReadNotifications;
}

BOOL CouriaShouldDecreaseBadgeNumber(NSString *application)
{
    BOOL decreaseBadgeNumber = YES;
    if ([Delegates[application]respondsToSelector:@selector(shouldDecreaseBadgeNumber)]) {
        decreaseBadgeNumber = [Delegates[application]shouldDecreaseBadgeNumber];
    }
    return decreaseBadgeNumber;
}

void CouriaOpenApp(NSString *application)
{
    if (iOS7()) {
        SBLockScreenManager *lockscreenManager = (SBLockScreenManager *)[NSClassFromString(@"SBLockScreenManager") sharedInstance];
        if (lockscreenManager.isUILocked) {
            [lockscreenManager couria_unlockAndOpenApplication:application];
        } else {
            [[UIApplication sharedApplication]launchApplicationWithIdentifier:application suspended:NO];
        }
    } else {
        SBAwayController *awayController = [NSClassFromString(@"SBAwayController")sharedAwayController];
        if (awayController.isLocked) {
            [awayController couria_unlockAndOpenApplication:application];
        } else {
            [[UIApplication sharedApplication]launchApplicationWithIdentifier:application suspended:NO];
        }
    }
}

id CouriaGetUserDefaultForKey(NSString *application, NSString *key)
{
    return UserDefaults[application][key];
}
