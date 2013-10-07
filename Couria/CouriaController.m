#import "CouriaController.h"
#import "CouriaTheme.h"
#import "CouriaSoundEffect.h"
#import "CouriaMessagesView.h"
#import "CouriaContactsView.h"
#import "CouriaFieldView.h"
#import "UIView+Couria.h"
#import "UIScreen+Couria.h"
#import "CALayer+Couria.h"
#import "CouriaImageViewerController.h"
#import "CouriaMoviePlayerController.h"
#import "CouriaMessage.h"
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface CouriaController () <CouriaMessagesViewDelegate, CouriaContactsViewDelegate, UITextViewDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, DoodleViewControllerDelegate>

@property(retain) NSString *applicationIdentifier;
@property(retain) NSString *userIdentifier;
@property(retain) CouriaTheme *theme;
@property(retain) NSString *passcode;
@property(copy) void (^dismissHandler)(void);

@property(strong, nonatomic) UIView *shadowView;
@property(strong, nonatomic) CALayer *borderLayer;
@property(strong, nonatomic) CALayer *shadowLayer;
@property(strong, nonatomic) UIView *mainView;
@property(strong, nonatomic) UIView *topbarView;
@property(strong, nonatomic) UIView *bottombarView;
@property(strong, nonatomic) CouriaMessagesView *messagesView;
@property(strong, nonatomic) CouriaContactsView *contactsView;
@property(strong, nonatomic) UITextField *passcodeField;

@property(strong, nonatomic) UIButton *applicationButton;
@property(strong, nonatomic) UILabel *titleLabel;
@property(strong, nonatomic) UIButton *closeButton;
@property(strong, nonatomic) UIButton *titleButton;
@property(strong, nonatomic) UITextField *titleField;
@property(strong, nonatomic) UIButton *cancelButton;

@property(strong, nonatomic) CouriaFieldView *fieldView;
@property(strong, nonatomic) UIButton *sendButton;
@property(strong, nonatomic) UIButton *photoButton;
@property(strong, nonatomic) UIActionSheet *photoActionSheet;
@property(strong, nonatomic) UIImagePickerController *photoPicker;
@property(strong, nonatomic) UIPopoverController *photoPickerPopover;
@property(retain) id mediaMessageContent;

@property(strong, nonatomic) CouriaImageViewerController *imageViewer;

@property(strong, nonatomic) CouriaAlert *alert;
@property(strong, nonatomic) UIViewController *presentedController;

@end

@implementation CouriaController

- (id)initWithApplication:(NSString *)applicationIdentifier user:(NSString *)userIdentifier dismissHandler:(void (^)(void))dismissHandler
{
    self = [self init];
    if (self) {
        _applicationIdentifier = applicationIdentifier;
        _userIdentifier = userIdentifier;
        _theme = [CouriaTheme themeWithIdentifier:CouriaGetUserDefaultForKey(applicationIdentifier, ThemeKey)];
        if ([CouriaGetUserDefaultForKey(_applicationIdentifier, [NSClassFromString(@"SBAwayController")sharedAwayController].isLocked ? RequirePasscodeWhenLockedKey : RequirePasscodeWhenUnlockedKey)boolValue]) {
            _passcode = CouriaGetUserDefaultForKey(_applicationIdentifier, PasscodeKey);
        }
        _dismissHandler = dismissHandler;
    }
    return self;
}

+ (SBAlertManager *)sharedAlertManager
{
    static SBAlertManager *alertManager;
    if (alertManager == nil) {
        if (iOS7()) {
            alertManager = [[NSClassFromString(@"SBAlertManager") alloc]initWithScreen:[UIScreen mainScreen]];
        } else {
            alertManager = [[NSClassFromString(@"SBAlertManager") alloc]init];
        }
    }
    return alertManager;
}

- (void)loadView
{
    _shadowView = [[UIView alloc]initWithFrame:CGRectZero];
    _shadowView.layer.anchorPoint = CGPointMake(0.5, 0);
    _shadowView.layer.position = CGPointMake([UIScreen mainScreen].viewFrame.size.width/2, -300);
    _shadowView.layer.bounds = (CGRect){CGPointZero, CGSizeMake(300, 250)};
    _borderLayer = [CALayer borderLayerWithSize:CGSizeMake(300, 250) cornerRadius:4];
    _shadowLayer = [CALayer shadowLayerWithSize:CGSizeMake(300, 250) cornerRadius:4];
    _mainView = [UIView mainViewWithFrame:CGRectMake(0, 0, 300, 250) cornerRadius:4 theme:_theme];
    _topbarView = [UIView topbarViewViewWithFrame:CGRectMake(0, 0, 300, 44) theme:_theme];
    _bottombarView = [UIView bottombarViewWithFrame:CGRectMake(0, 210, 300, 40) theme:_theme];
    _messagesView = [[CouriaMessagesView alloc]initWithFrame:CGRectMake(0, 44, 300, 166) delegate:self theme:_theme];
    [_messagesView setApplication:_applicationIdentifier user:_userIdentifier];

    _applicationButton = [UIView buttonWithApplicationIcon:_applicationIdentifier];
    _applicationButton.frame = CGRectMake(7, 7, 30, 30);
    _applicationButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    [_applicationButton addTarget:self action:@selector(applicationButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    _titleLabel = [UIView titleLabelWithTheme:_theme title:CouriaGetNickname(_applicationIdentifier, _userIdentifier)];
    _titleLabel.frame = CGRectMake(74, 7, 152, 30);
    _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    _closeButton = [UIView buttonWithTheme:_theme title:CouriaLocalizedString(@"CLOSE")];
    _closeButton.frame = CGRectMake(233, 7, 60, 30);
    _closeButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
    [_closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];

    _fieldView = [[CouriaFieldView alloc]initWithFrame:CGRectMake(6, 0, 229, 40) delegate:self theme:_theme];
    _sendButton = [UIView sendButtonWithTheme:_theme title:CouriaLocalizedString(@"SEND")];
    _sendButton.frame = CGRectMake(235, 8, 59, 26);
    _sendButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [_sendButton addTarget:self action:@selector(sendButtonAction:) forControlEvents:UIControlEventTouchUpInside];

    _imageViewer = [[CouriaImageViewerController alloc]init];

    [_topbarView addSubview:_applicationButton];
    [_topbarView addSubview:_closeButton];
    [_topbarView addSubview:_titleLabel];
    [_bottombarView addSubview:_fieldView];
    [_bottombarView addSubview:_sendButton];
    [_mainView addSubview:_messagesView];
    [_mainView addSubview:_topbarView];
    [_mainView addSubview:_bottombarView];
    [_shadowLayer addSublayer:_borderLayer];
    [_shadowView.layer addSublayer:_shadowLayer];
    [_shadowView addSubview:_mainView];

    if (CouriaCanSendPhoto(_applicationIdentifier) || CouriaCanSendMovie(_applicationIdentifier)) {
        _fieldView.frame = CGRectMake(38, 0, 197, 40);
        _photoButton = [UIView photoButtonWithTheme:_theme];
        _photoButton.frame = CGRectMake(6, 8, 26, 27);
        _photoButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
        [_photoButton addTarget:self action:@selector(photoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_bottombarView addSubview:_photoButton];
        _photoPicker = [[UIImagePickerController alloc]init];
        _photoPicker.delegate = self;
        NSMutableArray *mediaTypes = [NSMutableArray array];
        if (CouriaCanSendPhoto(_applicationIdentifier)) { [mediaTypes addObject:(NSString *)kUTTypeImage]; }
        if (CouriaCanSendMovie(_applicationIdentifier)) { [mediaTypes addObject:(NSString *)kUTTypeMovie]; }
        _photoPicker.mediaTypes = mediaTypes;
        _photoPicker.allowsEditing = NO;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            _photoPickerPopover = [[UIPopoverController alloc]initWithContentViewController:_photoPicker];
        }
    }

    if (CouriaGetContacts(_applicationIdentifier, nil) != nil) {
        _contactsView = [[CouriaContactsView alloc]initWithFrame:CGRectMake(0, 44, 300, 206) delegate:self theme:_theme];
        [_contactsView setApplication:_applicationIdentifier keyword:@""];
        _titleButton = [UIView lightButton];
        _titleButton.frame = CGRectMake(0, 0, 152, 30);
        _titleButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_titleButton addTarget:self action:@selector(titleButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _titleField = [UIView titleFieldWithTheme:_theme];
        _titleField.frame = CGRectMake(74, 7, 152, 30);
        _titleField.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        [_titleField addTarget:self action:@selector(titleFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        _cancelButton = [UIView buttonWithTheme:_theme title:CouriaLocalizedString(@"CANCEL")];
        _cancelButton.frame = CGRectMake(233, 7, 60, 30);
        _cancelButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
        [_cancelButton addTarget:self action:@selector(cancelButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_titleLabel addSubview:_titleButton];
        [_topbarView addSubview:_titleField];
        [_topbarView addSubview:_cancelButton];
        [_mainView addSubview:_contactsView];
        [_topbarView sendSubviewToBack:_titleField];
        _titleField.alpha = 0;
        [_topbarView sendSubviewToBack:_cancelButton];
        _cancelButton.alpha = 0;
        [_mainView sendSubviewToBack:_contactsView];
        _contactsView.alpha = 0;
    }

    if (_passcode.length > 0) {
        _passcodeField = [UIView passcodeFieldWithTheme:_theme keyboardType:UIKeyboardTypeNumberPad];
        _passcodeField.frame = CGRectMake(0, 147 - 25, 300, 50);
        _passcodeField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_passcodeField addTarget:self action:@selector(passcodeFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        [_mainView addSubview:_passcodeField];
        _messagesView.alpha = 0;
        _bottombarView.alpha = 0;
        _titleLabel.alpha = 0;
        _titleButton.enabled = NO;
    }

    self.view = [[UIView alloc]initWithFrame:UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? [UIScreen mainScreen].bounds : [UIScreen mainScreen].viewFrame];
    [self.view addSubview:_shadowView];
}

- (void)present
{
    [(SBOrientationLockManager *)[NSClassFromString(@"SBOrientationLockManager")sharedInstance]setLockOverrideEnabled:YES forReason:CouriaIdentifier];
    SBAlertManager *alertManager = [self.class sharedAlertManager];
    [alertManager deactivateAll];
    _alert = [[NSClassFromString(@"CouriaAlert") alloc]init];
    [_alert setOrientationChangedEventsEnabled:YES];
    [alertManager activate:_alert];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardFrameChanged:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardFrameChanged:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(newBulletinPublished:) name:@NewBulletinPublishedNotification object:nil];
    [_alert.display addSubview:self.view];
}

- (void)dismiss
{
    [(SBOrientationLockManager *)[NSClassFromString(@"SBOrientationLockManager")sharedInstance]setLockOverrideEnabled:NO forReason:CouriaIdentifier];
    [UIView animateWithDuration:0.25 animations:^{
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter]removeObserver:self name:@NewBulletinPublishedNotification object:nil];
        if (_dismissHandler != nil) {
            _dismissHandler();
        }
        [[self.class sharedAlertManager]deactivateAll];
        _alert = nil;
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (_passcode.length == 0) {
        [self showMainView:NO];
    } else {
        [_passcodeField becomeFirstResponder];
    }
}

- (void)showMainView:(BOOL)animated
{
    if (_userIdentifier != nil) {
        [self showMessagesView:animated];
    } else {
        [self showContactsView:animated];
    }
}

- (void)showMessagesView:(BOOL)animated
{
    if (_contactsView != nil) {
        NSArray *viewsToShow = @[_messagesView, _bottombarView, _titleLabel, _closeButton];
        NSArray *viewsToHide = @[_contactsView, _titleField, _cancelButton];
        NSArray *viewsToKeepFront = @[_topbarView];
        for (UIView *view in viewsToShow) {
            view.alpha = 0;
            [view.superview bringSubviewToFront:view];
        }
        for (UIView *view in viewsToKeepFront) {
            [view.superview bringSubviewToFront:view];
        }
        [UIView animateWithDuration:animated ? 0.25 : 0 animations:^{
            for (UIView *view in viewsToShow) {
                view.alpha = 1;
            }
            for (UIView *view in viewsToHide) {
                view.alpha = 0;
            }
        } completion:^(BOOL finished) {
            [_fieldView.textView becomeFirstResponder];
        }];
        [_messagesView refreshData];
        CouriaMarkRead(_applicationIdentifier, _userIdentifier);
    } else {
        [_fieldView.textView becomeFirstResponder];
        [_messagesView refreshData];
        CouriaMarkRead(_applicationIdentifier, _userIdentifier);
    }
}

- (void)showContactsView:(BOOL)animated
{
    if (_contactsView != nil) {
        NSArray *viewsToShow = @[_contactsView, _titleField, _cancelButton];
        NSArray *viewsToHide = @[_messagesView, _bottombarView, _titleLabel, _closeButton];
        NSArray *viewsToKeepFront = @[_topbarView];
        for (UIView *view in viewsToShow) {
            view.alpha = 0;
            [view.superview bringSubviewToFront:view];
        }
        for (UIView *view in viewsToKeepFront) {
            [view.superview bringSubviewToFront:view];
        }
        [UIView animateWithDuration:animated ? 0.25 : 0 animations:^{
            for (UIView *view in viewsToShow) {
                view.alpha = 1;
            }
            for (UIView *view in viewsToHide) {
                view.alpha = 0;
            }
        } completion:^(BOOL finished) {
            [_titleField becomeFirstResponder];
        }];
        [_contactsView refreshData];
    }
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion
{
    if (viewControllerToPresent == nil) {
        return;
    }
    [self.view endEditing:YES];
    _presentedController = viewControllerToPresent;
    CGRect startFrame = [UIScreen mainScreen].viewFrame, endFrame = startFrame;
    startFrame.origin.y += endFrame.size.height;
    if (flag) {
        viewControllerToPresent.view.frame = startFrame;
        [viewControllerToPresent viewWillAppear:YES];
        [self.view addSubview:viewControllerToPresent.view];
        [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            viewControllerToPresent.view.frame = endFrame;
        } completion:^(BOOL finished) {
            [viewControllerToPresent viewDidAppear:YES];
            if (completion) {
                completion();
            }
        }];
    } else {
        viewControllerToPresent.view.frame = endFrame;
        [viewControllerToPresent viewWillAppear:NO];
        [self.view addSubview:viewControllerToPresent.view];
        [viewControllerToPresent viewDidAppear:NO];
        if (completion) {
            completion();
        }
    }
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    if (_presentedController == nil) {
        return;
    }
    CGRect startFrame = [UIScreen mainScreen].viewFrame, endFrame = startFrame;
    endFrame.origin.y += startFrame.size.height;
    if (flag) {
        _presentedController.view.frame = startFrame;
        [_presentedController viewWillDisappear:YES];
        [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _presentedController.view.frame = endFrame;
        } completion:^(BOOL finished) {
            [_presentedController.view removeFromSuperview];
            [_presentedController viewDidDisappear:YES];
            _presentedController = nil;
            if (completion) {
                completion();
            }
        }];
    } else {
        [_presentedController viewWillDisappear:NO];
        [_presentedController.view removeFromSuperview];
        [_presentedController viewDidDisappear:NO];
        _presentedController = nil;
        if (completion) {
            completion();
        }
    }
}

- (void)keyboardFrameChanged:(NSNotification *)notification
{
    UIInterfaceOrientation orientation = [UIScreen mainScreen].frontMostAppOrientation;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && UIInterfaceOrientationIsLandscape(orientation)) {
        self.view.transform = CGAffineTransformMakeRotation(orientation == UIInterfaceOrientationLandscapeLeft ? -M_PI_2 : M_PI_2);
        self.view.frame = [UIScreen mainScreen].bounds;
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.view.frame = [UIScreen mainScreen].viewFrame;
    }
    CGFloat xMargin = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? 10 : 100;
    CGFloat yMargin = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? 10 : 50;
    CGFloat topMargin = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && UIInterfaceOrientationIsLandscape(orientation)) ? 0 : 20;
    CGSize viewSize = [UIScreen mainScreen].viewFrame.size;
    CGSize keyboardSize = [notification.userInfo[UIKeyboardFrameEndUserInfoKey]CGRectValue].size;
    CGFloat keyboardHeight = [notification.name isEqualToString:UIKeyboardWillHideNotification] ? 0 : (UIInterfaceOrientationIsPortrait(orientation) ? keyboardSize.height : keyboardSize.width);
    CGFloat width = viewSize.width - xMargin * 2;
    CGFloat height = viewSize.height - yMargin * 2 - topMargin - keyboardHeight;
    CGRect startFrame;
    if (_shadowView.frame.origin.y == yMargin + topMargin) {
        startFrame = _shadowView.frame;
    } else {
        startFrame = CGRectMake(xMargin, - (height + topMargin), width, height);
    }
    CGRect endFrame = CGRectMake(xMargin, yMargin + topMargin, width, height);
    CGRect startBounds = {CGPointZero, startFrame.size};
    CGRect endBounds = {CGPointZero, endFrame.size};
    CGPathRef startPath = [UIBezierPath bezierPathWithRoundedRect:startBounds cornerRadius:4].CGPath;
    CGPathRef endPath = [UIBezierPath bezierPathWithRoundedRect:endBounds cornerRadius:4].CGPath;

    _shadowView.frame = startFrame;
    _borderLayer.shadowPath = startPath;
    _shadowLayer.shadowPath = startPath;

    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _shadowView.frame = endFrame;
    } completion:^(BOOL finished) {
        [_messagesView scrollToBottomAnimated:YES];
        [_contactsView scrollToTopAnimated:YES];
    }];
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.25];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    CABasicAnimation *shadowAnimation = [CABasicAnimation animationWithKeyPath:@"shadowPath"];
    shadowAnimation.fromValue = (__bridge id)startPath;
    shadowAnimation.toValue = (__bridge id)endPath;
    [_borderLayer addAnimation:shadowAnimation forKey:nil];
    [_shadowLayer addAnimation:shadowAnimation forKey:nil];
    [CATransaction commit];
    _borderLayer.shadowPath = endPath;
    _shadowLayer.shadowPath = endPath;
}

- (void)newBulletinPublished:(NSNotification *)notification
{
    BBBulletin *bulletin = notification.userInfo[BulletinKey];
    if ([_applicationIdentifier isEqualToString:bulletin.sectionID] && [CouriaGetUserIdentifier(bulletin)isEqualToString:_userIdentifier]) {
        [_messagesView refreshData];
        if (_passcodeField.superview == nil) {
            CouriaMarkRead(_applicationIdentifier, _userIdentifier);
        }
    }
}

- (void)messagesView:(CouriaMessagesView *)messagesView didSelectMessage:(id<CouriaMessage>)message
{
    id media = message.media;
    if ([media isKindOfClass:UIImage.class]) {
        [_fieldView.textView endEditing:YES];
        [_imageViewer viewImage:media inView:self.view];
    } else if ([media isKindOfClass:NSURL.class]) {
        CouriaMoviePlayerController *moviePlayer = [[CouriaMoviePlayerController alloc]initWithContentURL:media];
        [moviePlayer playInView:self.view];
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    CGFloat mainHeight = _mainView.bounds.size.height;
    CGFloat maxViewHeight = mainHeight - _topbarView.bounds.size.height;
    CGFloat viewHeight = 0;
    if (iOS7()) {
        //TODO: text not displaying properly. sometimes crash when moving the caret. need more test and investigation on real device
        NSString *text = textView.text;
        if ([text hasSuffix:@"\n"]) {
            text = [text stringByAppendingString:@" "];
        }
        CGFloat textHeight = [text boundingRectWithSize:CGSizeMake(textView.bounds.size.width - 10, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: textView.font} context:nil].size.height;
        viewHeight = MAX(40, MIN(textHeight + 21, maxViewHeight));
    } else {
        CGFloat textHeight = textView.contentSize.height;
        viewHeight = MAX(40, MIN(textHeight + 4, maxViewHeight));
    }

    textView.scrollEnabled = (viewHeight == maxViewHeight);
    CGRect startFrame = _bottombarView.frame, endFrame = startFrame;
    endFrame.origin.y = mainHeight - viewHeight;
    endFrame.size.height = viewHeight;
    UIEdgeInsets startInset = _messagesView.contentInset, endInset = startInset;
    endInset.bottom += endFrame.size.height - startFrame.size.height;
    CGPoint startOffset = _messagesView.contentOffset, endOffset = startOffset;
    endOffset.y += endFrame.size.height - startFrame.size.height;
    endOffset.y = MAX(endOffset.y, 0.0f);
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
        _bottombarView.frame = endFrame;
        _messagesView.contentInset = endInset;
        _messagesView.scrollIndicatorInsets = endInset;
        _messagesView.contentOffset = endOffset;
    } completion:NULL];
}

- (void)applicationButtonAction:(id)sender
{
    [self dismiss];
    CouriaOpenApp(_applicationIdentifier);
}

- (void)closeButtonAction:(UIButton *)button
{
    [self dismiss];
}

- (void)titleButtonAction:(UIButton *)button
{
    [self showContactsView:YES];
}

- (void)cancelButtonAction:(UIButton *)button
{
    if (_userIdentifier != nil) {
        [self showMessagesView:YES];
    } else {
        [self dismiss];
    }
}

- (void)sendButtonAction:(UIButton *)button
{
    NSString *text = _fieldView.textView.text;
    id media = _mediaMessageContent;
    if (text.length == 0 && media == nil) {
        return;
    }
    CouriaMessage *message = [[CouriaMessage alloc]init];
    message.text = text;
    message.media = media;
    message.outgoing = YES;
    CouriaSendMessage(_applicationIdentifier, _userIdentifier, message);
    [CouriaSoundEffect playMessageSentSound];
    [self dismiss];
}

- (void)photoButtonAction:(UIButton *)button
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [_fieldView.textView endEditing:YES];
    }
    _photoActionSheet = [[UIActionSheet alloc]init];
    _photoActionSheet.delegate = self;
    if (_mediaMessageContent == nil) {
        _photoActionSheet.tag = 0;
        [_photoActionSheet addButtonWithTitle:CouriaLocalizedString(@"CAMERA")];
        [_photoActionSheet addButtonWithTitle:CouriaLocalizedString(@"LIBRARY")];
        [_photoActionSheet addButtonWithTitle:CouriaLocalizedString(@"DOODLE")];
    } else {
        _photoActionSheet.tag = 1;
        [_photoActionSheet addButtonWithTitle:CouriaLocalizedString(@"VIEW")];
        [_photoActionSheet addButtonWithTitle:CouriaLocalizedString(@"REMOVE")];
    }
    _photoActionSheet.cancelButtonIndex = [_photoActionSheet addButtonWithTitle:CouriaLocalizedString(@"CANCEL")];
    [_photoActionSheet showFromRect:[button convertRect:button.bounds toView:self.view] inView:self.view animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case 0:
            switch (buttonIndex) {
                case 0: {
                    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                        _photoPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                            [self presentViewController:_photoPicker animated:YES completion:NULL];
                        } else {
                            [_photoPickerPopover presentPopoverFromRect:[_photoButton convertRect:_photoButton.bounds toView:self.view] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                        }
                    } else {
                        [[[UIAlertView alloc]initWithTitle:nil message:CouriaLocalizedString(@"CAMERA_NOT_AVAILABLE") delegate:nil cancelButtonTitle:CouriaLocalizedString(@"OK") otherButtonTitles:nil]show];
                    }
                    break;
                }
                case 1: {
                    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
                        _photoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                            [self presentViewController:_photoPicker animated:YES completion:NULL];
                        } else {
                            [_photoPickerPopover presentPopoverFromRect:[_photoButton convertRect:_photoButton.bounds toView:self.view] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                        }
                    } else {
                        [[[UIAlertView alloc]initWithTitle:nil message:CouriaLocalizedString(@"LIBRARY_NOT_AVAILABLE") delegate:nil cancelButtonTitle:CouriaLocalizedString(@"OK") otherButtonTitles:nil]show];
                    }
                    break;
                }
                case 2: {
                    Class DoodleViewController$ = NSClassFromString(@"DoodleViewController");
                    if (DoodleViewController$ != Nil) {
                        UINavigationController *doodleController = [[UINavigationController alloc]initWithRootViewController:[[DoodleViewController$ alloc]initWithDelegate:self]];
                        [self presentViewController:doodleController animated:YES completion:NULL];
                    } else {
                        [[[UIAlertView alloc]initWithTitle:nil message:CouriaLocalizedString(@"DOODLE_NOT_AVAILABLE") delegate:nil cancelButtonTitle:CouriaLocalizedString(@"OK") otherButtonTitles:nil]show];
                    }
                    break;
                }
                default:
                    break;
            }
            break;
        case 1:
            switch (buttonIndex) {
                case 0: {
                    if ([_mediaMessageContent isKindOfClass:UIImage.class]) {
                        [_fieldView.textView endEditing:YES];
                        [_imageViewer viewImage:_mediaMessageContent inView:self.view];
                    } else if ([_mediaMessageContent isKindOfClass:NSURL.class]) {
                        CouriaMoviePlayerController *moviePlayer = [[CouriaMoviePlayerController alloc]initWithContentURL:_mediaMessageContent];
                        [moviePlayer playInView:self.view];
                    }
                    break;
                }
                case 1: {
                    _mediaMessageContent = nil;
                    break;
                }
                default:
                    break;
            }
            break;
        default:
            break;
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if ([info[UIImagePickerControllerMediaType]isEqualToString:(NSString *)kUTTypeImage]) {
        _mediaMessageContent = info[UIImagePickerControllerOriginalImage];
    } else if ([info[UIImagePickerControllerMediaType]isEqualToString:(NSString *)kUTTypeMovie]) {
        _mediaMessageContent = info[UIImagePickerControllerMediaURL];
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else {
        [_photoPickerPopover dismissPopoverAnimated:YES];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else {
        [_photoPickerPopover dismissPopoverAnimated:YES];
    }
}

- (void)doodle:(DoodleViewController *)doodleViewController didFinishWithImage:(UIImage *)image
{
    if (image != nil) {
        _mediaMessageContent = image;
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)titleFieldDidChange:(UITextField *)titleField
{
    [_contactsView setApplication:_applicationIdentifier keyword:titleField.text];
    [_contactsView refreshData];
}

- (void)contactsView:(CouriaContactsView *)contactsView didSelectContact:(NSString *)userIdentifier
{
    _userIdentifier = userIdentifier;
    [_titleLabel setText:CouriaGetNickname(_applicationIdentifier, userIdentifier)];
    [_messagesView setApplication:_applicationIdentifier user:userIdentifier];
    [self showMessagesView:YES];
}

- (void)passcodeFieldDidChange:(UITextField *)passcodeField
{
    if ([passcodeField.text isEqualToString:_passcode]) {
        _titleButton.enabled = YES;
        [self showMainView:YES];
        [UIView animateWithDuration:0.25 animations:^{
            _passcodeField.alpha = 0;
        } completion:^(BOOL finished) {
            [_passcodeField removeFromSuperview];
        }];
    }
}

@end
