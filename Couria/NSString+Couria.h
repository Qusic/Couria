#import <Foundation/Foundation.h>

@interface NSString (Couria)

- (CGSize)messageTextSizeWithWidth:(CGFloat)width;
- (CGSize)messageBackgroundSizeWithWidth:(CGFloat)width;
- (CGFloat)messageCellHeightWithWidth:(CGFloat)width;

@end
