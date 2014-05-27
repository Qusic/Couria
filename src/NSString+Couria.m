#import "NSString+Couria.h"

@implementation NSString (Couria)

- (CGSize)messageTextSizeWithWidth:(CGFloat)width fontSize:(CGFloat)fontSize
{
    CGSize textSize = [self sizeWithFont:[UIFont systemFontOfSize:fontSize]constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)];
    return textSize;
}

- (CGSize)messageBackgroundSizeWithWidth:(CGFloat)width fontSize:(CGFloat)fontSize
{
    CGSize textSize = [self messageTextSizeWithWidth:width fontSize:fontSize];
    CGSize backgroundSize = CGSizeMake(textSize.width + 35, textSize.height + 12);
    return backgroundSize;
}

- (CGFloat)messageCellHeightWithWidth:(CGFloat)width fontSize:(CGFloat)fontSize
{
    CGSize backgroundSize = [self messageBackgroundSizeWithWidth:width fontSize:fontSize];
    CGFloat cellHeight = backgroundSize.height + 4;
    return cellHeight;
}

@end
