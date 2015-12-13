#import "../Headers.h"

static NSString * const daemonListenerID = @"MessagesNotificationViewService";

static CouriaAddressBook *addressBook;
static CouriaSearchAgent *searchAgent;

CHDeclareClass(CouriaInlineReplyViewController)
CHDeclareClass(CouriaInlineReplyViewController_MobileSMSApp)

CHOptimizedMethod(0, super, void, CouriaInlineReplyViewController_MobileSMSApp, setupConversation) {
    NSString *chatIdentifier = self.context[CKBBUserInfoKeyChatIdentifierKey];
    if (chatIdentifier != nil) {
        if (CKListenerPaginatedChatRegistryCapabilities) {
            [[IMDaemonController sharedInstance]setCapabilities:CKListenerPaginatedChatRegistryCapabilities() forListenerID:daemonListenerID];
        }
        CHSuper(0, CouriaInlineReplyViewController_MobileSMSApp, setupConversation);
        CKConversationList *conversationList = [CKConversationList sharedConversationList];
        CKConversation *conversation = [conversationList conversationForExistingChatWithGroupID:chatIdentifier];
        if (conversation == nil) {
            CKEntity *entity = [CKEntity copyEntityForAddressString:chatIdentifier];
            IMService *service = [[IMPreferredServiceManager sharedPreferredServiceManager]preferredServiceForHandles:@[entity.defaultIMHandle] newComposition:YES error:NULL serverCheckCompletionBlock:NULL];
            IMAccount *account = [[IMAccountController sharedInstance]__ck_defaultAccountForService:service];
            NSArray *handles = [account __ck_handlesFromAddressStrings:@[chatIdentifier]];
            if ([conversationList respondsToSelector:@selector(conversationForHandles:displayName:joinedChatsOnly:create:)]) {
                conversation = [conversationList conversationForHandles:handles displayName:nil joinedChatsOnly:NO create:YES];
            } else if ([conversationList respondsToSelector:@selector(conversationForHandles:create:)]) {
                conversation = [conversationList conversationForHandles:handles create:YES];
            }
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
        if (CKListenerCapabilities) {
            [[IMDaemonController sharedInstance]setCapabilities:CKListenerCapabilities() forListenerID:daemonListenerID];
        }
        [addressBook requestAccess];
        searchAgent.updateHandler = ^(void) {
            NSMutableArray *contacts = [NSMutableArray array];
            NSString *queryString = searchAgent.queryString;
            if (queryString.length == 0) {
                CKConversationList *conversationList = [CKConversationList sharedConversationList];
                [conversationList setNeedsReload];
                [conversationList resort];
                [conversationList.activeConversations enumerateObjectsUsingBlock:^(CKConversation *conversation, NSUInteger index, BOOL *stop) {
                    NSString *identifier = conversation.groupID;
                    if (identifier.length == 0) {
                        return;
                    }
                    NSString *nickname = conversation.hasDisplayName ? conversation.displayName : conversation.name;
                    if (nickname == nil) {
                        nickname = IMStripFormattingFromAddress(identifier);
                    }
                    UIImage *avatar = CNContact.class ? [addressBook avatarImageForContacts:conversation.orderedContactsForAvatarView] : [CKEntity copyEntityForAddressString:conversation.groupID].transcriptContactImage;
                    NSMutableDictionary *contact = [NSMutableDictionary dictionary];
                    contact[IdentifierKey] = identifier;
                    contact[NicknameKey] = nickname;
                    if (avatar) {
                        contact[AvatarKey] = avatar;
                    }
                    [contacts addObject:contact];
                }];
            } else if (searchAgent.hasResults) {
                if (addressBook.accessGranted) {
                    [contacts addObjectsFromArray:[addressBook processSearchResults:searchAgent.contactsResults withBlock:^(NSString *identifier, NSString *nickname, UIImage *avatar) {
                        NSMutableDictionary *contact = [NSMutableDictionary dictionary];
                        contact[IdentifierKey] = identifier;
                        contact[NicknameKey] = nickname;
                        if (avatar) {
                            contact[AvatarKey] = avatar;
                        }
                        return contact;
                    }]];
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
            [searchAgent setQueryString:keyword inputMode:weakSelf.contactsViewController.searchBar.textInputMode];
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

FHFunction(BOOL, CKIsRunningInFullCKClient) {
    return YES;
}

FHFunction(BOOL, CKIsRunningInMessages) {
    return YES;
}

FHFunction(BOOL, CKIsRunningInMessagesOrSpringBoard) {
    return YES;
}

void CouriaUIMobileSMSAppInit(void) {
    addressBook = [[CouriaAddressBook alloc]init];
    searchAgent = [[CouriaSearchAgent alloc]init];
    CHLoadLateClass(CouriaInlineReplyViewController);
    CHRegisterClass(CouriaInlineReplyViewController_MobileSMSApp, CouriaInlineReplyViewController) {
        CHHook(0, CouriaInlineReplyViewController_MobileSMSApp, setupConversation);
        CHHook(0, CouriaInlineReplyViewController_MobileSMSApp, setupView);
        CHHook(0, CouriaInlineReplyViewController_MobileSMSApp, interactiveNotificationDidAppear);
        CHHook(1, CouriaInlineReplyViewController_MobileSMSApp, messageEntryViewDidChange);
    }
    FHHook(CKIsRunningInFullCKClient);
    FHHook(CKIsRunningInMessages);
    FHHook(CKIsRunningInMessagesOrSpringBoard);
}
