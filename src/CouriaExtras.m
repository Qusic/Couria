#import "Headers.h"
#import "CouriaExtras.h"
#import "CouriaController.h"

static LAActivator *activator;
static FSSwitchPanel *flipswitch;

static inline NSString *getApplicationIdentifier(NSString *externalIdentifier)
{
    return [externalIdentifier substringFromIndex:16];
}

static inline NSString *getExternalIdentifier(NSString *applicationIdentifier)
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

@implementation CouriaExtras

+ (CouriaExtras *)sharedInstance
{
    static CouriaExtras *sharedInstance;
    if (sharedInstance == nil) {
        sharedInstance = [[CouriaExtras alloc]init];
        activator = (LAActivator *)[NSClassFromString(@"LAActivator") sharedInstance];
        flipswitch = (FSSwitchPanel *)[NSClassFromString(@"FSSwitchPanel") sharedPanel];
    }
    return sharedInstance;
}

- (void)registerExtrasForApplication:(NSString *)applicationIdentifier
{
    NSString *externalIdentifier = getExternalIdentifier(applicationIdentifier);
    if (activator != nil) {
        [activator registerListener:[self.class sharedInstance] forName:externalIdentifier];
    }
    if (flipswitch != nil) {
        [flipswitch registerDataSource:self forSwitchIdentifier:externalIdentifier];
    }
}

- (void)unregisterExtrasForApplication:(NSString *)applicationIdentifier
{
    NSString *externalIdentifier = getExternalIdentifier(applicationIdentifier);
    if (activator != nil) {
        [activator unregisterListenerWithName:externalIdentifier];
    }
    if (flipswitch != nil) {
        [flipswitch unregisterSwitchIdentifier:externalIdentifier];
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

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier
{
    return FSSwitchStateIndeterminate;
}

- (void)applyActionForSwitchIdentifier:(NSString *)switchIdentifier
{
    if (CouriaCurrentController() == nil) {
        [[Couria sharedInstance]presentControllerForApplication:getApplicationIdentifier(switchIdentifier) user:nil];
    }
}

- (BOOL)hasAlternateActionForSwitchIdentifier:(NSString *)switchIdentifier
{
    return NO;
}

- (NSString *)titleForSwitchIdentifier:(NSString *)switchIdentifier
{
    return [NSString stringWithFormat:@"Couria/%@", getApplicationName(getApplicationIdentifier(switchIdentifier))];
}

- (NSBundle *)bundleForSwitchIdentifier:(NSString *)switchIdentifier
{
    return [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/%@", ExtensionsDirectoryPath, getApplicationIdentifier(switchIdentifier)]];
}

@end
