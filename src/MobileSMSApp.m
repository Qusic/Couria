#import "Headers.h"

static CouriaSearchAgent *searchAgent;
static ABAddressBookRef addressBook;

CHDeclareClass(CKInlineReplyViewController)
CHDeclareClass(CouriaInlineReplyViewController_MobileSMSApp)

CHOptimizedMethod(0, super, void, CouriaInlineReplyViewController_MobileSMSApp, setupConversation)
{
    NSString *chatIdentifier = self.context[@"CKBBUserInfoKeyChatIdentifier"];
    if (chatIdentifier != nil) {
        CHSuper(0, CouriaInlineReplyViewController_MobileSMSApp, setupConversation);
        CKConversation *conversation = [[CKConversationList sharedConversationList]conversationForExistingChatWithGroupID:chatIdentifier];
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
    } else {
        searchAgent.updateHandler = ^(void) {
            NSMutableArray *contacts = [NSMutableArray array];
            NSString *queryString = searchAgent.queryString;
            if (queryString.length == 0) {
                [[[IMChatRegistry sharedInstance].allExistingChats sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"dateModified" ascending:NO]]] enumerateObjectsUsingBlock:^(IMChat *chat, NSUInteger index, BOOL *stop) {
                    [contacts addObject:@{
                        @"identifier": chat.chatIdentifier,
                        @"nickname": chat.recipient.name,
                    }];
                }];
            } else if (searchAgent.resultCount > 0) {
                if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
                    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                        dispatch_semaphore_signal(semaphore);
                    });
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                }
                if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
                    [[searchAgent sectionAtIndex:0].results enumerateObjectsUsingBlock:^(SPSearchResult *agentResult, NSUInteger index, BOOL *stop) {
                        ABRecordRef record = ABAddressBookGetPersonWithRecordID(addressBook, (ABRecordID)agentResult.identifier);
                        CFStringRef name = ABRecordCopyCompositeName(record);
                        ABMultiValueRef phoneNumbers = ABRecordCopyValue(record, kABPersonPhoneProperty);
                        ABMultiValueRef emails = ABRecordCopyValue(record, kABPersonEmailProperty);
                        for (CFIndex index = 0, count = ABMultiValueGetCount(phoneNumbers); index < count; index++) {
                            CFStringRef label = ABMultiValueCopyLabelAtIndex(phoneNumbers, index);
                            CFStringRef localizedLabel = ABAddressBookCopyLocalizedLabel(label);
                            CFStringRef value = ABMultiValueCopyValueAtIndex(phoneNumbers, index);
                            [contacts addObject:@{
                                @"identifier": IMStripFormattingFromAddress((__bridge NSString *)value),
                                @"nickname": [NSString stringWithFormat:@"%@ (%@)", (__bridge NSString *)name, (__bridge NSString *)localizedLabel]
                            }];
                            CFRelease(label);
                            CFRelease(localizedLabel);
                            CFRelease(value);
                        }
                        for (CFIndex index = 0, count = ABMultiValueGetCount(emails); index < count; index++) {
                            CFStringRef label = ABMultiValueCopyLabelAtIndex(emails, index);
                            CFStringRef localizedLabel = ABAddressBookCopyLocalizedLabel(label);
                            CFStringRef value = ABMultiValueCopyValueAtIndex(emails, index);
                            [contacts addObject:@{
                                @"identifier": IMStripFormattingFromAddress((__bridge NSString *)value),
                                @"nickname": [NSString stringWithFormat:@"%@ (%@)", (__bridge NSString *)name, (__bridge NSString *)localizedLabel]
                            }];
                            CFRelease(label);
                            CFRelease(localizedLabel);
                            CFRelease(value);
                        }
                        CFRelease(name);
                        CFRelease(phoneNumbers);
                        CFRelease(emails);
                    }];
                } else {
                    [contacts addObject:@{
                        @"identifier": IMStripFormattingFromAddress(queryString),
                        @"nickname": queryString
                    }];
                    [self.messagingCenter sendNonBlockingMessageName:@"updateBanner" userInfo:@{
                        @"secondaryText": @"No Access to Contacts"
                    }];
                }
            } else {
                [contacts addObject:@{
                    @"identifier": IMStripFormattingFromAddress(queryString),
                    @"nickname": queryString
                }];
            }
            self.contactsViewController.contacts = contacts;
            [self.contactsViewController refreshData];
        };
        self.contactsViewController.keywordHandler = ^(NSString *keyword) {
            searchAgent.queryString = keyword;
        };
        __weak __typeof__(self) weakSelf = self;
        self.contactsViewController.selectionHandler = ^(NSDictionary *contact) {
            NSMutableDictionary *context = weakSelf.context.mutableCopy;
            context[@"CKBBUserInfoKeyChatIdentifier"] = contact[@"identifier"];
            weakSelf.context = context;
            [weakSelf setupConversation];
            [weakSelf.conversationViewController refreshData];
            [weakSelf interactiveNotificationDidAppear];
            [weakSelf.messagingCenter sendNonBlockingMessageName:@"updateBanner" userInfo:@{
                @"primaryText": contact[@"nickname"]
            }];
        };
    }
}

CHOptimizedMethod(0, self, void, CouriaInlineReplyViewController_MobileSMSApp, setupView)
{
    CHSuper(0, CouriaInlineReplyViewController_MobileSMSApp, setupView);
    self.entryView.shouldShowPhotoButton = NO; //TODO: photo not supported yet
}

CHOptimizedMethod(0, super, void, CouriaInlineReplyViewController_MobileSMSApp, interactiveNotificationDidAppear)
{
    CHSuper(0, CouriaInlineReplyViewController_MobileSMSApp, interactiveNotificationDidAppear);
    if (self.context[@"CKBBUserInfoKeyChatIdentifier"] != nil) {
        self.entryView.hidden = NO;
        self.conversationViewController.view.hidden = NO;
        self.contactsViewController.view.hidden = YES;
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

CHConstructor
{
    @autoreleasepool {
        searchAgent = [[CouriaSearchAgent alloc]init];
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        CHLoadLateClass(CKInlineReplyViewController);
        CHRegisterClass(CouriaInlineReplyViewController_MobileSMSApp, CKInlineReplyViewController) {
            CHHook(0, CouriaInlineReplyViewController_MobileSMSApp, setupConversation);
            CHHook(0, CouriaInlineReplyViewController_MobileSMSApp, setupView);
            CHHook(1, CouriaInlineReplyViewController_MobileSMSApp, messageEntryViewDidChange);
            CHHook(0, CouriaInlineReplyViewController_MobileSMSApp, interactiveNotificationDidAppear);
        }
    }
}
