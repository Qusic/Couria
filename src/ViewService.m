#import "Headers.h"

CHDeclareClass(CKInlineReplyViewController)

CHDeclareProperty(CKInlineReplyViewController, conversationViewController)
CHPropertyGetter(CKInlineReplyViewController, conversationViewController, CouriaConversationViewController *)
{
    CouriaConversationViewController *viewController = CHPropertyGetValue(CKInlineReplyViewController, conversationViewController);
    if (viewController == nil) {
        CKUIBehavior *uiBehavior = [CKUIBehavior sharedBehaviors];
        CGFloat rightBalloonMaxWidth = [uiBehavior rightBalloonMaxWidthForEntryContentViewWidth:self.entryView.contentView.bounds.size.width];
        CGFloat leftBalloonMaxWidth = [uiBehavior leftBalloonMaxWidthForTranscriptWidth:self.view.bounds.size.width marginInsets:uiBehavior.transcriptMarginInsets];
        viewController = [[CouriaConversationViewController alloc]initWithConversation:nil rightBalloonMaxWidth:rightBalloonMaxWidth leftBalloonMaxWidth:leftBalloonMaxWidth];
        viewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        CHPropertySetValue(CKInlineReplyViewController, conversationViewController, viewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return viewController;
}

CHDeclareProperty(CKInlineReplyViewController, contactsViewController)
CHPropertyGetter(CKInlineReplyViewController, contactsViewController, CouriaContactsViewController *)
{
    CouriaContactsViewController *viewController = CHPropertyGetValue(CKInlineReplyViewController, contactsViewController);
    if (viewController == nil) {
        viewController = [[CouriaContactsViewController alloc]initWithStyle:UITableViewStylePlain];
        viewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        CHPropertySetValue(CKInlineReplyViewController, contactsViewController, viewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return viewController;
}

CHOptimizedMethod(0, self, void, CKInlineReplyViewController, setupView)
{
    CHSuper(0, CKInlineReplyViewController, setupView);
    [self.view addSubview:self.conversationViewController.view];
    [self.view addSubview:self.contactsViewController.view];
    self.contactsViewController.view.hidden = YES;
}

CHOptimizedMethod(0, self, CGFloat, CKInlineReplyViewController, preferredContentHeight)
{
    return self.maximumHeight ?: CHSuper(0, CKInlineReplyViewController, preferredContentHeight);
}

CHOptimizedMethod(0, self, void, CKInlineReplyViewController, viewDidLayoutSubviews)
{
    CHSuper(0, CKInlineReplyViewController, viewDidLayoutSubviews);
    CGFloat contentHeight = self.preferredContentHeight;
    if (self.view.bounds.size.height != contentHeight) {
        [self requestPreferredContentHeight:contentHeight];
    }
    CGSize size = self.view.bounds.size;
    CGFloat entryHeight = MIN([self.entryView sizeThatFits:size].height, size.height);
    CGFloat conversationHeight = size.height - entryHeight;
    self.conversationViewController.view.frame = CGRectMake(0, 0, size.width, conversationHeight);
    self.entryView.frame = CGRectMake(0, conversationHeight, size.width, entryHeight);
}

CHOptimizedMethod(1, self, void, CKInlineReplyViewController, messageEntryViewDidChange, CKMessageEntryView *, entryView)
{
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

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
    }
}

CHOptimizedMethod(1, super, void, CouriaInlineReplyViewController_MobileSMSApp, messageEntryViewDidChange, CKMessageEntryView *, entryView)
{
    CHSuper(1, CouriaInlineReplyViewController_MobileSMSApp, messageEntryViewDidChange, entryView);
    [self.typingUpdater setNeedsUpdate];
    [self updateSendButton];
}

CHDeclareClass(CouriaInlineReplyViewController_ThirdPartyApp)

CHOptimizedMethod(0, super, void, CouriaInlineReplyViewController_ThirdPartyApp, setupConversation)
{
    //TODO: third party apps
}

CHConstructor
{
    @autoreleasepool {
        CHLoadLateClass(CKInlineReplyViewController);
        CHHook(0, CKInlineReplyViewController, conversationViewController);
        CHHook(0, CKInlineReplyViewController, contactsViewController);
        CHHook(0, CKInlineReplyViewController, setupView);
        CHHook(0, CKInlineReplyViewController, preferredContentHeight);
        CHHook(0, CKInlineReplyViewController, viewDidLayoutSubviews);
        CHHook(1, CKInlineReplyViewController, messageEntryViewDidChange);
        CHRegisterClass(CouriaInlineReplyViewController_MobileSMSApp, CKInlineReplyViewController) {
            CHHook(0, CouriaInlineReplyViewController_MobileSMSApp, setupConversation);
            CHHook(1, CouriaInlineReplyViewController_MobileSMSApp, messageEntryViewDidChange);
        }
        CHRegisterClass(CouriaInlineReplyViewController_ThirdPartyApp, CKInlineReplyViewController) {
            CHHook(0, CouriaInlineReplyViewController_ThirdPartyApp, setupConversation);
        }
    }
}
