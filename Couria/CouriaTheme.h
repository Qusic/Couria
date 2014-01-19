#import <Foundation/Foundation.h>

@interface CouriaTheme : NSObject

+ (id)themeWithIdentifier:(NSString *)themeIdentifier;

- (UIImage *)mainBackgroundImage;
- (UIImage *)topbarBackgroundImage;
- (UIImage *)topbarShadowImage;
- (UIImage *)bottombarBackgroundImage;
- (UIImage *)bottombarShadowImage;
- (UIColor *)titleColor;
- (UIColor *)titleShadowColor;
- (UIImage *)buttonNormalImage;
- (UIImage *)buttonHighlightedImage;
- (UIColor *)buttonTitleNormalColor;
- (UIColor *)buttonTitleHighlightedColor;
- (UIColor *)buttonTitleShadowNormalColor;
- (UIColor *)buttonTitleShadowHighlightedColor;
- (UIImage *)fieldBackgroundImage;
- (UIColor *)fieldBackgroundColor;
- (UIColor *)fieldTextColor;
- (UIImage *)photoButtonImage;
- (UIImage *)sendButtonNormalImage;
- (UIImage *)sendButtonHighlightedImage;
- (UIColor *)sendButtonTitleNormalColor;
- (UIColor *)sendButtonTitleHighlightedColor;
- (UIColor *)sendButtonTitleShadowNormalColor;
- (UIColor *)sendButtonTitleShadowHighlightedColor;
- (UIImage *)outgoingMessageBackgroundImage;
- (UIImage *)incomingMessageBackgroundImage;
- (UIColor *)outgoingMessageColor;
- (UIColor *)incomingMessageColor;
- (UIColor *)timestampColor;
- (UIColor *)timestampShadowColor;
- (UIColor *)contactNicknameColor;
- (UIColor *)contactIdentifierColor;
- (UIImage *)passcodeFieldBackgroundImage;
- (UIColor *)passcodeFieldTextColor;

@end
