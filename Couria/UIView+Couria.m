#import "UIView+Couria.h"
#import <QuartzCore/QuartzCore.h>
#import "CouriaTheme.h"
#import "CouriaImageView.h"

@implementation UIView (Couria)

+ (UIView *)mainViewWithFrame:(CGRect)frame cornerRadius:(CGFloat)cornerRadius theme:(CouriaTheme *)theme
{
    CouriaImageView *view = [[CouriaImageView alloc]initWithFrame:frame];
    view.image = theme.mainBackgroundImage;
    view.backgroundColor = [UIColor clearColor];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.userInteractionEnabled = YES;
    view.layer.cornerRadius = cornerRadius;
    view.layer.masksToBounds = YES;
    return view;
}

+ (UIView *)topbarViewViewWithFrame:(CGRect)frame theme:(CouriaTheme *)theme
{
    CouriaImageView *view = [[CouriaImageView alloc]initWithFrame:frame];
    view.image = theme.topbarBackgroundImage;
    view.backgroundColor = [UIColor clearColor];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    view.userInteractionEnabled = YES;
    UIImage *shadowImage = theme.topbarShadowImage;
    CouriaImageView *shadowView = [[CouriaImageView alloc]initWithFrame:CGRectMake(0, frame.size.height, frame.size.width, shadowImage.size.height)];
    shadowView.image = shadowImage;
    shadowView.backgroundColor = [UIColor clearColor];
    shadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [view addSubview:shadowView];
    return view;
}

+ (UIView *)bottombarViewWithFrame:(CGRect)frame theme:(CouriaTheme *)theme
{
    CouriaImageView *view = [[CouriaImageView alloc]initWithFrame:frame];
    view.image = theme.bottombarBackgroundImage;
    view.backgroundColor = [UIColor clearColor];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    view.userInteractionEnabled = YES;
    UIImage *shadowImage = theme.bottombarShadowImage;
    CouriaImageView *shadowView = [[CouriaImageView alloc]initWithFrame:CGRectMake(0, -shadowImage.size.height, frame.size.width, shadowImage.size.height)];
    shadowView.image = shadowImage;
    shadowView.backgroundColor = [UIColor clearColor];
    shadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [view addSubview:shadowView];
    return view;
}

+ (UILabel *)titleLabelWithTheme:(CouriaTheme *)theme title:(NSString *)title
{
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.userInteractionEnabled = YES;
    label.clipsToBounds = NO;
    label.text = title;
    label.font = [UIFont boldSystemFontOfSize:20];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = theme.titleColor;
    label.shadowColor = theme.titleShadowColor;
    return label;
}

+ (UITextField *)titleFieldWithTheme:(CouriaTheme *)theme
{
    UITextField *field = [[UITextField alloc]initWithFrame:CGRectZero];
    field.backgroundColor = [UIColor clearColor];
    field.borderStyle = UITextBorderStyleNone;
    field.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    field.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    field.clearsOnBeginEditing = YES;
    field.font = [UIFont boldSystemFontOfSize:20];
    field.textAlignment = NSTextAlignmentCenter;
    field.textColor = theme.titleColor;
    return field;
}

+ (UIButton *)buttonWithApplicationIcon:(NSString *)applicationIdentifier
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage _applicationIconImageForBundleIdentifier:applicationIdentifier format:0 scale:[UIScreen mainScreen].scale]forState:UIControlStateNormal];
    return button;
}

+ (UIButton *)buttonWithTheme:(CouriaTheme *)theme title:(NSString *)title
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
    button.titleLabel.shadowOffset = CGSizeMake(0, -1);
    [button setBackgroundImage:theme.buttonNormalImage forState:UIControlStateNormal];
    [button setBackgroundImage:theme.buttonHighlightedImage forState:UIControlStateHighlighted];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:theme.buttonTitleNormalColor forState:UIControlStateNormal];
    [button setTitleColor:theme.buttonTitleHighlightedColor forState:UIControlStateHighlighted];
    [button setTitleShadowColor:theme.buttonTitleShadowNormalColor forState:UIControlStateNormal];
    [button setTitleShadowColor:theme.buttonTitleShadowHighlightedColor forState:UIControlStateHighlighted];
    return button;
}

+ (UIButton *)photoButtonWithTheme:(CouriaTheme *)theme
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:theme.photoButtonImage forState:UIControlStateNormal];
    return button;
}

+ (UIButton *)sendButtonWithTheme:(CouriaTheme *)theme title:(NSString *)title
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    button.titleLabel.shadowOffset = CGSizeMake(0, -1);
    [button setBackgroundImage:theme.sendButtonNormalImage forState:UIControlStateNormal];
    [button setBackgroundImage:theme.sendButtonHighlightedImage forState:UIControlStateHighlighted];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:theme.sendButtonTitleNormalColor forState:UIControlStateNormal];
    [button setTitleColor:theme.sendButtonTitleHighlightedColor forState:UIControlStateHighlighted];
    [button setTitleShadowColor:theme.sendButtonTitleShadowNormalColor forState:UIControlStateNormal];
    [button setTitleShadowColor:theme.sendButtonTitleShadowHighlightedColor forState:UIControlStateHighlighted];
    return button;
}

+ (UIButton *)lightButton
{
    UIButton *button = nil;
    if (iOS7()) {
        //TODO: a better-looking button. currently this button is invisible
        button = [UIButton buttonWithType:UIButtonTypeCustom];
    } else {
        button = [UIButton buttonWithType:UIButtonTypeInfoLight];
        [button setImage:nil forState:UIControlStateNormal];
    }
    return button;
}

+ (UITextField *)passcodeFieldWithTheme:(CouriaTheme *)theme keyboardType:(UIKeyboardType)keyboardType
{
    UITextField *field = [[UITextField alloc]initWithFrame:CGRectZero];
    field.background = theme.passcodeFieldBackgroundImage;
    field.borderStyle = UITextBorderStyleNone;
    field.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    field.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    field.clearsOnBeginEditing = YES;
    field.font = [UIFont boldSystemFontOfSize:20];
    field.textAlignment = NSTextAlignmentCenter;
    field.textColor = theme.passcodeFieldTextColor;
    field.secureTextEntry = YES;
    field.placeholder = CouriaLocalizedString(@"PASSCODE");
    field.keyboardType = keyboardType;
    return field;
}

- (NSArray *)findViewsUsingBlock:(BOOL (^)(UIView *))block
{
    NSMutableArray *views = [NSMutableArray array];
    if (block(self)) {
        [views addObject:self];
    }
    for (UIView *view in self.subviews) {
        [views addObjectsFromArray:[view findViewsUsingBlock:block]];
    }
    return views;
}

@end
