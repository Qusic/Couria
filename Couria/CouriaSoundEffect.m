#import "CouriaSoundEffect.h"
#import <AudioToolbox/AudioToolbox.h>

static SystemSoundID messageReceivedSound;
static SystemSoundID messageSentSound;

@implementation CouriaSoundEffect

+ (void)load
{
    AudioServicesCreateSystemSoundID(CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFSTR("/System/Library/Audio/UISounds/ReceivedMessage.caf"), kCFURLPOSIXPathStyle, false), &messageReceivedSound);
    AudioServicesCreateSystemSoundID(CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFSTR("/System/Library/Audio/UISounds/SentMessage.caf"), kCFURLPOSIXPathStyle, false), &messageSentSound);
}

+ (void)playMessageReceivedSound
{
    AudioServicesPlaySystemSound(messageReceivedSound);
}

+ (void)playMessageSentSound
{
    AudioServicesPlaySystemSound(messageSentSound);
}

@end
