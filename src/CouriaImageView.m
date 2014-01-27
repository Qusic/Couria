#import "Headers.h"
#import "CouriaImageView.h"

@implementation CouriaImageView

+ (instancetype)imageViewWithFrame:(CGRect)frame
{
    CouriaImageView *imageView = iOS7() ? [[UIImageView alloc]initWithFrame:frame] : [[self alloc]initWithFrame:frame];
    imageView.userInteractionEnabled = NO;
    imageView.contentMode = UIViewContentModeRedraw;
    return imageView;
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
