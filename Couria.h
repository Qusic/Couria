#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class BBBulletin;

@protocol CouriaMessage <NSObject>

@required
- (id)content; // The class of returned object must be: NSString for text messages, NSURL for images and any other attachments.
- (BOOL)outgoing;

@optional
- (NSDate *)timestamp;

@end

@protocol CouriaExtension <NSObject>

@required
- (NSString *)getUserIdentifier:(BBBulletin *)bulletin; // UserIdentifier is used to uniquely identify each contact, which usually can be found in bulletins of that application. Return nil if this bulletin should not be handled by Couria.
@optional
- (NSString *)getNickname:(NSString *)userIdentifier; // Nickname will be displayed in user interface. The default value is userIdentifier.
- (NSArray *)getMessages:(NSString *)userIdentifier; // Some previous messages sorted in ascending order by date. Objects in the returned NSArray must conform to CouriaMessage protocol. The default value is nil.
- (UIImage *)getAvatar:(NSString *)userIdentifier; // Avatar will be displayed in user interface. The default value is nil.
- (NSArray *)getContacts:(NSString *)keyword; // Search results of contacts by keyword. A non-nil NSArray of userIdentifiers should be returned when quick compose feature should be available currently. The default value is nil.

@required
- (void)sendMessage:(id<CouriaMessage>)message toUser:(NSString *)userIdentifier; // Send a message to a user identified by userIdentifier.
@optional
- (void)markRead:(NSString *)userIdentifier; // Mark all messages of a user identified by userIdentifier as read. The default implementation does nothing.

@optional
- (BOOL)canSendPhotos; // Whether photo messages are supported. The default value is NO.
- (BOOL)shouldClearNotifications; // If YES, when messages of a user are marked as read, the corresponding notifications will be cleared and the badge number will be decreased accordingly. If NO, nothing will be done automatically. If automatic clearing notifications does not work correctly, you should return NO and do it yourself. The default value is YES.

@end

@interface Couria : NSObject // This class is only available in SpringBoard by using NSClassFromString(@"Couria")

+ (instancetype)sharedInstance; // You should always use this shared instance when needed.
- (void)registerExtension:(id<CouriaExtension>)extension forApplication:(NSString *)applicationIdentifier; // Register your extension for an application.
- (void)unregisterExtensionForApplication:(NSString *)applicationIdentifier; // Unregister your extension for an application.
- (void)presentControllerForApplication:(NSString *)applicationIdentifier user:(NSString *)userIdentifier; // Manually present a quick compose view controller. If applicationIdentifier has not been registered, nothing will happen. If userIdentifier is nil and getContacts: has been implemented in the data source, contacts search view will be showed.
- (void)handleBulletin:(BBBulletin *)bulletin; // Manually activate action of a bulletin. You may find useful if you are making some notifications tweaks.

@end
