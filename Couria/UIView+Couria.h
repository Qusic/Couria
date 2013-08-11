#import <UIKit/UIKit.h>

@class CouriaTheme;

@interface UIView (Couria)

+ (UIView *)mainViewWithFrame:(CGRect)frame cornerRadius:(CGFloat)cornerRadius theme:(CouriaTheme *)theme;
+ (UIView *)topbarViewViewWithFrame:(CGRect)frame theme:(CouriaTheme *)theme;
+ (UIView *)bottombarViewWithFrame:(CGRect)frame theme:(CouriaTheme *)theme;
+ (UILabel *)titleLabelWithTheme:(CouriaTheme *)theme title:(NSString *)title;
+ (UITextField *)titleFieldWithTheme:(CouriaTheme *)theme;
+ (UIButton *)buttonWithApplicationIcon:(NSString *)applicationIdentifier;
+ (UIButton *)buttonWithTheme:(CouriaTheme *)theme title:(NSString *)title;
+ (UIButton *)photoButtonWithTheme:(CouriaTheme *)theme;
+ (UIButton *)sendButtonWithTheme:(CouriaTheme *)theme title:(NSString *)title;
+ (UIButton *)lightButton;
+ (UITextField *)passcodeFieldWithTheme:(CouriaTheme *)theme keyboardType:(UIKeyboardType)keyboardType;

- (NSArray *)findViewsUsingBlock:(BOOL (^)(UIView *))block;

@end
