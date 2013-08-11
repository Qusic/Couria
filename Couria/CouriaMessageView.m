#import "CouriaMessageView.h"
#import "CouriaTheme.h"
#import "CouriaImageView.h"
#import "NSString+Couria.h"

@interface CouriaMessageView ()

@property(assign, nonatomic) BOOL outgoing;
@property(retain, nonatomic) NSString *message;

@property(retain) UIImage *outgoingBackgroundImage;
@property(retain) UIImage *incomingBackgroundImage;

@property(strong, nonatomic) CouriaImageView *imageView;
@property(strong, nonatomic) UITextView *textView;

@end

@implementation CouriaMessageView

- (id)initWithFrame:(CGRect)frame outgoing:(BOOL)outgoing theme:(CouriaTheme *)theme
{
    self = [self initWithFrame:frame];
    if (self) {
        _outgoing = outgoing;
        _outgoingBackgroundImage = theme.outgoingMessageBackgroundImage;
        _incomingBackgroundImage = theme.incomingMessageBackgroundImage;
        _imageView = [[CouriaImageView alloc]initWithFrame:CGRectZero];
        _imageView.image = outgoing ? _outgoingBackgroundImage : _incomingBackgroundImage;
        _imageView.backgroundColor = [UIColor clearColor];
        _textView = [[UITextView alloc]initWithFrame:CGRectZero];
        _textView.backgroundColor = [UIColor clearColor];
        _textView.font = [UIFont systemFontOfSize:15];
        _textView.textColor = theme.messageColor;
        _textView.dataDetectorTypes = UIDataDetectorTypeAll;
        _textView.editable = NO;
        _textView.scrollEnabled = NO;
        _textView.contentInset = UIEdgeInsetsMake(-8,-8,0,0);
        _textView.clipsToBounds = NO;
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
    _imageView.image = outgoing ? _outgoingBackgroundImage : _incomingBackgroundImage;
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
    UIImage *backgroundImage = _outgoing ? _outgoingBackgroundImage : _incomingBackgroundImage;
    CGSize textSize = [_message messageTextSizeWithWidth:215];
    CGSize backgroundSize = [_message messageBackgroundSizeWithWidth:215];
    CGRect backgroundFrame = {CGPointMake(_outgoing ? self.frame.size.width - backgroundSize.width : 0, 2), backgroundSize};
    CGRect textFrame = CGRectMake(backgroundFrame.origin.x + backgroundImage.capInsets.left, 6, textSize.width + 16, textSize.height);

    _imageView.frame = backgroundFrame;
    _textView.frame = textFrame;
}

@end
