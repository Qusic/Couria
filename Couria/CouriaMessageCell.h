#import <UIKit/UIKit.h>

@class CouriaTheme;

@interface CouriaMessageCell : UITableViewCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier outgoing:(BOOL)outgoing theme:(CouriaTheme *)theme;
- (void)setOutgoing:(BOOL)outgoing;
- (void)setMessage:(NSString *)message;
- (void)setTimestamp:(NSDate *)timestamp;

@end
