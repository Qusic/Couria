#import "Headers.h"

static CPDistributedMessagingCenter *messagingCenter;

CHDeclareClass(CKInlineReplyViewController)

CHPropertyGetter(CKInlineReplyViewController, messagingCenter, CPDistributedMessagingCenter *)
{
    return messagingCenter;
}

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
    self.entryView.hidden = YES;
    self.conversationViewController.view.hidden = YES;
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
    CGRect entryFrame = CGRectMake(0, conversationHeight, size.width, entryHeight);
    CGRect conversationFrame = CGRectMake(0, 0, size.width, conversationHeight);
    CGRect contactsFrame = CGRectMake(0, 0, size.width, size.height);
    if (!CGRectEqualToRect(self.entryView.frame, entryFrame)) {
        self.entryView.frame = entryFrame;
    }
    if (!CGRectEqualToRect(self.conversationViewController.view.frame, conversationFrame)) {
        self.conversationViewController.view.frame = conversationFrame;
        [self.conversationViewController.collectionView __ck_scrollToBottom:NO];
    }
    if (!CGRectEqualToRect(self.contactsViewController.view.frame, contactsFrame)) {
        self.contactsViewController.view.frame = contactsFrame;
        [self.contactsViewController.tableView __ck_scrollToTop:NO];
    }
}

CHOptimizedMethod(1, self, void, CKInlineReplyViewController, messageEntryViewDidChange, CKMessageEntryView *, entryView)
{
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

CHDeclareClass(CKMessageEntryView)

CHOptimizedMethod(5, self, id, CKMessageEntryView, initWithFrame, CGRect, frame, shouldShowSendButton, BOOL, sendButton, shouldShowSubject, BOOL, subject, shouldShowPhotoButton, BOOL, photoButton, shouldShowCharacterCount, BOOL, characterCount)
{
    photoButton = YES;
    return CHSuper(5, CKMessageEntryView, initWithFrame, frame, shouldShowSendButton, sendButton, shouldShowSubject, subject, shouldShowPhotoButton, photoButton, shouldShowCharacterCount, characterCount);
}

CHOptimizedMethod(1, self, void, CKMessageEntryView, setShouldShowPhotoButton, BOOL, shouldShowPhotoButton)
{
    CHSuper(1, CKMessageEntryView, setShouldShowPhotoButton, shouldShowPhotoButton);
    self.photoButton.hidden = !shouldShowPhotoButton;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

CHConstructor
{
    @autoreleasepool {
        messagingCenter = [CPDistributedMessagingCenter centerNamed:CouriaIdentifier];
        CHLoadLateClass(CKInlineReplyViewController);
        CHHook(0, CKInlineReplyViewController, messagingCenter);
        CHHook(0, CKInlineReplyViewController, conversationViewController);
        CHHook(0, CKInlineReplyViewController, contactsViewController);
        CHHook(0, CKInlineReplyViewController, setupView);
        CHHook(0, CKInlineReplyViewController, preferredContentHeight);
        CHHook(0, CKInlineReplyViewController, viewDidLayoutSubviews);
        CHHook(1, CKInlineReplyViewController, messageEntryViewDidChange);
        CHLoadClass(CKMessageEntryView);
        CHHook(5, CKMessageEntryView, initWithFrame, shouldShowSendButton, shouldShowSubject, shouldShowPhotoButton, shouldShowCharacterCount);
        CHHook(1, CKMessageEntryView, setShouldShowPhotoButton);
    }
}
