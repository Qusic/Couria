#import <Foundation/Foundation.h>
#import <LAActivator/libactivator.h>
#import <Flipswitch/Flipswitch.h>

@interface CouriaExtras : NSObject <LAListener, FSSwitchDataSource>

+ (CouriaExtras *)sharedInstance;
- (void)registerExtrasForApplication:(NSString *)applicationIdentifier;
- (void)unregisterExtrasForApplication:(NSString *)applicationIdentifier;

@end
