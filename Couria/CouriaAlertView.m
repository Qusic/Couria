#import "CouriaAlertView.h"
#import "CouriaController.h"
#import <QuartzCore/QuartzCore.h>

@interface CouriaAlertView ()

@property(retain) CouriaController *controller;

@end

@implementation CouriaAlertView

- (id)initWithController:(CouriaController *)controller
{
    self = [self initWithFrame:CGRectZero];
    if (self) {
        _controller = controller;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_controller.view];
        [self setFrame:CGRectZero];
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    if (UIInterfaceOrientationIsPortrait(((SpringBoard *)[NSClassFromString(@"SpringBoard")sharedApplication])._frontMostAppOrientation)) {
        frame = (CGRect){CGPointZero, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height};
    } else {
        frame = (CGRect){CGPointZero, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width};
    }
    [super setFrame:frame];
    [_controller.view setFrame:CGRectZero];
}

- (void)layoutSubviews
{
    [_controller.view setFrame:CGRectZero];
}

- (void)layout
{
}

- (void)_layoutPopupAlertWithOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated
{
    [self setFrame:CGRectZero];
    [_controller performSelector:@selector(layout) withObject:nil afterDelay:0.1];
}

- (void)_repopup
{
    [self _repopupNoAnimation];
}

- (void)_keyboardWillShow:(NSNotification *)keyboard
{
    [_controller performSelector:@selector(layout) withObject:nil afterDelay:0.1];
}

- (void)_keyboardWillHide:(NSNotification *)keyboard
{
    [_controller performSelector:@selector(layout) withObject:nil afterDelay:0.1+[keyboard.userInfo[UIKeyboardAnimationDurationUserInfoKey]doubleValue]];
}

- (BOOL)_needsKeyboard
{
    return YES;
}

@end
