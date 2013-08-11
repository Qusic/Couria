#import "CouriaMoviePlayerController.h"
#import "UIView+Couria.h"

@interface CouriaMoviePlayerController ()

@end

@implementation CouriaMoviePlayerController

- (void)playInView:(UIView *)view
{
    CGRect startFrame = view.frame, endFrame = startFrame;
    startFrame.origin.y += endFrame.size.height;
    [view addSubview:self.view];
    self.view.frame = startFrame;
    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationCurveEaseInOut animations:^{
        self.view.frame = endFrame;
    } completion:^(BOOL finished) {
        NSArray *buttons = [self.view findViewsUsingBlock:^BOOL(UIView *view) {
            return [view isKindOfClass:UINavigationButton.class];
        }];
        for (UINavigationButton *button in buttons) {
            if (button.style == UIBarButtonItemStyleDone) {
                [button addTarget:self action:@selector(doneAction:) forControlEvents:UIControlEventTouchUpInside];
                break;
            }
        }
    }];
}

- (void)doneAction:(id)sender
{
    CGRect startFrame = self.view.superview.frame, endFrame = startFrame;
    endFrame.origin.y += startFrame.size.height;
    self.view.frame = startFrame;
    [UIView animateWithDuration:0.4 animations:^{
        self.view.frame = endFrame;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
}

@end
