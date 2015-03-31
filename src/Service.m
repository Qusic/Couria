#import "Headers.h"

static CPDistributedMessagingCenter *messagingCenter;
static SBBannerController *bannerController;

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
    id<CouriaDataSource> dataSource; id<CouriaDelegate> delegate; NSString *user; id response;
    for (BOOL _valid = ({
        BOOL valid = NO;
        NSString *application = data[@"application"];
        if (CouriaRegistered(application)) {
            dataSource = CouriaDataSource(application);
            delegate = CouriaDelegate(application);
            user = data[@"user"];
            valid = YES;
        }
        valid;
    }); _valid; _valid = NO) {
        if ([request isEqualToString:@"getMessages"]) {
            NSMutableArray *result = [NSMutableArray array];
            [[dataSource getMessages:user]enumerateObjectsUsingBlock:^(id<CouriaMessage> message, NSUInteger idx, BOOL *stop) {
                NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary];
                id content = message.content;
                BOOL outgoing = message.outgoing;
                NSDate *timestamp = [message respondsToSelector:@selector(timestamp)] ? message.timestamp : nil;
                messageDictionary[@"outgoing"] = @(outgoing);
                if ([timestamp isKindOfClass:NSDate.class]) {
                    messageDictionary[@"timestamp"] = timestamp;
                }
                if ([content isKindOfClass:NSString.class] || [content isKindOfClass:UIImage.class] || [content isKindOfClass:NSURL.class]) {
                    messageDictionary[@"content"] = content;
                    [result addObject:messageDictionary];
                }
            }];
            response = result;
        } else if ([request isEqualToString:@"getContacts"]) {
            NSMutableArray *result = [NSMutableArray array];
            [[dataSource getContacts:data[@"keyword"]]enumerateObjectsUsingBlock:^(NSString *contact, NSUInteger idx, BOOL *stop) {
                NSMutableDictionary *contactDictionary = [NSMutableDictionary dictionary];
                NSString *nickname = [dataSource respondsToSelector:@selector(getNickname:)] ? [dataSource getNickname:contact] : contact;
                UIImage *avatar = [dataSource respondsToSelector:@selector(getAvatar:)] ? [dataSource getAvatar:contact] : nil;
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
            response = result;
        } else if ([request isEqualToString:@"sendMessage"]) {
            CouriaMessage *message = [[CouriaMessage alloc]init];
            message.outgoing = [data[@"outgoing"] boolValue];
            id content = data[@"content"];
            if ([content isKindOfClass:NSString.class] || [content isKindOfClass:UIImage.class] || [content isKindOfClass:NSURL.class]) {
                message.content = content;
                [delegate sendMessage:message toUser:user];
            }
        } else if ([request isEqualToString:@"markRead"]) {
            [delegate markRead:user];
        }
    }
    return response ? @{@"data": [NSKeyedArchiver archivedDataWithRootObject:response]} : nil;
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
