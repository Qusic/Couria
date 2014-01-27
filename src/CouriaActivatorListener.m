#import "Headers.h"
#import "CouriaActivatorListener.h"
#import "CouriaController.h"

static LAActivator *activator;

static inline NSString *getApplicationIdentifier(NSString *listenerName)
{
    return [listenerName substringFromIndex:16];
}

static inline NSString *getListenerName(NSString *applicationIdentifier)
{
    return [NSString stringWithFormat:@"%@.%@", CouriaIdentifier, applicationIdentifier];
}

static NSString *getApplicationName(NSString *applicationIdentifier)
{
    static SBApplicationController *applicationController;
    if (applicationController == nil) {
        applicationController = (SBApplicationController *)[NSClassFromString(@"SBApplicationController") sharedInstance];
    }
    SBApplication *application = [applicationController applicationWithDisplayIdentifier:applicationIdentifier];
    return application.displayName;
}

@implementation CouriaActivatorListener

+ (CouriaActivatorListener *)sharedInstance
{
    static CouriaActivatorListener *sharedInstance;
    if (sharedInstance == nil) {
        sharedInstance = [[CouriaActivatorListener alloc]init];
        activator = (LAActivator *)[NSClassFromString(@"LAActivator") sharedInstance];
    }
    return sharedInstance;
}

- (void)registerListenerForApplication:(NSString *)applicationIdentifier
{
    if (activator != nil) {
        [activator registerListener:[self.class sharedInstance] forName:getListenerName(applicationIdentifier)];
    }
}

- (void)unregisterListenerForApplication:(NSString *)applicationIdentifier
{
    if (activator != nil) {
        [activator unregisterListenerWithName:getListenerName(applicationIdentifier)];
    }
}

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event forListenerName:(NSString *)listenerName
{
    if (CouriaCurrentController() == nil) {
        [[Couria sharedInstance]presentControllerForApplication:getApplicationIdentifier(listenerName) user:nil];
        [event setHandled:YES];
    }
}

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event forListenerName:(NSString *)listenerName
{
    [CouriaCurrentController() dismiss];
}

- (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event
{
    CouriaController *controller = CouriaCurrentController();
    if (controller != nil) {
        [controller dismiss];
		[event setHandled:YES];
    }
}

- (void)activator:(LAActivator *)activator otherListenerDidHandleEvent:(LAEvent *)event
{
    [CouriaCurrentController() dismiss];
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName
{
    return [NSString stringWithFormat:@"Couria/%@", getApplicationName(getApplicationIdentifier(listenerName))];
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName
{
    return CouriaLocalizedString(@"ACTIVATOR_LISTENER_DESCRIPTION");
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName
{
    return @"Couria";
}

- (UIImage *)activator:(LAActivator *)activator requiresIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale
{
    return [UIImage _applicationIconImageForBundleIdentifier:getApplicationIdentifier(listenerName) format:2 scale:[UIScreen mainScreen].scale];
}

- (UIImage *)activator:(LAActivator *)activator requiresSmallIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale
{
    return [UIImage _applicationIconImageForBundleIdentifier:getApplicationIdentifier(listenerName) format:0 scale:[UIScreen mainScreen].scale];
}

@end
