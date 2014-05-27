#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (Couria)

- (CGSize)messageTextSizeWithWidth:(CGFloat)width fontSize:(CGFloat)fontSize;
- (CGSize)messageBackgroundSizeWithWidth:(CGFloat)width fontSize:(CGFloat)fontSize;
- (CGFloat)messageCellHeightWithWidth:(CGFloat)width fontSize:(CGFloat)fontSize;

@end
