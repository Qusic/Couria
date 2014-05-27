#import <UIKit/UIKit.h>

@class CouriaTheme;

@interface CouriaMessageView : UIView

- (instancetype)initWithFrame:(CGRect)frame outgoing:(BOOL)outgoing theme:(CouriaTheme *)theme textSize:(CGFloat)textSize;
- (void)setOutgoing:(BOOL)outgoing;
- (void)setMessage:(NSString *)message;

@end
