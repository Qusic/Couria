#import <Foundation/Foundation.h>
#import <libactivator.h>

@interface CouriaActivatorListener : NSObject <LAListener>

+ (CouriaActivatorListener *)sharedInstance;
- (void)registerListenerForApplication:(NSString *)applicationIdentifier;
- (void)unregisterListenerForApplication:(NSString *)applicationIdentifier;

@end
