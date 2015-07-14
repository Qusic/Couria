#import "../Headers.h"

static CPDistributedMessagingCenter *messagingCenter;
static NSUserDefaults *preferences;
static NSMutableArray *customBubbleColors;

CHDeclareClass(CKInlineReplyViewController)
CHDeclareClass(CKMessageEntryView)
CHDeclareClass(CKUIBehavior)
CHPropertyRetainNonatomic(CKInlineReplyViewController, CouriaConversationViewController *, conversationViewController, setConversationViewController)
CHPropertyRetainNonatomic(CKInlineReplyViewController, CouriaContactsViewController *, contactsViewController, setContactsViewController)
CHPropertyRetainNonatomic(CKInlineReplyViewController, CouriaPhotosViewController *, photosViewController, setPhotosViewController)

CHOptimizedMethod(0, self, id, CKInlineReplyViewController, init)
{
    self = CHSuper(0, CKInlineReplyViewController, init);
    if (self) {
        self.conversationViewController = ({
            CKUIBehavior *uiBehavior = [CKUIBehavior sharedBehaviors];
            CGFloat rightBalloonMaxWidth = [uiBehavior rightBalloonMaxWidthForEntryContentViewWidth:self.entryView.contentView.bounds.size.width];
            CGFloat leftBalloonMaxWidth = [uiBehavior leftBalloonMaxWidthForTranscriptWidth:self.view.bounds.size.width marginInsets:uiBehavior.transcriptMarginInsets];
            [[CouriaConversationViewController alloc]initWithConversation:nil rightBalloonMaxWidth:rightBalloonMaxWidth leftBalloonMaxWidth:leftBalloonMaxWidth];
        });
        self.contactsViewController = ({
            [[CouriaContactsViewController alloc]initWithStyle:UITableViewStylePlain];
        });
        self.photosViewController = ({
            [[CouriaPhotosViewController alloc]init];
        });
        [self addChildViewController:self.conversationViewController];
        [self addChildViewController:self.contactsViewController];
        [self addChildViewController:self.photosViewController.viewController];
    }
    return self;
}

CHPropertyGetter(CKInlineReplyViewController, messagingCenter, CPDistributedMessagingCenter *)
{
    return messagingCenter;
}

CHOptimizedMethod(0, self, void, CKInlineReplyViewController, setupConversation)
{
    CHSuper(0, CKInlineReplyViewController, setupConversation);
    NSString *applicationIdentifier = self.context[CouriaIdentifier ApplicationDomain];
    CouriaRegisterDefaults(preferences, applicationIdentifier);
    CouriaBubbleTheme bubbleTheme = [preferences integerForKey:[applicationIdentifier stringByAppendingString:BubbleThemeSetting]];
    self.conversationViewController.bubbleTheme = bubbleTheme;
    self.conversationViewController.bubbleColors = bubbleTheme == CouriaBubbleThemeCustom ? @[
        CouriaColor([preferences stringForKey:[applicationIdentifier stringByAppendingString:CustomMyBubbleColorSetting]]),
        CouriaColor([preferences stringForKey:[applicationIdentifier stringByAppendingString:CustomMyBubbleTextColorSetting]]),
        CouriaColor([preferences stringForKey:[applicationIdentifier stringByAppendingString:CustomOthersBubbleColorSetting]]),
        CouriaColor([preferences stringForKey:[applicationIdentifier stringByAppendingString:CustomOthersBubbleTextColorSetting]])
    ] : nil;
}

CHOptimizedMethod(0, self, void, CKInlineReplyViewController, setupView)
{
    CHSuper(0, CKInlineReplyViewController, setupView);
    [self.view addSubview:self.conversationViewController.view];
    [self.view addSubview:self.contactsViewController.view];
    [self.photosViewController.viewController loadView];
    [self.entryView.photoButton addTarget:self action:@selector(photoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.conversationViewController.view.hidden = YES;
    self.contactsViewController.view.hidden = YES;
    self.entryView.hidden = YES;
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
    BOOL photoShowing = self.photosViewController.view.superview == self.view;
    CGFloat photoHeight = [CKUIBehavior sharedBehaviors].photoPickerMaxPhotoHeight;
    CGFloat entryHeight = MIN([self.entryView sizeThatFits:size].height, size.height - photoHeight * photoShowing);
    CGFloat conversationHeight = size.height - entryHeight - photoHeight * photoShowing;
    self.conversationViewController.view.frame = CGRectMake(0, 0, size.width, conversationHeight);
    self.contactsViewController.view.frame = CGRectMake(0, 0, size.width, size.height);
    self.photosViewController.view.frame = CGRectMake(0, conversationHeight, size.width, photoHeight);
    self.entryView.frame = CGRectMake(0, conversationHeight + photoHeight * photoShowing, size.width, entryHeight);
    if (!self.conversationViewController.collectionView.__ck_isScrolledToBottom) {
        [self.conversationViewController.collectionView __ck_scrollToBottom:NO];
    }
    if (!self.contactsViewController.tableView.__ck_isScrolledToTop) {
        [self.contactsViewController.tableView __ck_scrollToTop:NO];
    }
}

CHOptimizedMethod(1, self, void, CKInlineReplyViewController, messageEntryViewDidChange, CKMessageEntryView *, entryView)
{
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

CHOptimizedMethod(0, self, void, CKInlineReplyViewController, sendMessage)
{
    if (self.photosViewController.view.superview == self.view) {
        [self photoButtonTapped:nil];
    }
    CHSuper(0, CKInlineReplyViewController, sendMessage);
}

CHOptimizedMethod(1, new, void, CKInlineReplyViewController, photoButtonTapped, UIButton *, button)
{
    if (self.photosViewController.view.superview != self.view) {
        [self.view addSubview:self.photosViewController.view];
    } else {
        NSArray *mediaObjects = self.photosViewController.fetchAndClearSelectedPhotos;
        CKComposition *photosComposition = [CKComposition photoPickerCompositionWithMediaObjects:mediaObjects];
        self.entryView.composition = [self.entryView.composition compositionByAppendingComposition:photosComposition];
        [self.photosViewController.view removeFromSuperview];
    }
}

CHOptimizedMethod(5, self, id, CKMessageEntryView, initWithFrame, CGRect, frame, shouldShowSendButton, BOOL, sendButton, shouldShowSubject, BOOL, subject, shouldShowPhotoButton, BOOL, photoButton, shouldShowCharacterCount, BOOL, characterCount)
{
    photoButton = YES;
    self = CHSuper(5, CKMessageEntryView, initWithFrame, frame, shouldShowSendButton, sendButton, shouldShowSubject, subject, shouldShowPhotoButton, photoButton, shouldShowCharacterCount, characterCount);
    if (self) {
        self.shouldShowPhotoButton = NO;
    }
    return self;
}

CHOptimizedMethod(1, self, void, CKMessageEntryView, setShouldShowPhotoButton, BOOL, shouldShowPhotoButton)
{
    CHSuper(1, CKMessageEntryView, setShouldShowPhotoButton, shouldShowPhotoButton);
    self.photoButton.hidden = !shouldShowPhotoButton;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

CHOptimizedMethod(0, self, void, CKMessageEntryView, updateEntryView)
{
    CHSuper(0, CKMessageEntryView, updateEntryView);
    if (self.conversation.chat == nil) {
        self.sendButton.enabled = self.composition.hasContent;
        self.photoButton.enabled = YES;
    }
}

#define CHCKUIBehavior(type, name, value) \
CHOptimizedMethod(0, self, type, CKUIBehavior, name) \
{ \
    static type name; \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, ^{ \
        name = value; \
    }); \
    return name; \
}
CHCKUIBehavior(UIColor *, transcriptBackgroundColor, [UIColor clearColor])
CHCKUIBehavior(BOOL, transcriptCanUseOpaqueMask, NO)
CHCKUIBehavior(BOOL, photoPickerShouldZoomOnSelection, NO)

CHOptimizedMethod(1, self, NSArray *, CKUIBehavior, balloonColorsForColorType, CKBalloonColor, colorType)
{
    return colorType >= CKBalloonColorCouria ? @[customBubbleColors[colorType - CKBalloonColorCouria]] : CHSuper(1, CKUIBehavior, balloonColorsForColorType, colorType);
}

CHOptimizedMethod(1, self, UIColor *, CKUIBehavior, balloonOverlayColorForColorType, CKBalloonColor, colorType)
{
    return colorType >= CKBalloonColorCouria ? [UIColor colorWithWhite:0 alpha:0.1] : CHSuper(1, CKUIBehavior, balloonOverlayColorForColorType, colorType);
}

CHOptimizedMethod(1, new, CKBalloonColor, CKUIBehavior, colorTypeForColor, UIColor *, color)
{
    NSUInteger index = [customBubbleColors indexOfObject:color];
    if (index == NSNotFound) {
        if (customBubbleColors.count >= (UINT8_MAX + 1 - 5)) {
            [customBubbleColors removeObjectAtIndex:0];
        }
        [customBubbleColors addObject:color];
        index = customBubbleColors.count - 1;
    }
    return CKBalloonColorCouria + index;
}

CHConstructor
{
    @autoreleasepool {
        messagingCenter = [CPDistributedMessagingCenter centerNamed:CouriaIdentifier];
        preferences = [[NSUserDefaults alloc]initWithSuiteName:CouriaIdentifier];
        customBubbleColors = [NSMutableArray array];
        CHLoadLateClass(CKInlineReplyViewController);
        CHLoadClass(CKMessageEntryView);
        CHLoadClass(CKUIBehavior);
        CHHook(0, CKInlineReplyViewController, init);
        CHHook(0, CKInlineReplyViewController, messagingCenter);
        CHHook(0, CKInlineReplyViewController, conversationViewController);
        CHHook(1, CKInlineReplyViewController, setConversationViewController);
        CHHook(0, CKInlineReplyViewController, contactsViewController);
        CHHook(1, CKInlineReplyViewController, setContactsViewController);
        CHHook(0, CKInlineReplyViewController, photosViewController);
        CHHook(1, CKInlineReplyViewController, setPhotosViewController);
        CHHook(0, CKInlineReplyViewController, setupConversation);
        CHHook(0, CKInlineReplyViewController, setupView);
        CHHook(0, CKInlineReplyViewController, preferredContentHeight);
        CHHook(0, CKInlineReplyViewController, viewDidLayoutSubviews);
        CHHook(1, CKInlineReplyViewController, messageEntryViewDidChange);
        CHHook(0, CKInlineReplyViewController, sendMessage);
        CHHook(1, CKInlineReplyViewController, photoButtonTapped);
        CHHook(5, CKMessageEntryView, initWithFrame, shouldShowSendButton, shouldShowSubject, shouldShowPhotoButton, shouldShowCharacterCount);
        CHHook(1, CKMessageEntryView, setShouldShowPhotoButton);
        CHHook(0, CKMessageEntryView, updateEntryView);
        CHHook(0, CKUIBehavior, transcriptBackgroundColor);
        CHHook(0, CKUIBehavior, transcriptCanUseOpaqueMask);
        CHHook(0, CKUIBehavior, photoPickerShouldZoomOnSelection);
        CHHook(1, CKUIBehavior, balloonColorsForColorType);
        CHHook(1, CKUIBehavior, balloonOverlayColorForColorType);
        CHHook(1, CKUIBehavior, colorTypeForColor);
    }
}
