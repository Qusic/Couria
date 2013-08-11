#import <UIKit/UIKit.h>

@class CouriaTheme;

@interface CouriaFieldView : UIView

- (id)initWithFrame:(CGRect)frame delegate:(id<UITextViewDelegate>)delegate theme:(CouriaTheme *)theme;
- (UITextView *)textView;

@end
