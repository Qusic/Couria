#import "CouriaSoundEffect.h"
#import <AudioToolbox/AudioToolbox.h>

static SystemSoundID messageReceivedSound;
static SystemSoundID messageSentSound;

@implementation CouriaSoundEffect

+ (void)load
{
    CFURLRef receivedSoundURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFSTR("/System/Library/Audio/UISounds/ReceivedMessage.caf"), kCFURLPOSIXPathStyle, false);
    CFURLRef sentSoundURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFSTR("/System/Library/Audio/UISounds/SentMessage.caf"), kCFURLPOSIXPathStyle, false);
    AudioServicesCreateSystemSoundID(receivedSoundURL, &messageReceivedSound);
    AudioServicesCreateSystemSoundID(sentSoundURL, &messageSentSound);
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
