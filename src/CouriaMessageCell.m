#import "CouriaMessageCell.h"
#import "CouriaMessageView.h"
#import "CouriaTheme.h"

@interface CouriaMessageCell ()

@property(strong, nonatomic) CouriaMessageView *messageView;
@property(strong, nonatomic) UILabel *timestampLabel;
@property(assign) BOOL hasTimestamp;

@end

@implementation CouriaMessageCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier outgoing:(BOOL)outgoing theme:(CouriaTheme *)theme textSize:(CGFloat)textSize
{
    self = [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        _messageView = [[CouriaMessageView alloc]initWithFrame:self.contentView.bounds outgoing:outgoing theme:theme textSize:textSize];
        _timestampLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, self.contentView.bounds.size.width, 14)];
        _timestampLabel.backgroundColor = [UIColor clearColor];
        _timestampLabel.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        _timestampLabel.font = [UIFont boldSystemFontOfSize:11.5f];
        _timestampLabel.textAlignment = NSTextAlignmentCenter;
        _timestampLabel.textColor = theme.timestampColor;
        _timestampLabel.shadowColor = theme.timestampShadowColor;
        _timestampLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
        _hasTimestamp = NO;
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.imageView.image = nil;
        self.imageView.hidden = YES;
        self.textLabel.text = nil;
        self.textLabel.hidden = YES;
        self.detailTextLabel.text = nil;
        self.detailTextLabel.hidden = YES;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.accessoryView = nil;
        [self.contentView addSubview:_messageView];
    }
    return self;
}

- (void)setOutgoing:(BOOL)outgoing
{
    [_messageView setOutgoing:outgoing];
}

- (void)setMessage:(NSString *)message
{
    [_messageView setMessage:message];
}

- (void)setTimestamp:(NSDate *)timestamp
{
    if (timestamp != nil) {
        if (!_hasTimestamp) {
            CGRect messageViewRect = _messageView.frame;
            messageViewRect.origin.y = 14;
            _messageView.frame = messageViewRect;
            [self.contentView addSubview:_timestampLabel];
            _hasTimestamp = YES;
        }
        _timestampLabel.text = [NSDateFormatter localizedStringFromDate:timestamp dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
    } else {
        if (_hasTimestamp) {
            CGRect messageViewRect = _messageView.frame;
            messageViewRect.origin.y = 0;
            _messageView.frame = messageViewRect;
            [_timestampLabel removeFromSuperview];
            _hasTimestamp = NO;
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect bounds = self.contentView.bounds;
    if (_hasTimestamp) {
        _timestampLabel.frame = CGRectMake(0, 0, bounds.size.width, 14);
        bounds.origin.y = 14;
        _messageView.frame = bounds;
    } else {
        _messageView.frame = bounds;
    }
}

@end
