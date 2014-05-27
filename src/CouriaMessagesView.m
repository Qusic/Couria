#import "Headers.h"
#import "CouriaMessagesView.h"
#import "CouriaTheme.h"
#import "CouriaMessageCell.h"
#import "NSString+Couria.h"

@interface CouriaMessagesView () <UITableViewDataSource, UITableViewDelegate>

@property(retain) id<CouriaMessagesViewDelegate> messagesViewDelegate;
@property(retain) CouriaTheme *theme;
@property(assign) CGFloat textSize;

@property(retain) NSString *applicationIdentifier;
@property(retain) NSString *userIdentifier;
@property(retain) NSArray *messages;

@property(retain) NSOperationQueue *operationQueue;

@property(strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@end

@implementation CouriaMessagesView

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<CouriaMessagesViewDelegate>)delegate theme:(CouriaTheme *)theme textSize:(CGFloat)textSize
{
    self = [self initWithFrame:frame];
    if (self) {
        _messagesViewDelegate = delegate;
        _theme = theme;
        _textSize = textSize;
        _operationQueue = [[NSOperationQueue alloc]init];
        _operationQueue.maxConcurrentOperationCount = 1;
        _activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndicator.center = CGPointMake(frame.size.width / 2, frame.size.height / 2);
        _activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        _activityIndicator.hidesWhenStopped = YES;
        [_activityIndicator stopAnimating];
        self.dataSource = self;
        self.delegate = self;
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self addSubview:_activityIndicator];
    }
    return self;
}

- (void)setApplication:(NSString *)applicationIdentifier user:(NSString *)userIdentifier
{
    _applicationIdentifier = applicationIdentifier;
    _userIdentifier = userIdentifier;
}

- (NSString *)displayedContentForMessage:(id<CouriaMessage>)message
{
    NSMutableString *displayedContent = [NSMutableString string];
    NSString *text = message.text;
    id media = message.media;
    if (text.length > 0) {
        [displayedContent appendString:text];
    }
    if (media != nil) {
        if (displayedContent.length > 0) {
            [displayedContent appendString:@"\n"];
        }
        if ([media isKindOfClass:UIImage.class]) {
            [displayedContent appendString:[NSString stringWithFormat:@"[%@]%@", CouriaLocalizedString(@"PHOTO"), CouriaLocalizedString(@"TAP_TO_VIEW")]];
        } else if ([media isKindOfClass:NSURL.class]) {
            [displayedContent appendString:[NSString stringWithFormat:@"[%@]%@", CouriaLocalizedString(@"MOVIE"), CouriaLocalizedString(@"TAP_TO_VIEW")]];
        } else {
            [displayedContent appendString:[NSString stringWithFormat:@"%@", media]];
        }
    }
    return displayedContent;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<CouriaMessage> message = (NSUInteger)indexPath.row < _messages.count ? _messages[indexPath.row] : nil;
    NSString *cellReuseIdentifier = [NSString stringWithFormat:@"CouriaMessageCell-%d", message.outgoing];
    CouriaMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier];
    if (cell == nil) {
        cell = [[CouriaMessageCell alloc]initWithReuseIdentifier:cellReuseIdentifier outgoing:message.outgoing theme:_theme textSize:_textSize];
    }
    [cell setMessage:[self displayedContentForMessage:message]];
    [cell setTimestamp:[message respondsToSelector:@selector(timestamp)] ? message.timestamp : nil];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<CouriaMessage> message = _messages[indexPath.row];
    CGFloat height = [[self displayedContentForMessage:message]messageCellHeightWithWidth:215 fontSize:_textSize];
    if ([message respondsToSelector:@selector(timestamp)] && message.timestamp != nil) {
        height += 12;
    }
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_messagesViewDelegate messagesView:self didSelectMessage:_messages[indexPath.row]];
}

- (void)refreshData
{
    [_operationQueue cancelAllOperations];
    [_operationQueue addOperationWithBlock:^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [_activityIndicator startAnimating];
        });
        _messages = CouriaGetMessages(_applicationIdentifier, _userIdentifier);
        dispatch_sync(dispatch_get_main_queue(), ^{
            [_activityIndicator stopAnimating];
            [self reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self performSelector:@selector(scrollToBottomAnimated:) withObject:@(YES) afterDelay:0.1];
        });
    }];
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
    NSInteger rows = [self numberOfRowsInSection:0];
    if(rows > 0) {
        [self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows-1 inSection:0]atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

@end
