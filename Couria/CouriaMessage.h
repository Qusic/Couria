#import <Foundation/Foundation.h>

@interface CouriaMessage : NSObject <CouriaMessage>

@property(retain) NSString *text;
@property(retain) id media;
@property(assign) BOOL outgoing;

@end
