#import "CouriaView.h"

@implementation CouriaView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self setFrame:CGRectZero];
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    if (self.superview) {
        frame = self.superview.bounds;
    } else {
        if (UIInterfaceOrientationIsPortrait(((SpringBoard *)[NSClassFromString(@"SpringBoard")sharedApplication])._frontMostAppOrientation)) {
            frame = (CGRect){CGPointZero, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height};
        } else {
            frame = (CGRect){CGPointZero, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width};
        }
    }
    [super setFrame:frame];
}

@end
