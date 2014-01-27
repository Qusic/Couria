#import "NSString+Couria.h"

@implementation NSString (Couria)

- (CGSize)messageTextSizeWithWidth:(CGFloat)width
{
    CGSize textSize = [self sizeWithFont:[UIFont systemFontOfSize:15]constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)];
    return textSize;
}

- (CGSize)messageBackgroundSizeWithWidth:(CGFloat)width
{
    CGSize textSize = [self messageTextSizeWithWidth:width];
    CGSize backgroundSize = CGSizeMake(textSize.width + 35, textSize.height + 12);
    return backgroundSize;
}

- (CGFloat)messageCellHeightWithWidth:(CGFloat)width
{
    CGSize backgroundSize = [self messageBackgroundSizeWithWidth:width];
    CGFloat cellHeight = backgroundSize.height + 4;
    return cellHeight;
}

@end
