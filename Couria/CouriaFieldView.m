#import "CouriaFieldView.h"
#import "CouriaTheme.h"
#import "CouriaImageView.h"

// Workaround for broken UITextView in iOS 7. See https://github.com/jaredsinclair/JTSTextView
#import "JTSTextView.h"

@interface CouriaFieldView ()

@property(strong, nonatomic) UITextView *textView;

@end

@implementation CouriaFieldView

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<UITextViewDelegate>)delegate theme:(CouriaTheme *)theme
{
    self = [self initWithFrame:frame];
    if (self) {
        _textView = iOS7() ? (UITextView *)[[JTSTextView alloc]initWithFrame:CGRectMake(1, 3, frame.size.width-5, frame.size.height-10)] : [[UITextView alloc]initWithFrame:CGRectMake(1, 3, frame.size.width-2, frame.size.height-10)];
        _textView.delegate = delegate;
        _textView.backgroundColor = theme.fieldBackgroundColor;
        _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _textView.font = [UIFont systemFontOfSize:16];
        _textView.textColor = theme.fieldTextColor;
        _textView.scrollEnabled = NO;
        _textView.scrollsToTop = NO;
        _textView.scrollIndicatorInsets = UIEdgeInsetsMake(12, 0, 6, 6);
        if (iOS7()) {
            ((JTSTextView *)_textView).textViewDelegate = (id<JTSTextViewDelegate>)delegate;
            _textView.textContainerInset = UIEdgeInsetsMake(13, 4, 0, 4);
            _textView.text = nil;
        }
        CouriaImageView *backgroundView = [CouriaImageView imageViewWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        backgroundView.image = theme.fieldBackgroundImage;
        backgroundView.backgroundColor = [UIColor clearColor];
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_textView];
        [self addSubview:backgroundView];
    }
    return self;
}

@end
