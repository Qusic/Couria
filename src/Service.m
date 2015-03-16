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
        bannerController = (SBBannerController *)[NSClassFromString(@"SBBannerController") sharedInstance];
    });
    return sharedInstance;
}

- (void)run
{
    [messagingCenter runServerOnCurrentThread];
}

- (NSDictionary *)processRequest:(NSString *)request data:(NSDictionary *)data
{
    id<CouriaDataSource> dataSource; id<CouriaDelegate> delegate; NSString *user; NSDictionary *response;
    for (BOOL _valid = ({
        BOOL valid = NO;
        BBBulletin *bulletin = bannerController._bannerContext.item.seedBulletin;
        NSString *application = bulletin.sectionID;
        if (CouriaRegistered(application)) {
            dataSource = CouriaDataSource(application);
            delegate = CouriaDelegate(application);
            user = [dataSource getUserIdentifier:bulletin];
            valid = YES;
        }
        valid;
    }); _valid; _valid = NO) {
        if ([request isEqualToString:@"getMessages"]) {
            NSMutableArray *result = [NSMutableArray array];
            [[dataSource getMessages:user]enumerateObjectsUsingBlock:^(id<CouriaMessage> message, NSUInteger idx, BOOL *stop) {
                NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary];
                NSString *text = message.text;
                id media = message.media;
                BOOL outgoing = message.outgoing;
                NSDate *timestamp = [message respondsToSelector:@selector(timestamp)] ? message.timestamp : nil;
                if (text != nil && [text isKindOfClass:NSString.class]) {
                    messageDictionary[@"text"] = text;
                }
                if (media != nil && ([media isKindOfClass:UIImage.class] || [media isKindOfClass:NSURL.class])) {
                    messageDictionary[@"media"] = media;
                }
                messageDictionary[@"outgoing"] = @(outgoing);
                if (timestamp != nil && [timestamp isKindOfClass:NSDate.class]) {
                    messageDictionary[@"timestamp"] = timestamp;
                }
                [result addObject:messageDictionary];
            }];
            response = @{@"result": response};
        } else if ([request isEqualToString:@"getContacts"]) {
            NSMutableArray *result = [NSMutableArray array];
            [[dataSource getContacts:data[@"keyword"]]enumerateObjectsUsingBlock:^(NSString *contact, NSUInteger idx, BOOL *stop) {
                NSMutableDictionary *contactDictionary = [NSMutableDictionary dictionary];
                UIImage *avatar = [dataSource getAvatar:contact];
                if (contact != nil && [contact isKindOfClass:NSString.class]) {
                    contactDictionary[@"identifier"] = contact;
                }
                if (avatar != nil && [avatar isKindOfClass:UIImage.class]) {
                    contactDictionary[@"avatar"] = avatar;
                }
                [result addObject:contactDictionary];
            }];
            response = @{@"result": response};
        } else if ([request isEqualToString:@"sendMessage"]) {
            CouriaMessage *message = [[CouriaMessage alloc]init];
            message.text = data[@"text"];
            message.media = data[@"media"];
            message.outgoing = [data[@"outgoing"] boolValue];
            [delegate sendMessage:message toUser:user];
        } else if ([request isEqualToString:@"markRead"]) {
            [delegate markRead:user];
        } else if ([request isEqualToString:@"updateBanner"]) {
            SBBannerContextView *bannerView = bannerController._bannerView;
            if (bannerView != nil) {
                SBDefaultBannerView * const *contentViewRef = CHIvarRef(bannerView, _contentView, SBDefaultBannerView * const);
                if (contentViewRef != NULL && *contentViewRef != nil) {
                    SBDefaultBannerTextView * const *textViewRef = CHIvarRef(*contentViewRef, _textView, SBDefaultBannerTextView * const);
                    if (textViewRef != NULL && *textViewRef != nil) {
                        SBDefaultBannerTextView *textView = *textViewRef;
                        textView.primaryText = data[@"primaryText"];
                        textView.secondaryText = data[@"secondaryText"];
                    }
                }
            }
        }
    }
    return response;
}

@end
