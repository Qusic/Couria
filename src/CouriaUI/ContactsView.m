#import "../Headers.h"

@implementation CouriaContactsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.tableView.separatorColor = [[UIColor whiteColor]colorWithAlphaComponent:0.1];
    self.searchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    self.searchBar.barStyle = UIBarStyleBlack;
    self.searchBar.translucent = YES;
    self.searchBar.delegate = self;
    self.searchBar.keyboardAppearance = UIKeyboardAppearanceDark;
    self.searchBar.tintColor = [[UIColor whiteColor]colorWithAlphaComponent:0.4];
    self.searchBar._backgroundView.alpha = 0;
    self.tableView.tableHeaderView = self.searchBar;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.contacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *contact = indexPath.row < self.contacts.count ? self.contacts[indexPath.row] : nil;
    static NSString * const cellReuseIdentifier = @"CouriaContactCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellReuseIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectedBackgroundView = [[UIView alloc]initWithFrame:CGRectZero];
        cell.selectedBackgroundView.backgroundColor = [[UIColor whiteColor]colorWithAlphaComponent:0.1];
        cell.textLabel.textColor = [[UIColor whiteColor]colorWithAlphaComponent:0.6];
        cell.detailTextLabel.textColor = [[UIColor whiteColor]colorWithAlphaComponent:0.3];
    }
    cell.textLabel.text = contact[NicknameKey];
    cell.detailTextLabel.text = contact[IdentifierKey];
    cell.imageView.image = contact[AvatarKey];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *contact = self.contacts[indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.selectionHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.selectionHandler(contact);
        });
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (self.keywordHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.keywordHandler(searchText);
        });
    }
}

- (void)refreshData
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

@end
