#import "../Headers.h"

static CouriaSearchAgent *searchAgent;
static ABAddressBookRef addressBook;

CHDeclareClass(CouriaInlineReplyViewController)
CHDeclareClass(CouriaInlineReplyViewController_MobileSMSApp)

CHOptimizedMethod(0, super, void, CouriaInlineReplyViewController_MobileSMSApp, setupConversation)
{
    NSString *chatIdentifier = self.context[CKBBUserInfoKeyChatIdentifierKey];
    if (chatIdentifier != nil) {
        CHSuper(0, CouriaInlineReplyViewController_MobileSMSApp, setupConversation);
        CKConversationList *conversationList = [CKConversationList sharedConversationList];
        CKConversation *conversation = [conversationList conversationForExistingChatWithGroupID:chatIdentifier];
        if (conversation == nil) {
            CKEntity *entity = [CKEntity copyEntityForAddressString:chatIdentifier];
            IMService *service = [[IMPreferredServiceManager sharedPreferredServiceManager]preferredServiceForHandles:@[entity.defaultIMHandle] newComposition:YES error:NULL serverCheckCompletionBlock:NULL];
            IMAccount *account = [[IMAccountController sharedInstance]__ck_defaultAccountForService:service];
            NSArray *handles = [account __ck_handlesFromAddressStrings:@[chatIdentifier]];
            conversation = [conversationList conversationForHandles:handles create:YES];
        }
        static NSUInteger const messagesLimit = 51;
        conversation.limitToLoad = messagesLimit;
        conversation.chat.numberOfMessagesToKeepLoaded = messagesLimit;
        [conversation.chat loadMessagesBeforeDate:nil limit:messagesLimit loadImmediately:YES];
        NSMutableArray *chatItems = [NSMutableArray array];
        [conversation.chat.chatItems enumerateObjectsUsingBlock:^(IMChatItem *item, NSUInteger index, BOOL *stop) {
            [chatItems addObject:[self.conversationViewController chatItemWithIMChatItem:item]];
        }];
        self.conversationViewController.conversation = conversation;
        self.conversationViewController.chatItems = chatItems;
        self.entryView.conversation = conversation;
    } else {
        searchAgent.updateHandler = ^(void) {
            if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                    dispatch_semaphore_signal(semaphore);
                });
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
            NSMutableArray *contacts = [NSMutableArray array];
            NSString *queryString = searchAgent.queryString;
            if (queryString.length == 0) {
                [[[IMChatRegistry sharedInstance].allExistingChats sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastFinishedMessage.time" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"__ck_watermarkMessageID" ascending:NO]]] enumerateObjectsUsingBlock:^(IMChat *chat, NSUInteger index, BOOL *stop) {
                    [contacts addObject:@{
                        IdentifierKey: chat.chatIdentifier,
                        NicknameKey: chat.participants.count == 1 ? chat.recipient.name : ({
                            NSMutableString *groupName = [NSMutableString string];
                            [chat.participants enumerateObjectsUsingBlock:^(IMHandle *handle, NSUInteger index, BOOL *stop) {
                                if (index > 0) {
                                    [groupName appendString:index == chat.participants.count - 1 ? @" & " : @", "];
                                }
                                [groupName appendString:handle.name];
                            }];
                            groupName;
                        }),
                        AvatarKey: [CKEntity copyEntityForAddressString:chat.chatIdentifier].transcriptContactImage //TODO: group thumbnail
                    }];
                }];
            } else if (searchAgent.resultCount > 0) {
                if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
                    [[searchAgent sectionAtIndex:0].results enumerateObjectsUsingBlock:^(SPSearchResult *agentResult, NSUInteger index, BOOL *stop) {
                        ABRecordID recordID = (ABRecordID)agentResult.identifier;
                        ABRecordRef record = ABAddressBookGetPersonWithRecordID(addressBook, recordID);
                        if (record != NULL) {
                            NSString *name = CFBridgingRelease(ABRecordCopyCompositeName(record));
                            void (^ processMultiValueProperty)(ABPropertyID) = ^(ABPropertyID property) {
                                ABMultiValueRef multiValue = ABRecordCopyValue(record, property);
                                for (CFIndex index = 0, count = ABMultiValueGetCount(multiValue); index < count; index++) {
                                    NSString *label = CFBridgingRelease(ABMultiValueCopyLabelAtIndex(multiValue, index));
                                    NSString *value = CFBridgingRelease(ABMultiValueCopyValueAtIndex(multiValue, index));
                                    if (value.length > 0) {
                                        [contacts addObject:@{
                                            IdentifierKey: IMStripFormattingFromAddress(value),
                                            NicknameKey: label ? [NSString stringWithFormat:@"%@ (%@)", name, CFBridgingRelease(ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)label))] : [NSString stringWithFormat:@"%@", name],
                                            AvatarKey: [CKAddressBook transcriptContactImageOfDiameter:[CKUIBehavior sharedBehaviors].transcriptContactImageDiameter forRecordID:recordID]
                                        }];
                                    }
                                }
                                CFRelease(multiValue);
                            };
                            processMultiValueProperty(kABPersonPhoneProperty);
                            processMultiValueProperty(kABPersonEmailProperty);
                        }
                    }];
                } else {
                    [contacts addObject:@{
                        IdentifierKey: IMStripFormattingFromAddress(queryString),
                        NicknameKey: queryString
                    }];
                    [self.messagingCenter sendNonBlockingMessageName:UpdateBannerMessage userInfo:@{
                        SecondaryTextKey: CouriaLocalizedString(@"NO_ACCESS_TO_CONTACTS")
                    }];
                }
            } else {
                [contacts addObject:@{
                    IdentifierKey: IMStripFormattingFromAddress(queryString),
                    NicknameKey: queryString
                }];
            }
            self.contactsViewController.contacts = contacts;
            [self.contactsViewController refreshData];
        };
        __weak __typeof__(self) weakSelf = self;
        self.contactsViewController.keywordHandler = ^(NSString *keyword) {
            searchAgent.queryString = keyword;
        };
        self.contactsViewController.selectionHandler = ^(NSDictionary *contact) {
            NSMutableDictionary *context = weakSelf.context.mutableCopy;
            context[CKBBUserInfoKeyChatIdentifierKey] = contact[IdentifierKey];
            weakSelf.context = context;
            [weakSelf.conversationViewController refreshData];
            [weakSelf interactiveNotificationDidAppear];
            [weakSelf.messagingCenter sendNonBlockingMessageName:UpdateBannerMessage userInfo:@{
                PrimaryTextKey: contact[NicknameKey]
            }];
        };
    }
}

CHOptimizedMethod(0, super, void, CouriaInlineReplyViewController_MobileSMSApp, setupView)
{
    CHSuper(0, CouriaInlineReplyViewController_MobileSMSApp, setupView);
    self.entryView.shouldShowPhotoButton = YES;
}

CHOptimizedMethod(0, super, void, CouriaInlineReplyViewController_MobileSMSApp, interactiveNotificationDidAppear)
{
    CHSuper(0, CouriaInlineReplyViewController_MobileSMSApp, interactiveNotificationDidAppear);
    if (self.context[CKBBUserInfoKeyChatIdentifierKey] != nil) {
        self.entryView.hidden = NO;
        self.conversationViewController.view.hidden = NO;
        self.contactsViewController.view.hidden = YES;
        [self.conversationViewController.conversation markAllMessagesAsRead];
    } else {
        self.entryView.hidden = YES;
        self.conversationViewController.view.hidden = YES;
        self.contactsViewController.view.hidden = NO;
        [self.contactsViewController.searchBar becomeFirstResponder];
        [self.contactsViewController searchBar:self.contactsViewController.searchBar textDidChange:nil];
    }
}

CHOptimizedMethod(1, super, void, CouriaInlineReplyViewController_MobileSMSApp, messageEntryViewDidChange, CKMessageEntryView *, entryView)
{
    CHSuper(1, CouriaInlineReplyViewController_MobileSMSApp, messageEntryViewDidChange, entryView);
    [self.typingUpdater setNeedsUpdate];
    [self updateSendButton];
}

void CouriaUIMobileSMSAppInit(void)
{
    searchAgent = [[CouriaSearchAgent alloc]init];
    addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    CHLoadLateClass(CouriaInlineReplyViewController);
    CHRegisterClass(CouriaInlineReplyViewController_MobileSMSApp, CouriaInlineReplyViewController) {
        CHHook(0, CouriaInlineReplyViewController_MobileSMSApp, setupConversation);
        CHHook(0, CouriaInlineReplyViewController_MobileSMSApp, setupView);
        CHHook(0, CouriaInlineReplyViewController_MobileSMSApp, interactiveNotificationDidAppear);
        CHHook(1, CouriaInlineReplyViewController_MobileSMSApp, messageEntryViewDidChange);
    }
}
