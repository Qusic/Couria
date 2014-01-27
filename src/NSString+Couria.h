#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (Couria)

- (CGSize)messageTextSizeWithWidth:(CGFloat)width;
- (CGSize)messageBackgroundSizeWithWidth:(CGFloat)width;
- (CGFloat)messageCellHeightWithWidth:(CGFloat)width;

@end
