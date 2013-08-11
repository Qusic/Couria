#import <UIKit/UIKit.h>

@interface CouriaController : UIViewController

- (id)initWithApplication:(NSString *)applicationIdentifier user:(NSString *)userIdentifier dismissHandler:(void (^)(void))dismissHandler;

- (void)present;
- (void)dismiss;

- (void)layout;

@end
