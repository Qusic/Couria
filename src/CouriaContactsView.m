#import "Headers.h"
#import "CouriaContactsView.h"
#import "CouriaTheme.h"

@interface CouriaContactsView () <UITableViewDataSource, UITableViewDelegate>

@property(retain) id<CouriaContactsViewDelegate> contactsViewDelegate;
@property(retain) CouriaTheme *theme;

@property(retain) NSString *applicationIdentifier;
@property(retain) NSString *keyword;
@property(retain) NSArray *contacts;

@property(retain) NSOperationQueue *operationQueue;

@property(strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@end

@implementation CouriaContactsView

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<CouriaContactsViewDelegate>)delegate theme:(CouriaTheme *)theme
{
    self = [self initWithFrame:frame];
    if (self) {
        _contactsViewDelegate = delegate;
        _theme = theme;
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

- (void)setApplication:(NSString *)applicationIdentifier keyword:(NSString *)keyword
{
    _applicationIdentifier = applicationIdentifier;
    _keyword = keyword;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _contacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *contact = (NSUInteger)indexPath.row < _contacts.count ? _contacts[indexPath.row] : nil;
    NSString *cellReuseIdentifier = @"CouriaContactCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellReuseIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = _theme.contactNicknameColor;
        cell.detailTextLabel.textColor = _theme.contactIdentifierColor;
    }
    cell.textLabel.text = CouriaGetNickname(_applicationIdentifier, contact);
    cell.detailTextLabel.text = contact;
    cell.imageView.image = CouriaGetAvatar(_applicationIdentifier, contact);
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_contactsViewDelegate contactsView:self didSelectContact:_contacts[indexPath.row]];
}

- (void)refreshData
{
    [_operationQueue cancelAllOperations];
    [_operationQueue addOperationWithBlock:^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [_activityIndicator startAnimating];
        });
        _contacts = CouriaGetContacts(_applicationIdentifier, _keyword);
        dispatch_sync(dispatch_get_main_queue(), ^{
            [_activityIndicator stopAnimating];
            [self reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self performSelector:@selector(scrollToTopAnimated:) withObject:@(YES) afterDelay:0.1];
        });
    }];
}

- (void)scrollToTopAnimated:(BOOL)animated
{
    NSInteger rows = [self numberOfRowsInSection:0];
    if(rows > 0) {
        [self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]atScrollPosition:UITableViewScrollPositionTop animated:animated];
    }
}

@end
