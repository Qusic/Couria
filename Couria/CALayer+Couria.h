#import <QuartzCore/QuartzCore.h>

@interface CALayer (Couria)

+ (CALayer *)borderLayerWithSize:(CGSize)size cornerRadius:(CGFloat)cornerRadius;
+ (CALayer *)shadowLayerWithSize:(CGSize)size cornerRadius:(CGFloat)cornerRadius;

@end
