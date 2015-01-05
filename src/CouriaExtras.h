#import <Foundation/Foundation.h>
#import <Activator/libactivator.h>
#import <Flipswitch/Flipswitch.h>

@interface CouriaExtras : NSObject <LAListener, FSSwitchDataSource>

+ (CouriaExtras *)sharedInstance;
- (void)registerExtrasForApplication:(NSString *)applicationIdentifier;
- (void)unregisterExtrasForApplication:(NSString *)applicationIdentifier;

@end
