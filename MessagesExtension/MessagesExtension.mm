#import <substrate.h>
#import <sqlite3.h>
#import <sys/sysctl.h>
#import "Couria.h"

#pragma mark - Constants

static CFStringRef const MessagesExtensionIdentifier = CFSTR("me.qusic.couria.messagesextension");
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

@interface IMPerson : NSObject
@property(readonly, nonatomic) NSString *name;
@property(readonly, nonatomic) NSString *fullName;
@property(readonly, nonatomic) NSString *companyName;
@property(nonatomic) NSArray *phoneNumbers;
@property(copy, nonatomic) NSArray *emails;
+ (NSArray *)allPeople;
@end

@interface IMHandle : NSObject
@property(readonly, nonatomic) NSString *ID;
+ (NSArray *)imHandlesForIMPerson:(IMPerson *)persons;
@end

@interface IMService : NSObject
+ (instancetype)smsService;
+ (instancetype)iMessageService;
@end

@interface CKEntity : NSObject
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
- (NSInteger)availabilityForAddress:(NSString *)address onService:(IMService *)service checkWithServer:(BOOL)checkWithServer;
- (IMService *)preferredServiceForAddressString:(NSString *)address newComposition:(BOOL)newComposition checkWithServer:(BOOL)checkWithServer error:(NSError **)error;
@end

#pragma mark - Functions

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

static IMService *getService(NSString *userIdentifier)
{
    static CKPreferredServiceManager *serviceManager;
    static IMService *imessageService;
    if (serviceManager == nil) {
        serviceManager = [CKPreferredServiceManager sharedPreferredServiceManager];
        imessageService = [IMService iMessageService];
    }
    while ([serviceManager availabilityForAddress:userIdentifier onService:imessageService checkWithServer:NO] == -1) {
        [serviceManager availabilityForAddress:userIdentifier onService:imessageService checkWithServer:YES];
        [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    IMService *service = [serviceManager preferredServiceForAddressString:userIdentifier newComposition:YES checkWithServer:NO error:nil];
    return service;
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

static inline BOOL stringContainsString(NSString *string1, NSString *string2, BOOL caseSensitive)
{
    if (string1 && string2) {
        return [string1 rangeOfString:string2 options:caseSensitive ? 0 : NSCaseInsensitiveSearch].location != NSNotFound;
    } else {
        return NO;
    }
}

static inline NSString *uncanonicalizedPhoneNumber(NSString *phoneNumber)
{
    return stringContainsString(phoneNumber, @"@", NO) ? phoneNumber : [phoneNumber stringByReplacingOccurrencesOfString:@"[- ()]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, phoneNumber.length)];
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
    return bulletin.context[@"contactInfo"];
}

- (NSString *)getNickname:(NSString *)userIdentifier
{
    CKEntity *entity = getEntity(userIdentifier);
    return entity ? entity.name : userIdentifier;
}

- (UIImage *)getAvatar:(NSString *)userIdentifier
{
    CKEntity *entity = getEntity(userIdentifier);
    return entity.transcriptContactImage;
}

- (NSArray *)getMessages:(NSString *)userIdentifier
{
    NSMutableArray *messages = [NSMutableArray array];
    NSArray *dbMessages = querySMSDB([NSString stringWithFormat:@"SELECT ROWID, text, is_from_me, date, cache_has_attachments FROM message WHERE handle_id IN (SELECT ROWID FROM handle WHERE id = '%@') ORDER BY ROWID DESC LIMIT 20;", userIdentifier]);
    NSTimeInterval lastDate = 0;
    for (NSDictionary *dbMessage in dbMessages.reverseObjectEnumerator) {
        NSString *text = [dbMessage[@"text"]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        BOOL outgoing = [dbMessage[@"is_from_me"]boolValue];
        BOOL hasAttachments = [dbMessage[@"cache_has_attachments"]boolValue];
        NSTimeInterval date = [dbMessage[@"date"]doubleValue];
        if (text.length > 0 && ((signed char)[text cStringUsingEncoding:NSUTF8StringEncoding][0]) != -17) {
            CouriaMessagesMessage *message = [[CouriaMessagesMessage alloc]init];
            message.text = text;
            message.outgoing = outgoing;
            if (round(date - lastDate) >= 60) {
                message.timestamp = [NSDate dateWithTimeIntervalSinceReferenceDate:date];
                lastDate = date;
            }
            [messages addObject:message];
        }
        if (hasAttachments) {
            NSArray *dbAttachments = querySMSDB([NSString stringWithFormat:@"SELECT filename, mime_type FROM attachment WHERE ROWID IN (SELECT attachment_id FROM message_attachment_join WHERE message_id = '%@');", dbMessage[@"ROWID"]]);
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
    static NSMutableArray *recentContacts;
    static NSDate *lastRefreshRecent;
    static NSArray *allPersons;
    static NSDate *lastRefreshAll;
    if (keyword.length == 0) {
        if (lastRefreshRecent == nil || [[NSDate date]timeIntervalSinceDate:lastRefreshRecent] > 10) {
            recentContacts = [NSMutableArray array];
            NSArray *dbRecentContacts = querySMSDB(@"SELECT handle.id, MAX(message.ROWID) FROM handle, message WHERE handle.ROWID = message.handle_id GROUP BY handle.id ORDER BY message.ROWID DESC");
            for (NSDictionary *dbRecentContact in dbRecentContacts) {
                [recentContacts addObject:dbRecentContact[@"id"]];
            }
            lastRefreshRecent = [NSDate date];
        }
        return recentContacts;
    } else {
        if (lastRefreshAll == nil || [[NSDate date]timeIntervalSinceDate:lastRefreshAll] > 600) {
            allPersons = [IMPerson allPeople];
            lastRefreshAll = [NSDate date];
        }
        NSMutableSet *resultingContacts = [NSMutableSet set];
        for (IMPerson *person in allPersons) {
            if (stringContainsString(person.fullName, keyword, NO) || stringContainsString(person.companyName, keyword, NO)) {
                for (NSString *phoneNumber in person.phoneNumbers) {
                    [resultingContacts addObject:uncanonicalizedPhoneNumber(phoneNumber)];
                }
                for (IMHandle *handle in [IMHandle imHandlesForIMPerson:person]) {
                    [resultingContacts addObject:handle.ID];
                }
            } else {
                for (NSString *phoneNumber in person.phoneNumbers) {
                    NSString *filteredPhoneNumber = uncanonicalizedPhoneNumber(phoneNumber);
                    if (stringContainsString(filteredPhoneNumber, keyword, NO)) {
                        [resultingContacts addObject:filteredPhoneNumber];
                    }
                }
                for (NSString *email in person.emails) {
                    if (stringContainsString(email, keyword, NO)) {
                        [resultingContacts addObject:email];
                    }
                }
            }
        }
        if (resultingContacts.count == 0) {
            [resultingContacts addObject:uncanonicalizedPhoneNumber(keyword)];
        }
        return resultingContacts.allObjects;
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
            break;
        }
        case MarkRead: {
            NSString *userIdentifier = [[NSString alloc]initWithData:(__bridge NSData *)data encoding:NSUTF8StringEncoding];
            CKConversation *conversation = getConversation(userIdentifier, NO);
            if (conversation != nil) {
                [conversation markAllMessagesAsRead];
            }
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

#pragma mark - Constructor

__attribute__((constructor))
static void Constructor()
{
    @autoreleasepool {
        _CFEnableZombies();
        NSString *application = [NSBundle mainBundle].bundleIdentifier;
        if ([application isEqualToString:@"com.apple.springboard"]) {
            [[NSClassFromString(@"Couria")sharedInstance]registerDataSource:[CouriaMessagesDataSource new] delegate:[CouriaMessagesDelegate new] forApplication:MessagesIdentifier];
        } else if ([application isEqualToString:@"com.apple.MobileSMS"]) {
            [[[CouriaMessagesService alloc]init]start];
        }
    }
}
