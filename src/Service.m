#import "Headers.h"

static CPDistributedMessagingCenter *messagingCenter;
static SBBannerController *bannerController;
static BBServer *bbServer;

@implementation CouriaService

+ (instancetype)sharedInstance
{
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc]init];
        messagingCenter = [CPDistributedMessagingCenter centerNamed:CouriaIdentifier];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            bannerController = (SBBannerController *)[NSClassFromString(@"SBBannerController") sharedInstance];
            bbServer = [BBServer sharedInstance];
        });
    });
    return sharedInstance;
}

- (void)run
{
    [messagingCenter runServerOnCurrentThread];
    [messagingCenter registerForMessageName:@"getMessages" target:self selector:@selector(processAppRequest:data:)];
    [messagingCenter registerForMessageName:@"getContacts" target:self selector:@selector(processAppRequest:data:)];
    [messagingCenter registerForMessageName:@"sendMessage" target:self selector:@selector(processAppRequest:data:)];
    [messagingCenter registerForMessageName:@"markRead" target:self selector:@selector(processAppRequest:data:)];
    [messagingCenter registerForMessageName:@"updateBanner" target:self selector:@selector(processUIRequest:data:)];
}

- (NSDictionary *)processAppRequest:(NSString *)request data:(NSDictionary *)data
{
    id<CouriaExtension> extension; NSString *application; NSString *user; NSDictionary *response;
    for (BOOL _valid = ({
        BOOL valid = NO;
        if (CouriaRegistered(application = data[@"application"])) {
            extension = CouriaExtension(application);
            user = data[@"user"];
            valid = YES;
        }
        valid;
    }); _valid; _valid = NO) {
        if ([request isEqualToString:@"getMessages"]) {
            if ([extension respondsToSelector:@selector(getMessages:)]) {
                NSMutableArray *result = [NSMutableArray array];
                [[extension getMessages:user]enumerateObjectsUsingBlock:^(id<CouriaMessage> message, NSUInteger idx, BOOL *stop) {
                    NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary];
                    id content = message.content;
                    BOOL outgoing = message.outgoing;
                    NSDate *timestamp = [message respondsToSelector:@selector(timestamp)] ? message.timestamp : nil;
                    messageDictionary[@"outgoing"] = @(outgoing);
                    if ([timestamp isKindOfClass:NSDate.class]) {
                        messageDictionary[@"timestamp"] = timestamp;
                    }
                    if ([content isKindOfClass:NSString.class] || [content isKindOfClass:NSURL.class]) {
                        messageDictionary[@"content"] = content;
                        [result addObject:messageDictionary];
                    }
                }];
                response = @{@"messages": [NSKeyedArchiver archivedDataWithRootObject:result]};
            }
        } else if ([request isEqualToString:@"getContacts"]) {
            if ([extension respondsToSelector:@selector(getContacts:)]) {
                NSMutableArray *result = [NSMutableArray array];
                [[extension getContacts:data[@"keyword"]]enumerateObjectsUsingBlock:^(NSString *contact, NSUInteger idx, BOOL *stop) {
                    NSMutableDictionary *contactDictionary = [NSMutableDictionary dictionary];
                    NSString *nickname = [extension respondsToSelector:@selector(getNickname:)] ? [extension getNickname:contact] : contact;
                    UIImage *avatar = [extension respondsToSelector:@selector(getAvatar:)] ? [extension getAvatar:contact] : nil;
                    if ([nickname isKindOfClass:NSString.class]) {
                        contactDictionary[@"nickname"] = nickname;
                    }
                    if ([avatar isKindOfClass:UIImage.class]) {
                        contactDictionary[@"avatar"] = avatar;
                    }
                    if ([contact isKindOfClass:NSString.class]) {
                        contactDictionary[@"identifier"] = contact;
                        [result addObject:contactDictionary];
                    }
                }];
                response = @{@"contacts": [NSKeyedArchiver archivedDataWithRootObject:result]};
            }
        } else if ([request isEqualToString:@"sendMessage"]) {
            CouriaMessage *message = [[CouriaMessage alloc]init];
            message.outgoing = YES;
            message.timestamp = [NSDate date];
            id content = [NSKeyedUnarchiver unarchiveObjectWithData:data[@"content"]];
            if ([content isKindOfClass:NSString.class] || [content isKindOfClass:NSURL.class]) {
                message.content = content;
                [extension sendMessage:message toUser:user];
            }
        } else if ([request isEqualToString:@"markRead"]) {
            if ([extension respondsToSelector:@selector(markRead:)]) {
                [extension markRead:user];
            }
            if ([extension respondsToSelector:@selector(shouldClearNotifications)] ? extension.shouldClearNotifications : NO) {
                BBDataProvider *dataProvider = [bbServer dataProviderForSectionID:application];
                NSSet *bulletins = [bbServer bulletinsRequestsForBulletinIDs:[bbServer allBulletinIDsForSectionID:application]];
                NSInteger remainingCount = 0;
                for (BBBulletinRequest *bulletin in bulletins) {
                    if ([[extension getUserIdentifier:bulletin]isEqualToString:user]) {
                        BBDataProviderWithdrawBulletinWithPublisherBulletinID(dataProvider, bulletin.publisherBulletinID);
                    } else {
                        remainingCount++;
                    }
                }
                BBDataProviderSetApplicationBadge(dataProvider, remainingCount);
            }
        }
    }
    return response;
}

- (NSDictionary *)processUIRequest:(NSString *)request data:(NSDictionary *)data
{
    NSDictionary *response;
    if ([request isEqualToString:@"updateBanner"]) {
        SBBannerContextView *bannerView = bannerController._bannerView;
        if (bannerView != nil) {
            SBDefaultBannerView * const *contentViewRef = CHIvarRef(bannerView, _contentView, SBDefaultBannerView * const);
            if (contentViewRef != NULL && *contentViewRef != nil) {
                SBDefaultBannerTextView * const *textViewRef = CHIvarRef(*contentViewRef, _textView, SBDefaultBannerTextView * const);
                if (textViewRef != NULL && *textViewRef != nil) {
                    SBDefaultBannerTextView *textView = *textViewRef;
                    textView.primaryText = data[@"primaryText"] ?: textView.primaryText;
                    textView.secondaryText = data[@"secondaryText"] ?: textView.secondaryText;
                }
            }
        }
    }
    return response;
}

@end
