#import "Headers.h"

static NSXPCInterface *exportedInterface;
static SBBannerController *bannerController;

#define processRequest() \
    id<CouriaDataSource> dataSource; id<CouriaDelegate> delegate; NSString *user; \
    for (BOOL _valid = ({ \
        BOOL valid = NO; \
        BBBulletin *bulletin = bannerController._bannerContext.item.seedBulletin; \
        NSString *application = bulletin.sectionID; \
        if (CouriaRegistered(application)) { \
            dataSource = CouriaDataSource(application); \
            delegate = CouriaDelegate(application); \
            user = [dataSource getUserIdentifier:bulletin]; \
            valid = YES; \
        } \
        valid; \
    }); _valid; _valid = NO)

CHDeclareClass(NCInteractiveNotificationHostViewController)

CHOptimizedClassMethod(0, self, NSXPCInterface *, NCInteractiveNotificationHostViewController, exportedInterface)
{
    return exportedInterface;
}

CHOptimizedMethod(2, new, void, NCInteractiveNotificationHostViewController, _Couria_getMessages, NSDictionary *, userInfo, callback, CouriaXPCCallback, callback)
{
    processRequest() {
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
        callback(result);
    }
}

CHOptimizedMethod(2, new, void, NCInteractiveNotificationHostViewController, _Couria_getContacts, NSDictionary *, userInfo, callback, CouriaXPCCallback, callback)
{
    processRequest() {
        NSMutableArray *result = [NSMutableArray array];
        [[dataSource getContacts:userInfo[@"keyword"]]enumerateObjectsUsingBlock:^(NSString *contact, NSUInteger idx, BOOL *stop) {
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
        callback(result);
    }
}

CHOptimizedMethod(1, new, void, NCInteractiveNotificationHostViewController, _Couria_sendMessage, NSDictionary *, userInfo)
{
    processRequest() {
        CouriaMessage *message = [[CouriaMessage alloc]init];
        message.text = userInfo[@"text"];
        message.media = userInfo[@"media"];
        message.outgoing = [userInfo[@"outgoing"] boolValue];
        [delegate sendMessage:message toUser:user];
    }
}

CHOptimizedMethod(1, new, void, NCInteractiveNotificationHostViewController, _Couria_markRead, NSDictionary *, userInfo)
{
    processRequest() {
        [delegate markRead:user];
    }
}

CHOptimizedMethod(1, new, void, NCInteractiveNotificationHostViewController, _Couria_updateBanner, NSDictionary *, userInfo)
{
    SBBannerContextView *bannerView = bannerController._bannerView;
    if (bannerView != nil) {
        SBDefaultBannerView * const *contentViewRef = CHIvarRef(bannerView, _contentView, SBDefaultBannerView * const);
        if (contentViewRef != NULL && *contentViewRef != nil) {
            SBDefaultBannerTextView * const *textViewRef = CHIvarRef(*contentViewRef, _textView, SBDefaultBannerTextView * const);
            if (textViewRef != NULL && *textViewRef != nil) {
                SBDefaultBannerTextView *textView = *textViewRef;
                textView.primaryText = userInfo[@"primaryText"];
                textView.secondaryText = userInfo[@"secondaryText"];
            }
        }
    }
}

CHConstructor
{
    @autoreleasepool {
        Protocol *protocol = objc_allocateProtocol("CouriaInteractiveNotificationHostInterface");
        protocol_addProtocol(protocol, objc_getProtocol("NCInteractiveNotificationHostInterface"));
        protocol_addProtocol(protocol, @protocol(CouriaInteractiveNotificationHostInterface_));
        objc_registerProtocol(protocol);
        class_addProtocol(NCInteractiveNotificationHostViewController.class, protocol);
        exportedInterface = [NSXPCInterface interfaceWithProtocol:protocol];
        bannerController = (SBBannerController *)[NSClassFromString(@"SBBannerController") sharedInstance];
        CHLoadClass(NCInteractiveNotificationHostViewController);
        CHHook(0, NCInteractiveNotificationHostViewController, exportedInterface);
        CHHook(2, NCInteractiveNotificationHostViewController, _Couria_getMessages, callback);
        CHHook(2, NCInteractiveNotificationHostViewController, _Couria_getContacts, callback);
        CHHook(1, NCInteractiveNotificationHostViewController, _Couria_sendMessage);
        CHHook(1, NCInteractiveNotificationHostViewController, _Couria_markRead);
        CHHook(1, NCInteractiveNotificationHostViewController, _Couria_updateBanner);
    }
}
