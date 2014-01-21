#import "CouriaTheme.h"
#import "UIImage+Couria.h"
#import "UIColor+Couria.h"

@interface CouriaTheme ()

@property(retain) NSBundle *themeBundle;
@property(retain) NSDictionary *themeProperty;

@property(retain) NSMutableDictionary *cachedImages;
@property(retain) NSMutableDictionary *cachedColors;

@end

@implementation CouriaTheme

+ (instancetype)themeWithIdentifier:(NSString *)themeIdentifier
{
    static NSMutableDictionary *cachedThemes;
    if (cachedThemes == nil) {
        cachedThemes = [NSMutableDictionary dictionary];
    }
    if (themeIdentifier == nil) {
        themeIdentifier = iOS7() ? @"me.qusic.couria.theme.default7" : @"me.qusic.couria.theme.default";
    }
    CouriaTheme *theme = cachedThemes[themeIdentifier];
    if (theme == nil) {
        theme = [[self.class alloc]init];
        NSString *themeBundlePath = [NSString stringWithFormat:@"%@/%@", ThemesDirectoryPath, themeIdentifier];
        NSString *themePropertyPath = [NSString stringWithFormat:@"%@/%@", themeBundlePath, @"Theme.plist"];
        theme.themeBundle = [NSBundle bundleWithPath:themeBundlePath];
        theme.themeProperty = [NSDictionary dictionaryWithContentsOfFile:themePropertyPath];
        theme.cachedImages = [NSMutableDictionary dictionary];
        theme.cachedColors = [NSMutableDictionary dictionary];
        cachedThemes[themeIdentifier] = theme;
    }
    return theme;
}

- (UIImage *)imageNamed:(NSString *)name
{
    UIImage *image = _cachedImages[name];
    if (image == nil) {
        image = [UIImage imageNamed:name bundle:_themeBundle];
        if (image != nil) {
            _cachedImages[name] = image;
        }
    }
    return image;
}

- (UIImage *)imageNamed:(NSString *)name resizingCapInsets:(UIEdgeInsets)capInsets
{
    UIImage *image = _cachedImages[name];
    if (image == nil) {
        image = [[UIImage imageNamed:name bundle:_themeBundle]resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeTile];
        if (image != nil) {
            _cachedImages[name] = image;
        }
    }
    return image;
}

- (UIColor *)colorNamed:(NSString *)name
{
    UIColor *color = _cachedColors[name];
    if (color == nil) {
        color = [UIColor colorFromHexString:_themeProperty[name]];
        if (color != nil) {
            _cachedColors[name] = color;
        }
    }
    return color;
}

- (UIImage *)mainBackgroundImage
{
    return [self imageNamed:@"Main_Background.png" resizingCapInsets:UIEdgeInsetsZero];
}

- (UIImage *)topbarBackgroundImage
{
    return [self imageNamed:@"Topbar_Background.png" resizingCapInsets:UIEdgeInsetsZero];
}

- (UIImage *)topbarShadowImage
{
    return [self imageNamed:@"Topbar_Shadow.png" resizingCapInsets:UIEdgeInsetsZero];
}

- (UIImage *)bottombarBackgroundImage
{
    return [self imageNamed:@"Bottombar_Background.png" resizingCapInsets:UIEdgeInsetsMake(20, 0, 19, 0)];
}

- (UIImage *)bottombarShadowImage
{
    return [self imageNamed:@"Bottombar_Shadow.png" resizingCapInsets:UIEdgeInsetsZero];
}

- (UIColor *)titleColor
{
    return [self colorNamed:@"TitleColor"];
}

- (UIColor *)titleShadowColor
{
    return [self colorNamed:@"TitleShadowColor"];
}

- (UIImage *)buttonNormalImage
{
    return [self imageNamed:@"Button_Normal.png" resizingCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
}

- (UIImage *)buttonHighlightedImage
{
    return [self imageNamed:@"Button_Highlighted.png" resizingCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
}

- (UIColor *)buttonTitleNormalColor
{
    return [self colorNamed:@"ButtonTitleNormalColor"];
}

- (UIColor *)buttonTitleHighlightedColor
{
    return [self colorNamed:@"ButtonTitleHighlightedColor"];
}

- (UIColor *)buttonTitleShadowNormalColor
{
    return [self colorNamed:@"ButtonTitleShadowNormalColor"];
}

- (UIColor *)buttonTitleShadowHighlightedColor
{
    return [self colorNamed:@"ButtonTitleShadowHighlightedColor"];
}

- (UIImage *)fieldBackgroundImage
{
    return [self imageNamed:@"Field_Background.png" resizingCapInsets:UIEdgeInsetsMake(20, 12, 19, 18)];
}

- (UIColor *)fieldBackgroundColor
{
    return [self colorNamed:@"FieldBackgroundColor"];
}

- (UIColor *)fieldTextColor
{
    return [self colorNamed:@"FieldTextColor"];
}

- (UIImage *)photoButtonImage
{
    return [self imageNamed:@"PhotoButton.png"];
}

- (UIImage *)sendButtonNormalImage
{
    return [self imageNamed:@"SendButton_Normal.png" resizingCapInsets:UIEdgeInsetsMake(0, 13, 0, 13)];
}

- (UIImage *)sendButtonHighlightedImage
{
    return [self imageNamed:@"SendButton_Highlighted.png" resizingCapInsets:UIEdgeInsetsMake(0, 13, 0, 13)];
}

- (UIColor *)sendButtonTitleNormalColor
{
    return [self colorNamed:@"SendButtonTitleNormalColor"];
}

- (UIColor *)sendButtonTitleHighlightedColor
{
    return [self colorNamed:@"SendButtonTitleHighlightedColor"];
}

- (UIColor *)sendButtonTitleShadowNormalColor
{
    return [self colorNamed:@"SendButtonTitleShadowNormalColor"];
}

- (UIColor *)sendButtonTitleShadowHighlightedColor
{
    return [self colorNamed:@"SendButtonTitleShadowHighlightedColor"];
}

- (UIImage *)outgoingMessageBackgroundImage
{
    return [self imageNamed:@"OutgoingMessage_Background.png" resizingCapInsets:UIEdgeInsetsMake(14, 18, 17, 24)];
}

- (UIImage *)incomingMessageBackgroundImage
{
    return [self imageNamed:@"IncomingMessage_Background.png" resizingCapInsets:UIEdgeInsetsMake(14, 24, 17, 18)];
}

- (UIColor *)outgoingMessageColor
{
    return [self colorNamed:@"OutgoingMessageColor"];
}

- (UIColor *)incomingMessageColor
{
    return [self colorNamed:@"IncomingMessageColor"];
}

- (UIColor *)timestampColor
{
    return [self colorNamed:@"TimestampColor"];
}

- (UIColor *)timestampShadowColor
{
    return [self colorNamed:@"TimestampShadowColor"];
}

- (UIColor *)contactNicknameColor
{
    return [self colorNamed:@"ContactNicknameColor"];
}

- (UIColor *)contactIdentifierColor
{
    return [self colorNamed:@"ContactIdentifierColor"];
}

- (UIImage *)passcodeFieldBackgroundImage
{
    return [self imageNamed:@"PasscodeField_Background.png" resizingCapInsets:UIEdgeInsetsZero];
}

- (UIColor *)passcodeFieldTextColor
{
    return [self colorNamed:@"PasscodeFieldTextColor"];
}

@end
