#import "../Headers.h"

CHDeclareClass(CouriaInlineReplyViewController)
CHDeclareClass(CouriaInlineReplyViewController_ThirdPartyApp)

CHOptimizedMethod(0, super, void, CouriaInlineReplyViewController_ThirdPartyApp, setupConversation)
{
    NSString *applicationIdentifier = self.context[CouriaIdentifier ApplicationDomain];
    NSString *userIdentifier = self.context[CouriaIdentifier UserDomain];
    if (userIdentifier != nil) {
        CHSuper(0, CouriaInlineReplyViewController_ThirdPartyApp, setupConversation);
        NSArray *result = [NSKeyedUnarchiver unarchiveObjectWithData:[self.messagingCenter sendMessageAndReceiveReplyName:GetMessagesMessage userInfo:@{
            ApplicationKey: applicationIdentifier,
            UserKey: userIdentifier
        } error:NULL][MessagesKey]];
        NSMutableArray *chatItems = [NSMutableArray array];
        [result enumerateObjectsUsingBlock:^(NSDictionary *messageDictionary, NSUInteger index, BOOL *stop) {
            id content = messageDictionary[ContentKey];
            BOOL outgoing = [messageDictionary[OutgoingKey]boolValue];
            NSDate *timestamp = messageDictionary[TimestampKey];
            IMMessageItem *messageItem = [[IMMessageItem alloc]init];
            BOOL finished = YES, fromme = outgoing, delivered = YES, read = !outgoing, sent = outgoing;
            messageItem.flags |= (finished << 0x0 | fromme << 0x2 | delivered << 0xc | read << 0xd | sent << 0xf);
            messageItem.time = timestamp;
            messageItem.timeDelivered = timestamp;
            messageItem.timeRead = timestamp;
            if ([content isKindOfClass:NSString.class]) {
                NSString *string = content;
                messageItem.plainBody = string;
            } else if ([content isKindOfClass:NSURL.class]) {
                NSURL *url = content;
                CKMediaObject *mediaObject = [[CKMediaObjectManager sharedInstance]mediaObjectWithFileURL:url filename:url.lastPathComponent transcoderUserInfo:nil];
                messageItem.body = [[NSAttributedString alloc]initWithString:IMAttachmentCharacterString attributes:@{
                    IMMessagePartAttributeName: @(1),
                    IMFileTransferGUIDAttributeName: mediaObject.transferGUID,
                    IMFilenameAttributeName: url.lastPathComponent,
                    IMBaseWritingDirectionAttributeName: @(NSWritingDirectionNatural)
                }];
            }
            messageItem.context = [IMMessage messageFromIMMessageItem:messageItem sender:nil subject:nil];
            CKChatItem *chatItem = [self.conversationViewController chatItemWithIMChatItem:messageItem._newChatItems];
            if (chatItem.transcriptDrawerText == nil) {
                chatItem.transcriptDrawerText = [[NSAttributedString alloc]initWithString:@""];
            }
            [chatItems addObject:chatItem];
        }];
        self.conversationViewController.chatItems = chatItems;
    } else {
        __weak __typeof__(self) weakSelf = self;
        self.contactsViewController.keywordHandler = ^(NSString *keyword) {
            NSArray *result = [NSKeyedUnarchiver unarchiveObjectWithData:[weakSelf.messagingCenter sendMessageAndReceiveReplyName:GetContactsMessage userInfo:@{
                ApplicationKey: applicationIdentifier,
                KeywordKey: keyword ?: @""
            } error:NULL][ContactsKey]];
            weakSelf.contactsViewController.contacts = result;
            [weakSelf.contactsViewController refreshData];
        };
        self.contactsViewController.selectionHandler = ^(NSDictionary *contact) {
            NSMutableDictionary *context = weakSelf.context.mutableCopy;
            context[CouriaIdentifier UserDomain] = contact[IdentifierKey];
            weakSelf.context = context;
            [weakSelf.conversationViewController refreshData];
            [weakSelf interactiveNotificationDidAppear];
            [weakSelf.messagingCenter sendNonBlockingMessageName:UpdateBannerMessage userInfo:@{
                PrimaryTextKey: contact[NicknameKey]
            }];
        };
    }
}

CHOptimizedMethod(0, super, void, CouriaInlineReplyViewController_ThirdPartyApp, setupView)
{
    CHSuper(0, CouriaInlineReplyViewController_ThirdPartyApp, setupView);
    self.entryView.shouldShowCharacterCount = NO;
    self.entryView.shouldShowPhotoButton = [self.context[CouriaIdentifier OptionsDomain][CanSendPhotosOption] boolValue];
}

CHOptimizedMethod(0, super, void, CouriaInlineReplyViewController_ThirdPartyApp, interactiveNotificationDidAppear)
{
    CHSuper(0, CouriaInlineReplyViewController_ThirdPartyApp, interactiveNotificationDidAppear);
    NSString *applicationIdentifier = self.context[CouriaIdentifier ApplicationDomain];
    NSString *userIdentifier = self.context[CouriaIdentifier UserDomain];
    if (userIdentifier != nil) {
        self.entryView.hidden = NO;
        self.conversationViewController.view.hidden = NO;
        self.contactsViewController.view.hidden = YES;
        [self.messagingCenter sendNonBlockingMessageName:MarkReadMessage userInfo:@{
            ApplicationKey: applicationIdentifier,
            UserKey: userIdentifier
        }];
    } else {
        self.entryView.hidden = YES;
        self.conversationViewController.view.hidden = YES;
        self.contactsViewController.view.hidden = NO;
        [self.contactsViewController.searchBar becomeFirstResponder];
        [self.contactsViewController searchBar:self.contactsViewController.searchBar textDidChange:nil];
    }
}

CHOptimizedMethod(0, super, void, CouriaInlineReplyViewController_ThirdPartyApp, sendMessage)
{
    CHSuper(0, CouriaInlineReplyViewController_ThirdPartyApp, sendMessage);
    NSString *applicationIdentifier = self.context[CouriaIdentifier ApplicationDomain];
    NSString *userIdentifier = self.context[CouriaIdentifier UserDomain];
    CKComposition *composition = self.entryView.composition;
    void (^ sendMessage)(id) = ^(id content) {
        [self.messagingCenter sendNonBlockingMessageName:SendMessageMessage userInfo:@{
            ApplicationKey: applicationIdentifier,
            UserKey: userIdentifier,
            ContentKey: [NSKeyedArchiver archivedDataWithRootObject:content]
        }];
    };
    sendMessage(composition.text.string);
    for (CKMediaObject *mediaObject in composition.mediaObjects) {
        sendMessage(mediaObject.fileURL);
    }
}

void CouriaUIThirdPartyAppInit(void)
{
    CHLoadLateClass(CouriaInlineReplyViewController);
    CHRegisterClass(CouriaInlineReplyViewController_ThirdPartyApp, CouriaInlineReplyViewController) {
        CHHook(0, CouriaInlineReplyViewController_ThirdPartyApp, setupConversation);
        CHHook(0, CouriaInlineReplyViewController_ThirdPartyApp, setupView);
        CHHook(0, CouriaInlineReplyViewController_ThirdPartyApp, interactiveNotificationDidAppear);
        CHHook(0, CouriaInlineReplyViewController_ThirdPartyApp, sendMessage);
    }
}
