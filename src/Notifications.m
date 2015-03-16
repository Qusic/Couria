#import "Headers.h"

CHDeclareClass(BBServer)

CHOptimizedMethod(4, self, void, BBServer, _publishBulletinRequest, BBBulletinRequest *, bulletinRequest, forSectionID, NSString *, sectionID, forDestinations, NSUInteger, destinations, alwaysToLockScreen, BOOL, alwaysToLockScreen)
{
    CouriaUpdateBulletinRequest(bulletinRequest);
    CHSuper(4, BBServer, _publishBulletinRequest, bulletinRequest, forSectionID, sectionID, forDestinations, destinations, alwaysToLockScreen, alwaysToLockScreen);
}

CHOptimizedMethod(3, self, void, BBServer, publishBulletinRequest, BBBulletinRequest *, bulletinRequest, destinations, NSUInteger, destinations, alwaysToLockScreen, BOOL, alwaysToLockScreen)
{
    CouriaUpdateBulletinRequest(bulletinRequest);
    CHSuper(3, BBServer, publishBulletinRequest, bulletinRequest, destinations, destinations, alwaysToLockScreen, alwaysToLockScreen);
}

CHConstructor
{
    @autoreleasepool {
        CHLoadClass(BBServer);
        CHHook(4, BBServer, _publishBulletinRequest, forSectionID, forDestinations, alwaysToLockScreen);
        CHHook(3, BBServer, publishBulletinRequest, destinations, alwaysToLockScreen);
    }
}
