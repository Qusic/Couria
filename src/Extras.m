#import "Headers.h"

static LAActivator *activator;
static FSSwitchPanel *flipswitch;
static SBApplicationController *applicationController;
static SBIconModel *iconModel;

static NSString *getApplicationIdentifier(NSString *externalIdentifier)
{
    return [externalIdentifier substringFromIndex:16];
}

static NSString *getExternalIdentifier(NSString *applicationIdentifier)
{
    return [NSString stringWithFormat:CouriaIdentifier".%@", applicationIdentifier];
}

static NSString *getApplicationName(NSString *applicationIdentifier)
{
    SBApplication *application = [applicationController applicationWithBundleIdentifier:applicationIdentifier];
    return application.displayName;
}

static UIImage *getApplicationIcon(NSString *applicationIdentifier, BOOL small)
{
    SBApplicationIcon *icon = [iconModel applicationIconForBundleIdentifier:applicationIdentifier];
    return [icon getIconImage:small ? 0 : 2];
}

@implementation CouriaExtras

+ (instancetype)sharedInstance
{
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc]init];
        dlopen("/Library/MobileSubstrate/DynamicLibraries/Activator.dylib", RTLD_LAZY);
        dlopen("/Library/MobileSubstrate/DynamicLibraries/Flipswitch.dylib", RTLD_LAZY);
        activator = (LAActivator *)[NSClassFromString(@"LAActivator") sharedInstance];
        flipswitch = (FSSwitchPanel *)[NSClassFromString(@"FSSwitchPanel") sharedPanel];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            applicationController = (SBApplicationController *)[NSClassFromString(@"SBApplicationController") sharedInstance];
            iconModel = ((SBIconViewMap *)[NSClassFromString(@"SBIconViewMap") homescreenMap]).iconModel;
        });
    });
    return sharedInstance;
}

- (void)registerExtrasForApplication:(NSString *)applicationIdentifier
{
    NSString *externalIdentifier = getExternalIdentifier(applicationIdentifier);
    [activator registerListener:self forName:externalIdentifier];
    [flipswitch registerDataSource:self forSwitchIdentifier:externalIdentifier];
}

- (void)unregisterExtrasForApplication:(NSString *)applicationIdentifier
{
    NSString *externalIdentifier = getExternalIdentifier(applicationIdentifier);
    [activator unregisterListenerWithName:externalIdentifier];
    [flipswitch unregisterSwitchIdentifier:externalIdentifier];
}

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event forListenerName:(NSString *)listenerName
{
    NSString *applicationIdentifier = getApplicationIdentifier(listenerName);
    CouriaPresentViewController(applicationIdentifier, nil);
    [event setHandled:YES];
}

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event forListenerName:(NSString *)listenerName
{
    CouriaDismissViewController();
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName
{
    return @"Couria";
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName
{
    NSString *applicationIdentifier = getApplicationIdentifier(listenerName);
    return [NSString stringWithFormat:@"Couria/%@", getApplicationName(applicationIdentifier)];
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName
{
    return CouriaLocalizedString(@"ACTIVATOR_LISTENER_DESCRIPTION");
}

- (UIImage *)activator:(LAActivator *)activator requiresIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale
{
    NSString *applicationIdentifier = getApplicationIdentifier(listenerName);
    return getApplicationIcon(applicationIdentifier, NO);
}

- (UIImage *)activator:(LAActivator *)activator requiresSmallIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale
{
    NSString *applicationIdentifier = getApplicationIdentifier(listenerName);
    return getApplicationIcon(applicationIdentifier, YES);
}

- (void)applyActionForSwitchIdentifier:(NSString *)switchIdentifier
{
    NSString *applicationIdentifier = getApplicationIdentifier(switchIdentifier);
    CouriaPresentViewController(applicationIdentifier, nil);
}

- (NSString *)titleForSwitchIdentifier:(NSString *)switchIdentifier
{
    NSString *applicationIdentifier = getApplicationIdentifier(switchIdentifier);
    return [NSString stringWithFormat:@"Couria/%@", getApplicationName(applicationIdentifier)];
}

- (NSBundle *)bundleForSwitchIdentifier:(NSString *)switchIdentifier
{
    return CouriaResourcesBundle();
}

@end
