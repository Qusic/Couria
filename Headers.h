#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Couria.h"

#define CouriaIdentifier @"me.qusic.couria"
#define ExtensionsDirectoryPath @"/Library/Application Support/Couria/Extensions"
#define ThemesDirectoryPath @"/Library/Application Support/Couria/Themes"
#define LocalizationsDirectoryPath @"/Library/Application Support/Couria/Localizations"
#define PreferenceBundlePath @"/Library/PreferenceBundles/Couria.bundle"
#define UserDefaultsPlistPath @"/var/mobile/Library/Preferences/me.qusic.couria.plist"
#define RegisteredApplicationsMessage @"RegisteredApplications"
#define WidgetApplicationsMessage @"WidgetApplications"
#define UserDefaultsChangedNotification "me.qusic.couria.UserDefaultsChanged"
#define NewBulletinPublishedNotification "me.qusic.couria.NewBulletinPublished"
#define ApplicationsKey @"Applications"
#define BulletinKey @"Bulletin"
#define EnabledKey @"Enabled"
#define ThemeKey @"Theme"
#define PasscodeKey @"Passcode"
#define RequirePasscodeWhenLockedKey @"RequirePasscodeWhenLocked"
#define RequirePasscodeWhenUnlockedKey @"RequirePasscodeWhenUnlocked"

#pragma mark - Couria

@class BBBulletin, CouriaController;
@protocol CouriaMessage;

@interface Couria (Private)
- (NSDictionary *)message:(NSString *)message info:(NSDictionary *)info;
@end

#ifdef __cplusplus
extern "C" {
#endif
    BOOL CouriaIsApplicationRegistered(NSString *application);
    BOOL CouriaIsHandling(void);
    BOOL CouriaCanHandle(NSString *application);
    BOOL CouriaCanHandleBulletin(BBBulletin *bulletin);
    void CouriaHandle(NSString *application, NSString *userIdentifier);
    void CouriaHandleBulletin(BBBulletin *bulletin);
    void CouriaHandleNewBulletin(BBBulletin *bulletin);
    CouriaController *CouriaCurrentController(void);
    NSString *CouriaGetUserIdentifier(BBBulletin *bulletin);
    NSString *CouriaGetNickname(NSString *application, NSString *userIdentifier);
    NSArray *CouriaGetMessages(NSString *application, NSString *userIdentifier);
    UIImage *CouriaGetAvatar(NSString *application, NSString *userIdentifier);
    NSArray *CouriaGetContacts(NSString *application, NSString *keyword);
    void CouriaSendMessage(NSString *application, NSString *userIdentifier, id<CouriaMessage> message);
    void CouriaMarkRead(NSString *application, NSString *userIdentifier);
    BOOL CouriaCanSendPhoto(NSString *application);
    BOOL CouriaCanSendMovie(NSString *application);
    BOOL CouriaShouldClearReadNotifications(NSString *application);
    BOOL CouriaShouldDecreaseBadgeNumber(NSString *application);
    void CouriaOpenApp(NSString *application);
    id CouriaGetUserDefaultForKey(NSString *application, NSString *key);
#ifdef __cplusplus
}
#endif

#pragma mark - CouriaPreferences

#ifdef __cplusplus
extern "C" {
#endif
    void CouriaPreferencesSetUserDefaultForKey(NSString *application, NSString *key, id value);
    id CouriaPreferencesGetUserDefaultForKey(NSString *application, NSString *key);
    NSArray *CouriaPreferencesGetExtensions(void);
    NSArray *CouriaPreferencesGetThemes(void);
    NSString *CouriaPreferencesGetExtensionDisplayName(NSString *extension);
    NSString *CouriaPreferencesGetThemeDisplayName(NSString *theme);
#ifdef __cplusplus
}
#endif

#pragma mark - Localization

#ifdef __cplusplus
extern "C" {
#endif
    NSString *CouriaLocalizedString(NSString *string);
#ifdef __cplusplus
}
#endif

#pragma mark - Debug

#ifdef __cplusplus
extern "C" {
#endif
    void _CFEnableZombies(void);
#ifdef __cplusplus
}
#endif

#pragma mark - SpringBoard

@protocol UIWindowDelegate
@optional
- (BOOL)window:(UIWindow*)window shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)window:(UIWindow*)window willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration;
- (void)window:(UIWindow*)window willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration;
- (void)window:(UIWindow*)window willAnimateFromContentFrame:(CGRect)fromFrame toContentFrame:(CGRect)toFrame;
- (void)window:(UIWindow*)window willAnimateFirstHalfOfRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration;
- (void)window:(UIWindow*)window didAnimateFirstHalfOfRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)window:(UIWindow*)window willAnimateSecondHalfOfRotationFromInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration;
- (void)window:(UIWindow*)window didRotateFromInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (BOOL)shouldWindowUseOnePartInterfaceRotationAnimation:(UIWindow*)window;
- (UIView*)rotatingContentViewForWindow:(UIWindow*)window;
- (UIView*)rotatingHeaderViewForWindow:(UIWindow*)window;
- (UIView*)rotatingFooterViewForWindow:(UIWindow*)window;
- (id)clientsForRotationForWindow:(UIWindow*)window;
- (void)getRotationContentSettings:(void*)settings forWindow:(UIWindow*)window;
@end

@protocol BBWeeAppController <NSObject>
- (UIView *)view;
@optional
- (CGFloat)viewHeight;
- (void)viewWillAppear;
- (void)viewDidAppear;
- (void)viewWillDisappear;
- (void)viewDidDisappear;
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)loadPlaceholderView;
- (void)loadFullView;
- (void)unloadView;
- (void)clearShapshotImage;
- (void)loadView;
- (NSURL *)launchURL;
- (NSURL *)launchURLForTapLocation:(CGPoint)tapLocation;
@end

@interface CPDistributedMessagingCenter : NSObject
+ (CPDistributedMessagingCenter*)centerNamed:(NSString*)serverName;
- (id)_initWithServerName:(NSString*)serverName;
- (NSString*)name;
- (unsigned)_sendPort;
- (void)_serverPortInvalidated;
- (BOOL)sendMessageName:(NSString*)name userInfo:(NSDictionary*)info;
- (NSDictionary*)sendMessageAndReceiveReplyName:(NSString*)name userInfo:(NSDictionary*)info;
- (NSDictionary*)sendMessageAndReceiveReplyName:(NSString*)name userInfo:(NSDictionary*)info error:(NSError**)error;
- (void)sendMessageAndReceiveReplyName:(NSString*)name userInfo:(NSDictionary*)info toTarget:(id)target selector:(SEL)selector context:(void*)context;
- (BOOL)_sendMessage:(id)message userInfo:(id)info receiveReply:(id*)reply error:(id*)error toTarget:(id)target selector:(SEL)selector context:(void*)context;
- (BOOL)_sendMessage:(id)message userInfoData:(id)data oolKey:(id)key oolData:(id)data4 receiveReply:(id*)reply error:(id*)error;
- (void)runServerOnCurrentThread;
- (void)runServerOnCurrentThreadProtectedByEntitlement:(id)entitlement;
- (void)stopServer;
- (void)registerForMessageName:(NSString*)messageName target:(id)target selector:(SEL)selector;
- (void)unregisterForMessageName:(NSString*)messageName;
- (void)_dispatchMessageNamed:(id)named userInfo:(id)info reply:(id*)reply auditToken:(id*)token;
- (BOOL)_isTaskEntitled:(id*)entitled;
- (id)_requiredEntitlement;

@end

@interface BBBulletin : NSObject
@property(copy, nonatomic) NSString *bulletinID;
@property(copy, nonatomic) NSString *sectionID;
@property(copy, nonatomic) NSString *title;
@property(copy, nonatomic) NSString *subtitle;
@property(copy, nonatomic) NSString *message;
@property(retain, nonatomic) NSDictionary *context;
@end

@interface SBOrientationLockManager : NSObject
+ (id)sharedInstance;
- (void)updateLockOverrideForCurrentDeviceOrientation;
- (BOOL)lockOverrideEnabled;
- (void)enableLockOverrideForReason:(NSString *)reason forceOrientation:(UIInterfaceOrientation)orientation;
- (void)enableLockOverrideForReason:(NSString *)reason suggestOrientation:(UIInterfaceOrientation)orientation;
- (void)setLockOverrideEnabled:(BOOL)enabled forReason:(NSString *)reason;
- (UIInterfaceOrientation)userLockOrientation;
- (BOOL)isLocked;
- (void)unlock;
- (void)lock;
@end

@interface UIApplication (Private)
- (BOOL)launchApplicationWithIdentifier:(NSString *)identifier suspended:(BOOL)suspended;
@end

@interface UIViewController (Private)
- (void)_willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration forwardToChildControllers:(BOOL)forward skipSelf:(BOOL)skipSelf;
@end

@interface UIWindow (Private)
- (void)setDelegate:(id)delegate;
- (id)delegate;
- (void)_setRotatableViewOrientation:(UIInterfaceOrientation)orientation duration:(double)duration force:(BOOL)force;
@end

@interface UIDevice (Private)
- (void)setOrientation:(UIDeviceOrientation)orientation animated:(BOOL)animated;
@end

@interface UIAutoRotatingWindow : UIWindow
- (void)updateForOrientation:(UIInterfaceOrientation)orientation;
@end

@interface _UIAlertNormalizingOverlayWindow : UIWindow
@end

@interface UIAlertView (Private)
- (void)popupAlertAnimated:(BOOL)animated;
- (void)dismissAnimated:(BOOL)animated;
- (UIInterfaceOrientation)_currentOrientation;
- (void)layout;
- (void)_layoutPopupAlertWithOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated;
- (void)_keyboardDidHide:(NSNotification *)keyboard;
- (void)_keyboardWillHide:(NSNotification *)keyboard;
- (void)_keyboardWillShow:(NSNotification *)keyboard;
- (void)_repopup;
- (void)_repopupNoAnimation;
- (BOOL)_needsKeyboard;
- (BOOL)requiresPortraitOrientation;
@end

@interface UIActionSheet (Private)
- (void)_buttonClicked:(id)button;
@end

@interface UITextEffectsWindow : UIWindow
+ (UITextEffectsWindow *)sharedTextEffectsWindow;
- (void)resetTransform;
- (void)updateForOrientation:(UIInterfaceOrientation)orientation;
- (void)updateForOrientation:(UIInterfaceOrientation)orientation forceResetTransform:(BOOL)force;
@end

@interface UIPeripheralHostView : UIView
@end

@interface UIImage (Private)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;
@end

@interface UINavigationButton : UIButton
@property(assign, nonatomic) UIBarButtonItemStyle style;
@end

@interface UIPopoverController (Private)
- (void)_updateDimmingViewTransformForInterfaceOrientationOfHostingWindow:(UIWindow *)hostingWindow;
@end

@interface SBApplication : NSObject
- (NSString *)displayName;
@end

@interface SBApplicationController : NSObject
+ (SBApplicationController *)sharedInstance;
- (SBApplication *)applicationWithDisplayIdentifier:(NSString *)identifier;
@end

@interface SpringBoard : UIApplication
+ (SpringBoard *)sharedApplication;
- (UIInterfaceOrientation)_frontMostAppOrientation;
- (void)_openURLCore:(NSURL *)url display:(id)display animating:(BOOL)animating sender:(id)sender additionalActivationFlags:(id)flags;
@end

@interface SBBulletinBannerItem : NSObject
- (BBBulletin *)seedBulletin;
@end

@interface SBBannerController : NSObject
- (void)_handleBannerTapGesture:(UITapGestureRecognizer *)gestureRecognizer;
- (SBBulletinBannerItem *)currentBannerItem;
@end

@interface SBBulletinListController : UIViewController
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (BBBulletin *)_bulletinAtIndexPath:(NSIndexPath *)indexPath;
- (void)positionListViewAtY:(CGFloat)y;
@end

@interface SBAlertItem : NSObject
@end

@interface SBBulletinModalAlert : SBAlertItem {
    BBBulletin *_bulletin;
}
@end

@interface SBAlertItemsController : NSObject
- (void)activateAlertItem:(SBAlertItem *)alertItem;
@end

@interface TPBottomLockBar : UIView
- (void)unlock;
- (void)relock;
- (void)slideBack:(BOOL)animated;
@end

@interface SBBulletinLockBar : TPBottomLockBar
@end

@interface SBAwayListActionContext : NSObject
- (NSString *)bulletinID;
@end

@interface SBAwayBulletinCell : UITableViewCell
- (SBAwayListActionContext *)actionContext;
@end

@interface SBAwayBulletinListItem : NSObject
- (BBBulletin *)bulletinWithID:(NSString *)bulletinID;
@end

@interface SBAwayBulletinListController : NSObject
- (SBAwayBulletinListItem *)_listItemContainingBulletinID:(NSString *)bulletinID;
- (void)observer:(id)observer removeBulletin:(BBBulletin *)bulletin;
- (SBAwayListActionContext *)visibleActionContext;
@end

@interface SBAwayView : NSObject
- (SBAwayBulletinListController *)bulletinController;
@end

@interface SBAwayController : NSObject
+ (SBAwayController *)sharedAwayController;
- (SBAwayView *)awayView;
- (BOOL)isLocked;
- (void)restartDimTimer;
- (void)restartDimTimer:(float)seconds;
- (void)dimScreen:(BOOL)animated;
- (void)unlockWithSound:(BOOL)sound;
- (void)willAnimateToggleDeviceLockWithStyle:(int)style toVisibility:(BOOL)visibility withDuration:(double)duration;
- (void)_finishUnlockWithSound:(BOOL)sound unlockSource:(int)source isAutoUnlock:(BOOL)autoUnlock;
@end

@interface SBAwayController (Couria)
- (void)couria_unlockAndOpenApplication:(NSString *)applicationIdentifier;
@end

@interface SBUIController : NSObject
- (void)window:(UIWindow *)window willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration;
- (void)finishedUnscattering;
- (BOOL)clickedMenuButton;
@end

@interface BBServer : NSObject
- (void)_loadAllDataProviderPluginBundles;
- (NSSet *)_allBulletinsForSectionID:(NSString *)sectionID;
- (void)publishBulletin:(BBBulletin *)bulletin destinations:(int)destinations alwaysToLockScreen:(BOOL)lockScreen;
- (void)removeBulletinID:(NSString *)bulletinID fromListSection:(NSString *)sectionID;
@end

@interface BBServer (Couria)
+ (BBServer *)sharedInstance;
@end

@interface SBIcon : NSObject
- (NSInteger)badgeValue;
@end

@interface SBLeafIcon : SBIcon
@end

@interface SBApplicationIcon : SBLeafIcon
- (void)setBadge:(NSString *)badge;
@end

@interface SBIconModel : NSObject
- (SBApplicationIcon *)applicationIconForDisplayIdentifier:(NSString *)identifier;
@end

@interface SBIconController : NSObject {
    SBIconModel *_iconModel;
}
+ (SBIconController *)sharedInstance;
@end

#pragma mark - DoodleMessage

@protocol DoodleViewControllerDelegate;
@interface DoodleViewController : UIViewController
- (id)initWithDelegate:(id<DoodleViewControllerDelegate>)delegate;
@end

@protocol DoodleViewControllerDelegate <NSObject>
@required
- (void)doodle:(DoodleViewController *)doodleViewController didFinishWithImage:(UIImage *)image;
@end

#pragma mark - Ayra

@interface AyraCenterListCell : SBAwayBulletinCell
+(CGFloat)optionsRowHeight;
-(void)lockBarStartedTracking:(id)arg1;
-(void)lockBarSlidBackToOrigin:(id)arg1;
-(BOOL)_createsLockBarEarly;
-(id)delegate;
-(void)setDelegate:(id)arg1;
-(void)_ayra_deleteButtonTapped;
-(void)_ayra_openButtonTapped;
-(void)willTransitionToState:(unsigned)arg1;
-(void)_setShowOptionButtons:(BOOL)arg1 touchContentView:(BOOL)arg2;
-(void)setShowOptionButtons:(BOOL)arg1;
-(void)setIsClearable:(BOOL)arg1;
-(void)prepareForReuse;
-(void)_ayra_swipeRecognizerFired;
-(id)initWithReuseIdentifier:(id)arg1;
@end

@interface AyraCenterDataSource : NSObject {
    NSMutableArray *bulletins;
}
- (AyraCenterListCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)didDeleteRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)didLaunchRowAtIndexPath:(NSIndexPath *)indexPath;
@end

#pragma mark - IntelliScreenX

@interface IntelliScreenX : NSObject
+ (IntelliScreenX *)sharedInstance;
- (void)openBulletin:(BBBulletin *)bulletin withOrigin:(NSInteger)origin canUnlock:(BOOL)unlock;
- (void)removeBulletin:(BBBulletin *)bulletin;
@end

@interface IntelliScreenXSelectHandler : NSObject
@property (nonatomic,retain) BBBulletin *currentBulletin;
- (NSInteger)buttonCount;
- (NSString *)titleForButton:(NSInteger)index;
- (UIImage *)imageForButton:(NSInteger)index;
- (void)buttonClicked:(UIButton *)button;
- (UIImage *)openImage;
- (UIImage *)unreadImage;
- (UIImage *)replyImage;
@end

@interface IntelliScreenXDefaultHandler : IntelliScreenXSelectHandler
@end

#pragma mark - LockInfo

@interface LIBulletinListController : SBBulletinListController
- (void)observer:(id)observer removeBulletin:(BBBulletin *)bulletin;
@end

@interface LIWidgetController : NSObject
@property(retain, nonatomic) LIBulletinListController *bulletinController;
@end

@interface LIController : NSObject
@property(retain, nonatomic) LIWidgetController *widgetController;
+ (LIController *)sharedInstance;
@end

#pragma mark - Velox

@interface NotificationsFolderView : UIView {
    NSString *appID;
	NSMutableArray *notifications;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end
