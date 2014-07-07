#import "Headers.h"
#import <CaptainHook.h>
#import <sqlite3.h>
#import <sys/sysctl.h>

#pragma mark - Constants

static CFStringRef const MessagesExtensionIdentifier = CFSTR("me.qusic.couria.messagesextension");
static NSString * const SpringBoardIdentifier = @"com.apple.springboard";
static NSString * const MessagesIdentifier = @"com.apple.MobileSMS";
static NSString * const UserIDKey = @"UserID";
static NSString * const MessageKey = @"Message";

typedef NS_ENUM(SInt32, CouriaMessagesExtensionMessageID) {
    SendMessage,
        MarkRead
};

#pragma mark - Interfaces

@interface CouriaMessagesMessage : NSObject <CouriaMessage, NSSecureCoding>
@property(retain) NSString *text;
@property(retain) id media;
@property(assign) BOOL outgoing;
@property(retain) NSDate *timestamp;
@end

@interface CouriaMessagesDataSource : NSObject <CouriaDataSource>
@end

@interface CouriaMessagesDelegate : NSObject <CouriaDelegate>
@end

#pragma mark - Private APIs

@interface CKEntity : NSObject
@property(nonatomic,readonly) NSString *rawAddress;
@property(nonatomic,readonly) NSString *name;
@property(nonatomic,readonly) UIImage *transcriptContactImage;
+ (instancetype)copyEntityForAddressString:(NSString *)string;
@end

@protocol CKMessage <NSObject>
@end

@interface CKIMMessage : NSObject <CKMessage>
@end

@interface CKMediaObject : NSObject
@property(readonly, nonatomic) NSString *transferGUID;
@end

@interface CKMediaObjectManager : NSObject
+ (instancetype)sharedInstance;
- (CKMediaObject *)mediaObjectWithData:(NSData *)data UTIType:(NSString *)utiType filename:(NSString *)filename transcoderUserInfo:(id)transcoderUserInfo; // iOS 7
- (CKMediaObject *)mediaObjectWithFileURL:(NSURL *)url filename:(NSString *)filename transcoderUserInfo:(id)transcoderUserInfo; // iOS 7
- (CKMediaObject *)newMediaObjectForData:(NSData *)data mimeType:(NSString *)mimeType exportedFilename:(NSString *)exportedFilename; // iOS 6
- (CKMediaObject *)newMediaObjectForFilename:(NSString *)filename mimeType:(NSString *)mimeType exportedFilename:(NSString *)exportedFilename composeOptions:(id)composeOptions; // iOS 6
@end

@interface CKMessagePart : NSObject
- (NSAttributedString *)text;
- (CKMediaObject *)mediaObject;
@end

@interface CKTextMessagePart : CKMessagePart
@end

@interface CKMediaObjectMessagePart : CKMessagePart
- (instancetype)initWithMediaObject:(CKMediaObject *)mediaObject;
@end

@interface CKComposition : NSObject // iOS 7
+ (instancetype)compositionForMessageParts:(NSArray *)parts;
- (instancetype)initWithText:(NSAttributedString *)text subject:(NSAttributedString *)subject;
@end

@interface CKMessageComposition : NSObject // iOS 6
@property(retain, nonatomic) NSDictionary *resources;
@property(copy, nonatomic) NSString *markupString;
+ (instancetype)newComposition;
+ (instancetype)newCompositionForText:(NSString *)text;
@end

@interface CKConversation : NSObject
@property(nonatomic, readonly) NSString *name;
@property(retain, nonatomic) NSArray *recipients;
- (BOOL)canSendToRecipients:(NSArray *)ckimEntitys withAttachments:(NSArray *)messageParts alertIfUnable:(BOOL)alert;
- (BOOL)canSendMessageComposition:(CKComposition *)composition error:(NSError **)error;
- (CKIMMessage *)newMessageWithComposition:(CKComposition *)composition;
- (void)sendMessage:(CKIMMessage *)message newComposition:(BOOL)newComposition;
- (void)markAllMessagesAsRead;
@end

@interface CKConversationList : NSObject
+ (instancetype)sharedConversationList;
- (CKConversation *)conversationForRecipients:(NSArray *)recipients create:(BOOL)create;
- (CKConversation *)conversationForExistingChatWithGroupID:(NSString *)groupID;
@end

@interface CKPreferredServiceManager : NSObject
+ (instancetype)sharedPreferredServiceManager;
- (void)refreshAvailabilityForConversation:(CKConversation *)conversation;
- (id)preferredServiceForAddressString:(NSString *)addressString newComposition:(BOOL)newComposition checkWithServer:(BOOL)checkWithServer error:(NSError **)errpt;
@end

extern "C" NSString *IMStripFormattingFromAddress(NSString *formattedAddress);

#pragma mark - Functions

static NSArray *queryDB(sqlite3 *database, NSString *sqlString)
{
    sqlite3_stmt *statement;
    const char *query = sqlString.UTF8String;
    if (sqlite3_prepare_v2(database, query, -1, &statement, NULL) != SQLITE_OK) {
        return nil;
    }
    NSMutableArray *result = [NSMutableArray array];
    while (sqlite3_step(statement) == SQLITE_ROW) {
        NSMutableDictionary *row = [NSMutableDictionary dictionary];
        int columns = sqlite3_column_count(statement);
        for (int i = 0; i < columns; i++) {
            NSString *key = [NSString stringWithCString:sqlite3_column_name(statement, i) encoding:NSUTF8StringEncoding];
            id value;
            switch (sqlite3_column_type(statement, i)) {
                case SQLITE_TEXT:
                    value = [NSString stringWithCString:(const char *)sqlite3_column_text(statement, i) encoding:NSUTF8StringEncoding];
                    break;
                case SQLITE_INTEGER:
                    value = [NSNumber numberWithInt:sqlite3_column_int(statement, i)];
                    break;
                case SQLITE_FLOAT:
                    value = [NSNumber numberWithFloat:sqlite3_column_double(statement, i)];
                    break;
                case SQLITE_NULL:
                    value = [NSNull null];
                    break;
                default:
                    value = [NSNull null];
                    break;
            }
            row[key] = value;
        }
        [result addObject:row];
    }
    return result;
}

static NSArray *querySMSDB(NSString *sqlString)
{
    static sqlite3 *database;
    if (database == NULL) {
        sqlite3 *tmpDatabase;
        if (sqlite3_open(@"/private/var/mobile/Library/SMS/sms.db".UTF8String, &tmpDatabase) == SQLITE_OK) {
            database = tmpDatabase;
        } else {
            return nil;
        }
    }
    return queryDB(database, sqlString);
}

static NSArray *queryAddressBookDB(NSString *sqlString)
{
    static sqlite3 *database;
    if (database == NULL) {
        sqlite3 *tmpDatabase;
        if (sqlite3_open(@"/private/var/mobile/Library/AddressBook/AddressBook.sqlitedb".UTF8String, &tmpDatabase) == SQLITE_OK) {
            database = tmpDatabase;
        } else {
            return nil;
        }
    }
    return queryDB(database, sqlString);
}

static NSArray *getRecipients(NSString *userIdentifier)
{
    NSArray *dbRecipients = querySMSDB([NSString stringWithFormat:@"SELECT handle.id FROM handle INNER JOIN chat_handle_join ON handle.ROWID = chat_handle_join.handle_id INNER JOIN chat ON chat.ROWID = chat_handle_join.chat_id WHERE chat.chat_identifier = '%@' ORDER BY handle.ROWID", userIdentifier]);
    NSMutableArray *recipients = [NSMutableArray array];
    for (NSDictionary *dbRecipient in dbRecipients) {
        NSString *dbRecipientString = dbRecipient[@"id"];
        if (![recipients containsObject:dbRecipientString]) {
            [recipients addObject:dbRecipientString];
        }
    }
    if (recipients.count == 0) {
        [recipients addObject:userIdentifier];
    }
    return recipients;
}

static CKEntity *getEntity(NSString *userIdentifier)
{
    CKEntity *entity = nil;
    if (userIdentifier.length > 0) {
        entity = [CKEntity copyEntityForAddressString:userIdentifier];
    }
    return entity;
}

static CKConversation *getConversation(NSString *userIdentifier, BOOL create)
{
    static CKConversationList *conversationList;
    if (conversationList == nil) {
        conversationList = [CKConversationList sharedConversationList];
    }
    CKConversation *conversation = [conversationList conversationForExistingChatWithGroupID:userIdentifier];
    if (conversation == nil) {
        conversation = [conversationList conversationForRecipients:@[getEntity(userIdentifier)] create:create];
    }
    return conversation;
}

static CFMessagePortRef remotePort()
{
    static CFMessagePortRef port;
    if (!(port != NULL && CFMessagePortIsValid(port))) {
        port = CFMessagePortCreateRemote(kCFAllocatorDefault, MessagesExtensionIdentifier);
    }
    return port;
}

static BOOL appIsRunning()
{
    CFMessagePortRef port = remotePort();
    return port != NULL && CFMessagePortIsValid(port);
}

static void launchApp()
{
    while (appIsRunning() == NO) {
        dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication]launchApplicationWithIdentifier:MessagesIdentifier suspended:YES];
                });
        [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

static inline NSString *standardizedAddress(NSString *address)
{
    return IMStripFormattingFromAddress(address);
}

#pragma mark - Implementations

@implementation CouriaMessagesMessage

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    if (self) {
        _text = [aDecoder decodeObjectOfClass:NSString.class forKey:@"Text"];
        _outgoing = [[aDecoder decodeObjectOfClass:NSNumber.class forKey:@"Outgoing"]boolValue];
        _media = [aDecoder decodeObjectOfClasses:[NSSet setWithObjects:UIImage.class, NSURL.class, nil] forKey:@"Media"];
        _timestamp = [aDecoder decodeObjectOfClass:NSDate.class forKey:@"Timestamp"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_text forKey:@"Text"];
    [aCoder encodeObject:@(_outgoing) forKey:@"Outgoing"];
    [aCoder encodeObject:_media forKey:@"Media"];
    [aCoder encodeObject:_timestamp forKey:@"Timestamp"];
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@end

@implementation CouriaMessagesDataSource

- (NSString *)getUserIdentifier:(BBBulletin *)bulletin
{
    NSString *messageId = bulletin.context[@"AssistantContext"][@"identifier"];
    messageId = [messageId stringByReplacingOccurrencesOfString:@"x-apple-sms:guid=(\\d+)" withString:@"$1" options:NSRegularExpressionSearch range:NSMakeRange(0, messageId.length)];
    NSString *chatId = querySMSDB([NSString stringWithFormat:@"SELECT chat.chat_identifier FROM chat INNER JOIN chat_message_join ON chat.ROWID = chat_message_join.chat_id INNER JOIN message ON message.ROWID = chat_message_join.message_id WHERE message.ROWID = %@", messageId]).firstObject[@"chat_identifier"];
    return chatId;
}

- (NSString *)getNickname:(NSString *)userIdentifier
{
    NSArray *recipients = getRecipients(userIdentifier);
    NSUInteger count = recipients.count;
    NSMutableString *nickname = [NSMutableString string];
    if (count == 1) {
        [nickname appendString:getEntity(recipients.firstObject).name];
    } else {
        [recipients enumerateObjectsUsingBlock:^(NSString *recipient, NSUInteger index, BOOL *stop) {
            if (nickname.length > 0) {
                [nickname appendString:(index == count - 1) ? @" & " : @", "];
            }
            [nickname appendString:getEntity(recipient).name];
        }];
    }
    return nickname;
}

- (UIImage *)getAvatar:(NSString *)userIdentifier
{
    NSArray *recipients = getRecipients(userIdentifier);
    NSUInteger count = recipients.count;
    UIImage *avatar = nil;
    if (count == 1) {
        avatar = getEntity(recipients.firstObject).transcriptContactImage;
    } else {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(27, 27), NO, 0.0);
        if (count == 2) {
            [getEntity(recipients[0]).transcriptContactImage drawInRect:CGRectMake( 0,  0, 15, 15)];
            [getEntity(recipients[1]).transcriptContactImage drawInRect:CGRectMake(12, 12, 15, 15)];
        } else if (count == 3) {
            [getEntity(recipients[0]).transcriptContactImage drawInRect:CGRectMake( 7,  1, 13, 13)];
            [getEntity(recipients[1]).transcriptContactImage drawInRect:CGRectMake( 0, 13, 13, 13)];
            [getEntity(recipients[2]).transcriptContactImage drawInRect:CGRectMake(14, 13, 13, 13)];
        } else {
            [getEntity(recipients[0]).transcriptContactImage drawInRect:CGRectMake( 0,  0, 13, 13)];
            [getEntity(recipients[1]).transcriptContactImage drawInRect:CGRectMake(14,  0, 13, 13)];
            [getEntity(recipients[2]).transcriptContactImage drawInRect:CGRectMake( 0, 14, 13, 13)];
            [getEntity(recipients[3]).transcriptContactImage drawInRect:CGRectMake(14, 14, 13, 13)];
        }
        avatar = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return avatar;
}

- (NSArray *)getMessages:(NSString *)userIdentifier
{
    BOOL groupMessages = getRecipients(userIdentifier).count > 1;
    NSMutableArray *messages = [NSMutableArray array];
    NSArray *dbMessages = querySMSDB([NSString stringWithFormat:@"SELECT handle.id, message.ROWID, message.text, message.is_from_me, message.date, message.cache_has_attachments FROM message INNER JOIN chat_message_join ON message.ROWID = chat_message_join.message_id INNER JOIN chat ON chat.ROWID = chat_message_join.chat_id LEFT JOIN handle ON handle.ROWID = message.handle_id WHERE chat.chat_identifier = '%@' ORDER BY message.ROWID DESC LIMIT 20", userIdentifier]);
    NSTimeInterval lastDate = 0;
    for (NSDictionary *dbMessage in dbMessages.reverseObjectEnumerator) {
        id handleId = dbMessage[@"id"];
        NSString *text = dbMessage[@"text"];
        text = [text stringByReplacingOccurrencesOfString:@"\ufffc" withString:@""];
        text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        BOOL outgoing = [dbMessage[@"is_from_me"]boolValue];
        BOOL hasAttachments = [dbMessage[@"cache_has_attachments"]boolValue];
        NSTimeInterval date = [dbMessage[@"date"]doubleValue];
        if (text.length > 0) {
            CouriaMessagesMessage *message = [[CouriaMessagesMessage alloc]init];
            message.text = text;
            message.outgoing = outgoing;
            if (groupMessages && !outgoing && [handleId isKindOfClass:NSString.class]) {
                message.text = [NSString stringWithFormat:@"%@: %@", getEntity(handleId).name, text];
            }
            if (round(date - lastDate) >= 60) {
                message.timestamp = [NSDate dateWithTimeIntervalSinceReferenceDate:date];
                lastDate = date;
            }
            [messages addObject:message];
        }
        if (hasAttachments) {
            NSArray *dbAttachments = querySMSDB([NSString stringWithFormat:@"SELECT attachment.filename, attachment.mime_type FROM attachment INNER JOIN message_attachment_join ON attachment.ROWID = message_attachment_join.attachment_id WHERE message_id = %@", dbMessage[@"ROWID"]]);
            for (NSDictionary *dbAttachment in dbAttachments) {
                NSString *filename = [dbAttachment[@"filename"]stringByExpandingTildeInPath];
                NSString *mimeType = dbAttachment[@"mime_type"];
                CouriaMessagesMessage *message = [[CouriaMessagesMessage alloc]init];
                if ([mimeType hasPrefix:@"image"]) {
                    message.media = [UIImage imageWithContentsOfFile:filename];
                } else if ([mimeType hasPrefix:@"video"]) {
                    message.media = [NSURL fileURLWithPath:filename];
                } else {
                    continue;
                }
                message.outgoing = outgoing;
                [messages addObject:message];
            }
        }
    }
    return messages;
}

- (NSArray *)getContacts:(NSString *)keyword
{
    if (keyword.length == 0) {
        static NSMutableArray *recentContacts;
        static NSDate *lastRefreshRecent;
        if (lastRefreshRecent == nil || [[NSDate date]timeIntervalSinceDate:lastRefreshRecent] > 10) {
            recentContacts = [NSMutableArray array];
            NSArray *dbRecentContacts = querySMSDB(@"SELECT chat.chat_identifier, MAX(chat_message_join.message_id) FROM chat, chat_message_join WHERE chat.ROWID = chat_message_join.chat_id GROUP BY chat.ROWID ORDER BY chat_message_join.message_id DESC");
            for (NSDictionary *dbRecentContact in dbRecentContacts) {
                [recentContacts addObject:dbRecentContact[@"chat_identifier"]];
            }
            lastRefreshRecent = [NSDate date];
        }
        return recentContacts;
    } else {
        static SPSearchAgent *searchAgent;
        if (searchAgent == nil) {
            searchAgent = [[SPSearchAgent alloc]init];
            searchAgent.searchDomains = @[@(2)];
        }
        searchAgent.queryString = keyword;
        while (!searchAgent.queryComplete) {
            [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        }
        NSMutableSet *resultContacts = [NSMutableSet set];
        if (searchAgent.resultCount > 0 && [[searchAgent sectionAtIndex:0].displayIdentifier isEqualToString:@"com.apple.mobilephone"]) {
            for (SPSearchResult *agentResult in [searchAgent sectionAtIndex:0].results) {
                NSArray *dbResults = queryAddressBookDB([NSString stringWithFormat:@"SELECT value FROM ABMultiValue WHERE record_id = %lu AND (property = 3 or property = 4)", (unsigned long)agentResult.identifier]);
                for (NSDictionary *dbResult in dbResults) {
                    [resultContacts addObject:standardizedAddress(dbResult[@"value"])];
                }
            }
        } else {
            [resultContacts addObject:standardizedAddress(keyword)];
        }
        return resultContacts.allObjects;
    }
    return nil;
}

@end

@implementation CouriaMessagesDelegate

- (void)sendMessage:(id<CouriaMessage>)message toUser:(NSString *)userIdentifier
{
    if (!appIsRunning()) {
        launchApp();
        [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    CouriaMessagesMessage *couriaMessage = [[CouriaMessagesMessage alloc]init];
    couriaMessage.text = message.text;
    couriaMessage.media = message.media;
    couriaMessage.outgoing = message.outgoing;
    CFDataRef data = (__bridge CFDataRef)[NSKeyedArchiver archivedDataWithRootObject:@{UserIDKey: userIdentifier, MessageKey: couriaMessage}];
    CFMessagePortSendRequest(remotePort(), SendMessage, data, 30, 30, NULL, NULL);
}

- (void)markRead:(NSString *)userIdentifier
{
    if (!appIsRunning()) {
        launchApp();
        [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    CFDataRef data = (__bridge CFDataRef)[userIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    CFMessagePortSendRequest(remotePort(), MarkRead, data, 30, 30, NULL, NULL);
}

- (BOOL)canSendPhoto
{
    return YES;
}

- (BOOL)canSendMovie
{
    return NO;
}

- (BOOL)shouldClearReadNotifications
{
    return NO;
}

- (BOOL)shouldDecreaseBadgeNumber
{
    return NO;
}

@end

#pragma mark - Service

static CFDataRef CouriaMessagesServiceCallback(CFMessagePortRef local, SInt32 messageId, CFDataRef data, void *info)
{
    CFDataRef returnData = NULL;
    switch (messageId) {
        case SendMessage: {
            NSDictionary *messageDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)data];
            NSString *userIdentifier = messageDictionary[UserIDKey];
            CouriaMessagesMessage *message = messageDictionary[MessageKey];
            NSString *text = message.text;
            id media = message.media;
            [[NSOperationQueue mainQueue]addOperationWithBlock:^{
                NSMutableArray *compositions = [NSMutableArray array];
                Class CompositionClass = NSClassFromString(iOS7() ? @"CKComposition" : @"CKMessageComposition");
                if (text.length > 0) {
                    if (iOS7()) {
                        CKComposition *composition = [[CompositionClass alloc]initWithText:[[NSAttributedString alloc]initWithString:text]subject:nil];
                        [compositions addObject:composition];
                    } else {
                        CKMessageComposition *composition = [CompositionClass newCompositionForText:text];
                        [compositions addObject:composition];
                    }
                }
                if (media != nil) {
                    if (iOS7()) {
                        CKMediaObject *mediaObject = nil;
                        if ([media isKindOfClass:UIImage.class]) {
                            mediaObject = [[CKMediaObjectManager sharedInstance]mediaObjectWithData:UIImagePNGRepresentation(media) UTIType:@"public.png" filename:nil transcoderUserInfo:nil];
                        } else if ([media isKindOfClass:NSURL.class]) {
                            mediaObject = [[CKMediaObjectManager sharedInstance]mediaObjectWithFileURL:media filename:nil transcoderUserInfo:nil];
                        }
                        if (mediaObject != nil) {
                            CKMediaObjectMessagePart *part = [[CKMediaObjectMessagePart alloc]initWithMediaObject:mediaObject];
                            CKComposition *composition = [CKComposition compositionForMessageParts:@[part]];
                            [compositions addObject:composition];
                        }
                    } else {
                        CKMediaObject *mediaObject = nil;
                        if ([media isKindOfClass:UIImage.class]) {
                            mediaObject = [[CKMediaObjectManager sharedInstance]newMediaObjectForData:UIImagePNGRepresentation(media) mimeType:@"image/png" exportedFilename:nil];
                        } else if ([media isKindOfClass:NSURL.class]) {
                            mediaObject = [[CKMediaObjectManager sharedInstance]newMediaObjectForFilename:[media absoluteString] mimeType:@"video/quicktime" exportedFilename:nil composeOptions:nil];
                        }
                        if (mediaObject != nil) {
                            NSString *transferGUID = mediaObject.transferGUID;
                            CKMediaObjectMessagePart *part = [[CKMediaObjectMessagePart alloc]initWithMediaObject:mediaObject];
                            CKMessageComposition *composition = [CompositionClass newComposition];
                            composition.resources = @{transferGUID: part};
                            composition.markupString = [NSString stringWithFormat:@"<img id=\"%@\" style=\"display:block;margin-left:-6px;padding-top:5px;padding-bottom:3px\" width=\"100px\" height=\"100px\" src=\"x-ckmsgpart:0/%@/0\">", transferGUID, transferGUID];
                            [compositions addObject:composition];
                        }
                    }
                }
                CKConversation *conversation = getConversation(userIdentifier, YES);

                for (CKComposition *composition in compositions) {
                    CKIMMessage *message = [conversation newMessageWithComposition:composition];
                    [conversation sendMessage:message newComposition:YES];
                }
            }];
            break;
        }
        case MarkRead: {
            NSString *userIdentifier = [[NSString alloc]initWithData:(__bridge NSData *)data encoding:NSUTF8StringEncoding];
            [[NSOperationQueue mainQueue]addOperationWithBlock:^{
                CKConversation *conversation = getConversation(userIdentifier, NO);
                CKPreferredServiceManager *preferedServiceManager = [CKPreferredServiceManager sharedPreferredServiceManager];
                if (conversation != nil) {
                    [conversation markAllMessagesAsRead];
                    [preferedServiceManager refreshAvailabilityForConversation:conversation];
                } else {
                    [preferedServiceManager preferredServiceForAddressString:userIdentifier newComposition:YES checkWithServer:YES error:NULL];
                }
            }];
            break;
       }
    }
    return returnData;
}

@interface CouriaMessagesService : NSThread
@property(assign) CFMessagePortRef localPort;
@end

@implementation CouriaMessagesService

- (void)main
{
    _localPort = CFMessagePortCreateLocal(kCFAllocatorDefault, MessagesExtensionIdentifier, CouriaMessagesServiceCallback, NULL, NULL);
    CFRunLoopSourceRef source = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, _localPort, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
    CFRunLoopRun();
}

@end

#pragma mark - Hooks

CHDeclareClass(SpringBoard);

CHInline static BOOL handleURL(NSURL *url) {
    if ([url.scheme isEqualToString:@"sms"]) {
        NSString *address = standardizedAddress(url.resourceSpecifier.stringByRemovingPercentEncoding);
        [[NSClassFromString(@"Couria")sharedInstance]presentControllerForApplication:MessagesIdentifier user:address];
        return YES;
    } else {
        return NO;
    }
}

CHOptimizedMethod(6, self, void, SpringBoard, _openURLCore, NSURL *, url, display, id, display, animating, BOOL, animating, sender, id, sender, activationContext, id, context, activationHandler, id, handler)
{
    if (!handleURL(url)) {
        CHSuper(6, SpringBoard, _openURLCore, url, display, display, animating, animating, sender, sender, activationContext, context, activationHandler, handler);
    }
}

CHOptimizedMethod(6, self, void, SpringBoard, _openURLCore, NSURL *, url, display, id, display, animating, BOOL, animating, sender, id, sender, additionalActivationFlags, id, flags, activationHandler, id, handler)
{
    if (!handleURL(url)) {
        CHSuper(6, SpringBoard, _openURLCore, url, display, display, animating, animating, sender, sender, additionalActivationFlags, flags, activationHandler, handler);
    }
}

CHOptimizedMethod(5, self, void, SpringBoard, _openURLCore, NSURL *, url, display, id, display, animating, BOOL, animating, sender, id, sender, additionalActivationFlags, id, flags)
{
    if (!handleURL(url)) {
        CHSuper(5, SpringBoard, _openURLCore, url, display, display, animating, animating, sender, sender, additionalActivationFlags, flags);
    }
}

#pragma mark - Constructor

CHConstructor
{
    @autoreleasepool {
        NSString *application = [NSBundle mainBundle].bundleIdentifier;
        if ([application isEqualToString:SpringBoardIdentifier]) {
            [[NSClassFromString(@"Couria")sharedInstance]registerDataSource:[CouriaMessagesDataSource new] delegate:[CouriaMessagesDelegate new] forApplication:MessagesIdentifier];
        } else if ([application isEqualToString:MessagesIdentifier]) {
            [[[CouriaMessagesService alloc]init]start];
        }
        CHLoadLateClass(SpringBoard);
        CHHook(6, SpringBoard, _openURLCore, display, animating, sender, activationContext, activationHandler);
        CHHook(6, SpringBoard, _openURLCore, display, animating, sender, additionalActivationFlags, activationHandler);
        CHHook(5, SpringBoard, _openURLCore, display, animating, sender, additionalActivationFlags);
    }
}
