#import "../Headers.h"

static CPDistributedMessagingCenter *messagingCenter;

CHDeclareClass(SBBannerController)
CHDeclareClass(BBServer)

@implementation CouriaService

+ (instancetype)sharedInstance
{
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc]init];
        messagingCenter = [CPDistributedMessagingCenter centerNamed:CouriaIdentifier];
        CHLoadLateClass(SBBannerController);
        CHLoadClass(BBServer);
    });
    return sharedInstance;
}

- (void)run
{
    [messagingCenter runServerOnCurrentThread];
    [messagingCenter registerForMessageName:GetMessagesMessage target:self selector:@selector(processExtensionRequest:data:)];
    [messagingCenter registerForMessageName:GetContactsMessage target:self selector:@selector(processExtensionRequest:data:)];
    [messagingCenter registerForMessageName:SendMessageMessage target:self selector:@selector(processExtensionRequest:data:)];
    [messagingCenter registerForMessageName:MarkReadMessage target:self selector:@selector(processExtensionRequest:data:)];
    [messagingCenter registerForMessageName:ListExtensionsMessage target:self selector:@selector(processMiscellaneousRequest:data:)];
    [messagingCenter registerForMessageName:UpdateBannerMessage target:self selector:@selector(processMiscellaneousRequest:data:)];
}

- (NSDictionary *)processExtensionRequest:(NSString *)request data:(NSDictionary *)data
{
    id<CouriaExtension> extension; NSString *application; NSString *user; NSDictionary *response;
    for (BOOL _valid = ({
        BOOL valid = NO;
        if (CouriaEnabled(application = data[ApplicationKey])) {
            extension = CouriaExtension(application);
            user = data[UserKey];
            valid = YES;
        }
        valid;
    }); _valid; _valid = NO) {
        if ([request isEqualToString:GetMessagesMessage]) {
            if ([extension respondsToSelector:@selector(getMessages:)]) {
                NSMutableArray *result = [NSMutableArray array];
                [[extension getMessages:user]enumerateObjectsUsingBlock:^(id<CouriaMessage> message, NSUInteger idx, BOOL *stop) {
                    NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary];
                    id content = message.content;
                    BOOL outgoing = message.outgoing;
                    NSDate *timestamp = [message respondsToSelector:@selector(timestamp)] ? message.timestamp : nil;
                    messageDictionary[OutgoingKey] = @(outgoing);
                    if ([timestamp isKindOfClass:NSDate.class]) {
                        messageDictionary[TimestampKey] = timestamp;
                    }
                    if ([content isKindOfClass:NSString.class] || [content isKindOfClass:NSURL.class]) {
                        messageDictionary[ContentKey] = content;
                        [result addObject:messageDictionary];
                    }
                }];
                response = @{MessagesKey: [NSKeyedArchiver archivedDataWithRootObject:result]};
            }
        } else if ([request isEqualToString:GetContactsMessage]) {
            if ([extension respondsToSelector:@selector(getContacts:)]) {
                NSMutableArray *result = [NSMutableArray array];
                [[extension getContacts:data[KeywordKey]]enumerateObjectsUsingBlock:^(NSString *contact, NSUInteger idx, BOOL *stop) {
                    NSMutableDictionary *contactDictionary = [NSMutableDictionary dictionary];
                    NSString *nickname = [extension respondsToSelector:@selector(getNickname:)] ? [extension getNickname:contact] : contact;
                    UIImage *avatar = [extension respondsToSelector:@selector(getAvatar:)] ? [extension getAvatar:contact] : nil;
                    if ([nickname isKindOfClass:NSString.class]) {
                        contactDictionary[NicknameKey] = nickname;
                    }
                    if ([avatar isKindOfClass:UIImage.class]) {
                        contactDictionary[AvatarKey] = avatar;
                    }
                    if ([contact isKindOfClass:NSString.class]) {
                        contactDictionary[IdentifierKey] = contact;
                        [result addObject:contactDictionary];
                    }
                }];
                response = @{ContactsKey: [NSKeyedArchiver archivedDataWithRootObject:result]};
            }
        } else if ([request isEqualToString:SendMessageMessage]) {
            CouriaMessage *message = [[CouriaMessage alloc]init];
            message.outgoing = YES;
            message.timestamp = [NSDate date];
            id content = [NSKeyedUnarchiver unarchiveObjectWithData:data[ContentKey]];
            if ([content isKindOfClass:NSString.class] || [content isKindOfClass:NSURL.class]) {
                message.content = content;
                [extension sendMessage:message toUser:user];
            }
        } else if ([request isEqualToString:MarkReadMessage]) {
            if ([extension respondsToSelector:@selector(markRead:)]) {
                [extension markRead:user];
            }
            if ([extension respondsToSelector:@selector(shouldClearNotifications)] ? extension.shouldClearNotifications : NO) {
                dispatch_sync(__BBServerQueue, ^{
                    BBServer *bbServer = CHSharedInstance(BBServer);
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
                });
            }
        }
    }
    return response;
}

- (NSDictionary *)processMiscellaneousRequest:(NSString *)request data:(NSDictionary *)data
{
    NSDictionary *response;
    if ([request isEqualToString:ListExtensionsMessage]) {
        NSMutableArray *result = [NSMutableArray array];
        NSMutableArray *applicationIdentifiers = [NSMutableArray arrayWithObject:MobileSMSIdentifier];
        [applicationIdentifiers addObjectsFromArray:CouriaExtensions().allKeys];
        [applicationIdentifiers enumerateObjectsUsingBlock:^(NSString *applicationIdentifier, NSUInteger index, BOOL *stop) {
            [result addObject:@{
                IdentifierKey: applicationIdentifier,
                NameKey: CouriaApplicationName(applicationIdentifier),
                IconKey: CouriaApplicationIcon(applicationIdentifier, YES)
            }];
        }];
        response = @{ExtensionsKey: [NSKeyedArchiver archivedDataWithRootObject:result]};
    } else if ([request isEqualToString:UpdateBannerMessage]) {
        SBBannerContextView *bannerView = CHSharedInstance(SBBannerController)._bannerView;
        if (bannerView != nil) {
            SBDefaultBannerView * const *contentViewRef = CHIvarRef(bannerView, _contentView, SBDefaultBannerView * const);
            if (contentViewRef != NULL && *contentViewRef != nil) {
                SBDefaultBannerTextView * const *textViewRef = CHIvarRef(*contentViewRef, _textView, SBDefaultBannerTextView * const);
                if (textViewRef != NULL && *textViewRef != nil) {
                    SBDefaultBannerTextView *textView = *textViewRef;
                    textView.primaryText = data[PrimaryTextKey] ?: textView.primaryText;
                    textView.secondaryText = data[SecondaryTextKey] ?: textView.secondaryText;
                    [textView setNeedsLayout];
                    [textView layoutIfNeeded];
                }
            }
        }
    }
    return response;
}

@end
