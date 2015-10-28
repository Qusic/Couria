#import "../Headers.h"

static NSString * const daemonListenerID = @"MessagesNotificationViewService";

static CouriaSearchAgent *searchAgent;
static ABAddressBookRef addressBook;

CHDeclareClass(CouriaInlineReplyViewController)
CHDeclareClass(CouriaInlineReplyViewController_MobileSMSApp)
CHDeclareClass(CNAvatarView)

CHOptimizedMethod(0, super, void, CouriaInlineReplyViewController_MobileSMSApp, setupConversation) {
    NSString *chatIdentifier = self.context[CKBBUserInfoKeyChatIdentifierKey];
    if (chatIdentifier != nil) {
        [[IMDaemonController sharedInstance]setCapabilities:CKListenerPaginatedChatRegistryCapabilities() forListenerID:daemonListenerID];
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
        [[IMDaemonController sharedInstance]setCapabilities:CKListenerCapabilities() forListenerID:daemonListenerID];
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
                CKConversationList *conversationList = [CKConversationList sharedConversationList];
                [conversationList setNeedsReload];
                [conversationList resort];
                [conversationList.activeConversations enumerateObjectsUsingBlock:^(CKConversation *conversation, NSUInteger index, BOOL *stop) {
                    [contacts addObject:@{
                        IdentifierKey: conversation.groupID,
                        NicknameKey: conversation.hasDisplayName ? conversation.displayName : conversation.name,
                        AvatarKey: ({
                            UIImage *image = nil;
                            if (CHClass(CNAvatarView)) {
                                static CNAvatarView *avatarView;
                                static dispatch_once_t onceToken;
                                dispatch_once(&onceToken, ^{
                                    CGFloat size = [CKUIBehavior sharedBehaviors].transcriptContactImageDiameter;
                                    avatarView = [CHAlloc(CNAvatarView)initWithFrame:CGRectMake(0, 0, size, size)];
                                });
                                avatarView.contacts = conversation.orderedContactsForAvatarView;
                                [avatarView _updateAvatarView];
                                image = avatarView.contentImage;
                            } else {
                                image = [CKEntity copyEntityForAddressString:conversation.groupID].transcriptContactImage;
                            }
                            image;
                        })
                    }];
                }];
            } else if (searchAgent.hasResults) {
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
            if ([searchAgent respondsToSelector:@selector(setQueryString:keyboardLanguage:keyboardPrimaryLanguage:levelZKW:allowInternet:)]) {
                static NSString * (^ const inputTypeForInputMode)(UITextInputMode *) = ^(UITextInputMode *inputMode) {
                    NSString *inputType = nil;
                    if ([inputMode isKindOfClass:UITextInputMode.class]) {
                        if ([inputMode.identifier isEqualToString:@"dictation"]) {
                            inputType = @"dictation";
                        } else if (inputMode.extension != nil) {
                            inputType = @"custom";
                        } else {
                            inputType = inputMode.normalizedIdentifierLevels.firstObject;
                        }
                    }
                    return inputType;
                };
                UITextInputMode *inputMode = weakSelf.contactsViewController.searchBar.textInputMode;
                [searchAgent setQueryString:keyword keyboardLanguage:inputTypeForInputMode(inputMode) keyboardPrimaryLanguage:inputMode.primaryLanguage levelZKW:0 allowInternet:NO];
            } else if ([searchAgent respondsToSelector:@selector(setQueryString:)]) {
                [searchAgent setQueryString:keyword];
            }
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

CHOptimizedMethod(0, super, void, CouriaInlineReplyViewController_MobileSMSApp, setupView) {
    CHSuper(0, CouriaInlineReplyViewController_MobileSMSApp, setupView);
    self.entryView.shouldShowPhotoButton = YES;
}

CHOptimizedMethod(0, super, void, CouriaInlineReplyViewController_MobileSMSApp, interactiveNotificationDidAppear) {
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
        [self.contactsViewController searchBar:self.contactsViewController.searchBar textDidChange:self.contactsViewController.searchBar.text];
    }
}

CHOptimizedMethod(1, super, void, CouriaInlineReplyViewController_MobileSMSApp, messageEntryViewDidChange, CKMessageEntryView *, entryView) {
    CHSuper(1, CouriaInlineReplyViewController_MobileSMSApp, messageEntryViewDidChange, entryView);
    [self.typingUpdater setNeedsUpdate];
    if ([self respondsToSelector:@selector(updateSendButton)]) {
        [self updateSendButton];
    }
}

FHFunction(0, BOOL, CKIsRunningInFullCKClient) {
    return YES;
}

FHFunction(0, BOOL, CKIsRunningInMessages) {
    return YES;
}

FHFunction(0, BOOL, CKIsRunningInMessagesOrSpringBoard) {
    return YES;
}

void CouriaUIMobileSMSAppInit(void) {
    searchAgent = [[CouriaSearchAgent alloc]init];
    addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    CHLoadLateClass(CouriaInlineReplyViewController);
    CHRegisterClass(CouriaInlineReplyViewController_MobileSMSApp, CouriaInlineReplyViewController) {
        CHHook(0, CouriaInlineReplyViewController_MobileSMSApp, setupConversation);
        CHHook(0, CouriaInlineReplyViewController_MobileSMSApp, setupView);
        CHHook(0, CouriaInlineReplyViewController_MobileSMSApp, interactiveNotificationDidAppear);
        CHHook(1, CouriaInlineReplyViewController_MobileSMSApp, messageEntryViewDidChange);
    }
    CHLoadLateClass(CNAvatarView);
    FHHook(CKIsRunningInFullCKClient);
    FHHook(CKIsRunningInMessages);
    FHHook(CKIsRunningInMessagesOrSpringBoard);
}
