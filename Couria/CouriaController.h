#import <UIKit/UIKit.h>

@interface CouriaController : UIViewController

- (instancetype)initWithApplication:(NSString *)applicationIdentifier user:(NSString *)userIdentifier dismissHandler:(void (^)(void))dismissHandler;

- (void)present;
- (void)dismiss;

@end
