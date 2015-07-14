#import "../Headers.h"

static BBServer *bbServer;

CHDeclareClass(BBServer)

CHOptimizedClassMethod(0, new, id, BBServer, sharedInstance)
{
    return bbServer;
}

CHOptimizedMethod(0, self, id, BBServer, init)
{
    self = bbServer = CHSuper(0, BBServer, init);
    return self;
}

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

void CouriaNotificationsInit(void)
{
    CHLoadClass(BBServer);
    CHHook(0, BBServer, sharedInstance);
    CHHook(0, BBServer, init);
    CHHook(4, BBServer, _publishBulletinRequest, forSectionID, forDestinations, alwaysToLockScreen);
    CHHook(3, BBServer, publishBulletinRequest, destinations, alwaysToLockScreen);
}
