#import <UIKit/UIKit.h>

@class CouriaTheme;
@protocol CouriaContactsViewDelegate;

@interface CouriaContactsView : UITableView

- (id)initWithFrame:(CGRect)frame delegate:(id<CouriaContactsViewDelegate>)delegate theme:(CouriaTheme *)theme;
- (void)setApplication:(NSString *)applicationIdentifier keyword:(NSString *)keyword;
- (void)refreshData;
- (void)scrollToTopAnimated:(BOOL)animated;

@end

@protocol CouriaContactsViewDelegate <NSObject>

- (void)contactsView:(CouriaContactsView *)contactsView didSelectContact:(NSString *)userIdentifier;

@end
