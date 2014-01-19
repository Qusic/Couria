#import "CALayer+Couria.h"

@implementation CALayer (Couria)

+ (CALayer *)borderLayerWithSize:(CGSize)size cornerRadius:(CGFloat)cornerRadius
{
    CALayer *layer = [CALayer layer];
    layer.anchorPoint = CGPointMake(0.5, 0);
    layer.position = CGPointZero;
    layer.cornerRadius = cornerRadius;
    layer.masksToBounds = NO;
    layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:(CGRect){CGPointZero, size} cornerRadius:cornerRadius].CGPath;
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOpacity = 1;
    layer.shadowRadius = 1;
    layer.shadowOffset = CGSizeZero;
    return layer;
}

+ (CALayer *)shadowLayerWithSize:(CGSize)size cornerRadius:(CGFloat)cornerRadius
{
    CALayer *layer = [CALayer layer];
    layer.anchorPoint = CGPointMake(0.5, 0);
    layer.position = CGPointZero;
    layer.cornerRadius = cornerRadius;
    layer.masksToBounds = NO;
    layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:(CGRect){CGPointZero, size} cornerRadius:cornerRadius].CGPath;
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOpacity = iOS7() ? 0 : 1;
    layer.shadowRadius = 20;
    layer.shadowOffset = CGSizeMake(0, 1);
    return layer;
}

@end
