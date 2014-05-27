#import "CouriaMessageView.h"
#import "CouriaTheme.h"
#import "CouriaImageView.h"
#import "NSString+Couria.h"

@interface CouriaMessageView ()

@property(assign, nonatomic) BOOL outgoing;
@property(retain, nonatomic) NSString *message;

@property(retain, nonatomic) CouriaTheme *theme;
@property(strong, nonatomic) CouriaImageView *imageView;
@property(strong, nonatomic) UILabel *textView;

@end

@implementation CouriaMessageView

- (instancetype)initWithFrame:(CGRect)frame outgoing:(BOOL)outgoing theme:(CouriaTheme *)theme textSize:(CGFloat)textSize
{
    self = [self initWithFrame:frame];
    if (self) {
        _outgoing = outgoing;
        _theme = theme;
        _imageView = [CouriaImageView imageViewWithFrame:CGRectZero];
        _imageView.image = outgoing ? theme.outgoingMessageBackgroundImage : theme.incomingMessageBackgroundImage;
        _imageView.backgroundColor = [UIColor clearColor];
        _textView = [[UILabel alloc]initWithFrame:CGRectZero];
        _textView.backgroundColor = [UIColor clearColor];
        _textView.font = [UIFont systemFontOfSize:textSize];
        _textView.textColor = outgoing ? theme.outgoingMessageColor : theme.incomingMessageColor;
        _textView.numberOfLines = 0;
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_imageView];
        [self addSubview:_textView];
    }
    return self;
}

- (void)setOutgoing:(BOOL)outgoing
{
    _outgoing = outgoing;
    _imageView.image = outgoing ? _theme.outgoingMessageBackgroundImage : _theme.incomingMessageBackgroundImage;
    _textView.textColor = outgoing ? _theme.outgoingMessageColor : _theme.incomingMessageColor;
    [self setNeedsLayout];
}

- (void)setMessage:(NSString *)message
{
    _message = message;
    _textView.text = message;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    UIImage *backgroundImage = _outgoing ? _theme.outgoingMessageBackgroundImage : _theme.incomingMessageBackgroundImage;
    CGFloat fontSize = _textView.font.pointSize;
    CGSize textSize = [_message messageTextSizeWithWidth:215 fontSize:fontSize];
    CGSize backgroundSize = [_message messageBackgroundSizeWithWidth:215 fontSize:fontSize];
    CGRect backgroundFrame = {CGPointMake(_outgoing ? self.frame.size.width - backgroundSize.width : 0, 2), backgroundSize};
    CGRect textFrame = CGRectMake(backgroundFrame.origin.x + backgroundImage.capInsets.left - 4, 4, textSize.width + 1, textSize.height + 1);

    _imageView.frame = backgroundFrame;
    _textView.frame = textFrame;
}

@end
