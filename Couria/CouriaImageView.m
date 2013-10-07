#import "CouriaImageView.h"

@implementation CouriaImageView

- (id)initWithFrame:(CGRect)frame
{
    //TODO: crash relating to resizing may not exist on ios7. if so, use UIImageView on ios7
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [_image drawInRect:rect];
}

@end
