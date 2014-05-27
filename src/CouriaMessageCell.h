#import <UIKit/UIKit.h>

@class CouriaTheme;

@interface CouriaMessageCell : UITableViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier outgoing:(BOOL)outgoing theme:(CouriaTheme *)theme textSize:(CGFloat)textSize;
- (void)setOutgoing:(BOOL)outgoing;
- (void)setMessage:(NSString *)message;
- (void)setTimestamp:(NSDate *)timestamp;

@end
