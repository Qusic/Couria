#import <MobileCoreServices/MobileCoreServices.h>
#import <sqlite3.h>
#import "Couria.h"
#import "CouriaMessage.h"

#pragma mark - Defines

#define MessagesIdentifier @"com.apple.MobileSMS"

#pragma mark - Private APIs

@class IMPerson, IMHandle;

@interface IMPerson : NSObject
@property(readonly, nonatomic) NSString *name;
@property(readonly, nonatomic) NSString *fullName;
@property(readonly, nonatomic) NSString *companyName;
@property(nonatomic) NSArray *phoneNumbers;
@property(copy, nonatomic) NSArray *emails;
@property(retain, nonatomic) NSData *imageData;
+ (NSArray *)allPeople;
+ (instancetype)existingABPersonWithFirstName:(NSString *)firstName andLastName:(NSString *)lastName andNickName:(NSString *)nickName orEmail:(NSString *)email orNumber:(NSString *)number;
@end

@interface IMService : NSObject
@end

@interface IMService (IMService_GetService)
+ (instancetype)smsService;
+ (instancetype)iMessageService;
@end

@interface CKPreferredServiceManager : NSObject
+ (instancetype)sharedPreferredServiceManager;
- (NSInteger)availabilityForAddress:(NSString *)address onService:(IMService *)service checkWithServer:(BOOL)checkWithServer;
- (IMService *)preferredServiceForAddressString:(NSString *)address newComposition:(BOOL)newComposition checkWithServer:(BOOL)checkWithServer error:(NSError **)error;
@end

@interface IMAccount : NSObject
@end

@interface IMAccountController : NSObject
+ (instancetype)sharedInstance;
- (IMAccount *)bestConnectedAccountForService:(IMService *)service;
@end

@interface IMHandle : NSObject <NSCoding>
@property(readonly, nonatomic) NSString *ID;
+ (NSArray *)imHandlesForIMPerson:(IMPerson *)persons;
- (instancetype)initWithAccount:(IMAccount *)account ID:(NSString *)ID alreadyCanonical:(BOOL)alreadyCanonical;
@end

@interface IMHandleRegistrar : NSObject
+ (instancetype)sharedInstance;
- (void)registerIMHandle:(IMHandle *)handle;
@end

@interface IMMessage : NSObject <NSCopying>
@property(retain, nonatomic) NSDate *time;
@end

@interface IMChat : NSObject
@property(retain, nonatomic) IMHandle *recipient;
@property(readonly, nonatomic) IMMessage *lastMessage;
@end

@interface IMChatRegistry : NSObject <NSFastEnumeration>
@property(readonly, nonatomic) NSArray *allExistingChats;
+ (instancetype)sharedInstance;
- (IMChat *)existingChatWithChatIdentifier:(NSString *)identifier;
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
- (CKMediaObject *)newMediaObjectForData:(NSData *)data mimeType:(NSString *)mimeType exportedFilename:(NSString *)exportedFilename; // iOS 6
- (CKMediaObject *)newMediaObjectForFilename:(NSString *)filename mimeType:(NSString *)mimeType exportedFilename:(NSString *)exportedFilename composeOptions:(id)composeOptions; // iOS 6
- (CKMediaObject *)mediaObjectWithData:(NSData *)data UTIType:(NSString *)utiType filename:(NSString *)filename transcoderUserInfo:(id)transcoderUserInfo; // iOS 7
- (CKMediaObject *)mediaObjectWithFileURL:(NSURL *)url filename:(NSString *)filename transcoderUserInfo:(id)transcoderUserInfo; // iOS 7
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

@interface CKMessageComposition : NSObject // iOS 6
@property(retain, nonatomic) NSDictionary *resources;
@property(copy, nonatomic) NSString *markupString;
+ (instancetype)newComposition;
+ (instancetype)newCompositionForText:(NSString *)text;
@end

@interface CKComposition : NSObject // iOS 7
@property(copy, nonatomic) NSAttributedString *text;
+ (instancetype)compositionForMessageParts:(NSArray *)parts;
- (instancetype)initWithText:(id)text subject:(id)subject;
- (instancetype)compositionByAppendingMessagePart:(id)arg1;
- (NSArray *)mediaObjects;
@end

@interface CKConversation : NSObject
@property(retain, nonatomic) NSArray *recipients;
- (BOOL)canSendToRecipients:(NSArray *)ckimEntitys withAttachments:(NSArray *)messageParts alertIfUnable:(BOOL)alert;
- (BOOL)canSendMessageComposition:(CKMessageComposition *)composition error:(NSError **)error;
- (CKIMMessage *)newMessageWithComposition:(CKMessageComposition *)composition;
- (void)sendMessage:(CKIMMessage *)message newComposition:(BOOL)newComposition;
- (void)markAllMessagesAsRead;
@end

@interface CKConversationList : NSObject
+ (instancetype)sharedConversationList;
- (CKConversation *)conversationForExistingChatWithGroupID:(NSString *)groupID;
- (CKConversation *)conversationForHandles:(NSArray *)handles create:(BOOL)create;
@end

#pragma mark - Interfaces

@interface CouriaMessagesDataSource : NSObject <CouriaDataSource>
@end

@interface CouriaMessagesDelegate : NSObject <CouriaDelegate>
@end

@interface NSString (MessagesExtension)
- (BOOL)containsString:(NSString *)string caseSensitive:(BOOL)caseSensitive;
- (NSString *)uncanonicalizedPhoneNumber;
@end

#pragma mark - Implementations

static CKConversation *getConversation(NSString *userIdentifier, BOOL create)
{
    CKConversationList *list = [CKConversationList sharedConversationList];
    CKConversation *conversation = [list conversationForExistingChatWithGroupID:userIdentifier];
    if (conversation == nil && create) {
        IMService *service = [[CKPreferredServiceManager sharedPreferredServiceManager]preferredServiceForAddressString:userIdentifier newComposition:YES checkWithServer:NO error:nil];
        IMAccount *account = [[IMAccountController sharedInstance]bestConnectedAccountForService:service];
        IMHandle *handle = [[IMHandle alloc]initWithAccount:account ID:userIdentifier alreadyCanonical:NO];
        conversation = [[CKConversationList sharedConversationList]conversationForHandles:@[handle] create:YES];
        [[IMHandleRegistrar sharedInstance]registerIMHandle:handle];
    }
    return conversation;
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

@interface CouriaMessagesDataSource ()

@property(retain, readonly) NSMutableArray *recentContacts;
@property(retain, readonly) NSDate *lastRefreshRecent;
@property(retain, readonly) NSArray *allPersons;
@property(retain, readonly) NSDate *lastRefreshAll;

@end

@implementation CouriaMessagesDataSource

- (NSString *)getUserIdentifier:(BBBulletin *)bulletin
{
    return bulletin.context[@"contactInfo"];
}

- (NSString *)getNickname:(NSString *)userIdentifier
{
    IMPerson *person = [IMPerson existingABPersonWithFirstName:nil andLastName:nil andNickName:nil orEmail:userIdentifier orNumber:userIdentifier];
    return person ? person.name : userIdentifier;
}

- (UIImage *)getAvatar:(NSString *)userIdentifier
{
    IMPerson *person = [IMPerson existingABPersonWithFirstName:nil andLastName:nil andNickName:nil orEmail:userIdentifier orNumber:userIdentifier];
    return [UIImage imageWithData:person.imageData];
}

- (NSArray *)getMessages:(NSString *)userIdentifier
{
    CKPreferredServiceManager *serviceManager = [CKPreferredServiceManager sharedPreferredServiceManager];
    IMService *imessageService = [IMService iMessageService];
    if ([serviceManager availabilityForAddress:userIdentifier onService:imessageService checkWithServer:NO] == -1) {
        [serviceManager availabilityForAddress:userIdentifier onService:imessageService checkWithServer:YES];
    }
    NSMutableArray *messages = [NSMutableArray array];
    NSArray *dbMessages = querySMSDB([NSString stringWithFormat:@"SELECT ROWID, text, is_from_me, date, cache_has_attachments FROM message WHERE handle_id IN (SELECT ROWID FROM handle WHERE id = '%@') ORDER BY date DESC LIMIT 20;", userIdentifier]);
    for (NSDictionary *dbMessage in dbMessages.reverseObjectEnumerator) {
        NSString *text = [dbMessage[@"text"]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        BOOL outgoing = [dbMessage[@"is_from_me"]boolValue];
        BOOL hasAttachments = [dbMessage[@"cache_has_attachments"]boolValue];
        if (text.length > 0 && ((signed char)[text cStringUsingEncoding:NSUTF8StringEncoding][0]) != -17) {
            CouriaMessage *message = [[CouriaMessage alloc]init];
            message.text = text;
            message.outgoing = outgoing;
            [messages addObject:message];
        }
        if (hasAttachments) {
            NSArray *dbAttachments = querySMSDB([NSString stringWithFormat:@"SELECT filename, mime_type FROM attachment WHERE ROWID IN (SELECT attachment_id FROM message_attachment_join WHERE message_id = '%@');", dbMessage[@"ROWID"]]);
            for (NSDictionary *dbAttachment in dbAttachments) {
                NSString *filename = [dbAttachment[@"filename"]stringByExpandingTildeInPath];
                NSString *mimeType = dbAttachment[@"mime_type"];
                CouriaMessage *message = [[CouriaMessage alloc]init];
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
    if (_lastRefreshRecent == nil || [[NSDate date]timeIntervalSinceDate:_lastRefreshRecent] > 10) {
        _recentContacts = [NSMutableArray array];
        for (IMChat *chat in [[IMChatRegistry sharedInstance].allExistingChats sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastMessage.time" ascending:NO]]]) {
            if (chat.lastMessage.time) {
                [_recentContacts addObject:chat.recipient.ID];
            } else {
                [_recentContacts insertObject:chat.recipient.ID atIndex:0];
            }
        }
        _lastRefreshRecent = [NSDate date];
    }
    if (_lastRefreshAll == nil || [[NSDate date]timeIntervalSinceDate:_lastRefreshAll] > 600) {
        _allPersons = [IMPerson allPeople];
        _lastRefreshAll = [NSDate date];
    }
    if (keyword.length == 0) {
        return _recentContacts;
    } else {
        NSMutableSet *resultingContacts = [NSMutableSet set];
        for (IMPerson *person in _allPersons) {
            if ([person.fullName containsString:keyword caseSensitive:NO] || [person.companyName containsString:keyword caseSensitive:NO]) {
                for (NSString *phoneNumber in person.phoneNumbers) {
                    [resultingContacts addObject:phoneNumber.uncanonicalizedPhoneNumber];
                }
                for (IMHandle *handle in [IMHandle imHandlesForIMPerson:person]) {
                    [resultingContacts addObject:handle.ID];
                }
            } else {
                for (NSString *phoneNumber in person.phoneNumbers) {
                    NSString *filteredPhoneNumber = phoneNumber.uncanonicalizedPhoneNumber;
                    if ([filteredPhoneNumber containsString:keyword caseSensitive:NO]) {
                        [resultingContacts addObject:filteredPhoneNumber];
                    }
                }
                for (NSString *email in person.emails) {
                    if ([email containsString:keyword caseSensitive:NO]) {
                        [resultingContacts addObject:email];
                    }
                }
            }
        }
        if (resultingContacts.count == 0) {
            [resultingContacts addObject:keyword.uncanonicalizedPhoneNumber];
        }
        return resultingContacts.allObjects;
    }
}

@end

@implementation CouriaMessagesDelegate

- (void)sendMessage:(id<CouriaMessage>)message toUser:(NSString *)userIdentifier
{
    if (iOS7()) {
        //TODO: iOS 7
    } else {
        Class CKMessageComposition$ = NSClassFromString(@"CKMessageComposition");
        NSMutableArray *compositions = [NSMutableArray array];
        NSString *text = message.text;
        if (text.length > 0) {
            CKMessageComposition *composition = [CKMessageComposition$ newCompositionForText:text];
            [compositions addObject:composition];
        }
        id media = message.media;
        if (media != nil) {
            CKMediaObject *mediaObject = nil;
            if ([media isKindOfClass:UIImage.class]) {
                mediaObject = [[CKMediaObjectManager sharedInstance]newMediaObjectForData:UIImagePNGRepresentation(media) mimeType:@"image/png" exportedFilename:nil];
            } else if ([media isKindOfClass:NSURL.class]) {
                //TODO: cannot be sent successfully.
                mediaObject = [[CKMediaObjectManager sharedInstance]newMediaObjectForFilename:[media absoluteString] mimeType:@"video/quicktime" exportedFilename:nil composeOptions:nil];
            }
            if (mediaObject != nil) {
                NSString *transferGUID = mediaObject.transferGUID;
                CKMessageComposition *composition = [CKMessageComposition$ newComposition];
                CKMediaObjectMessagePart *part = [[CKMediaObjectMessagePart alloc]initWithMediaObject:mediaObject];
                composition.resources = @{transferGUID: part};
                composition.markupString = [NSString stringWithFormat:@"<img id=\"%@\" style=\"display:block;margin-left:-6px;padding-top:5px;padding-bottom:3px\" width=\"100px\" height=\"100px\" src=\"x-ckmsgpart:0/%@/0\">", transferGUID, transferGUID];
                [compositions addObject:composition];
            }
        }
        CKConversation *conversation = getConversation(userIdentifier, YES);
        if (conversation == nil) {
            IMService *service = [[CKPreferredServiceManager sharedPreferredServiceManager]preferredServiceForAddressString:userIdentifier newComposition:YES checkWithServer:NO error:nil];
            IMAccount *account = [[IMAccountController sharedInstance]bestConnectedAccountForService:service];
            IMHandle *handle = [[IMHandle alloc]initWithAccount:account ID:userIdentifier alreadyCanonical:NO];
            conversation = [[CKConversationList sharedConversationList]conversationForHandles:@[handle] create:YES];
            [[IMHandleRegistrar sharedInstance]registerIMHandle:handle];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            for (CKMessageComposition *composition in compositions) {
                if (composition.resources.count > 0 && ![conversation canSendToRecipients:conversation.recipients withAttachments:composition.resources.allValues alertIfUnable:NO]) {
                    return;
                }
                if (![conversation canSendMessageComposition:composition error:nil]) {
                    return;
                }
                CKIMMessage *message = [conversation newMessageWithComposition:composition];
                [conversation sendMessage:message newComposition:YES];
            }
        });
    }
}

- (void)markRead:(NSString *)userIdentifier
{
    CKConversation *conversation = getConversation(userIdentifier, NO);
    [conversation performSelectorOnMainThread:@selector(markAllMessagesAsRead) withObject:nil waitUntilDone:NO];
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

@implementation NSString (MessagesExtension)

- (BOOL)containsString:(NSString *)string caseSensitive:(BOOL)caseSensitive
{
    return [self rangeOfString:string options:caseSensitive ? 0 : NSCaseInsensitiveSearch].location != NSNotFound;
}

- (NSString *)uncanonicalizedPhoneNumber
{
    return [self stringByReplacingOccurrencesOfString:@"[- ()]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, self.length)];
}

@end

#pragma mark - Constructor

__attribute__((constructor))
static void Constructor()
{
    @autoreleasepool {
        _CFEnableZombies();
        [[Couria sharedInstance]registerDataSource:[CouriaMessagesDataSource new] delegate:[CouriaMessagesDelegate new] forApplication:MessagesIdentifier];
    }
}
