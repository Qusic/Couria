#import "../Headers.h"

CHDeclareClass(SBBannerController)

CHOptimizedMethod(4, self, void, SBBannerController, _handleGestureState, NSInteger, state, location, CGPoint, location, displacement, CGFloat, displacement, velocity, CGFloat, velocity)
{
    if (!self.isShowingModalBanner || CHIvar(self, _activeGestureType, NSInteger) != 2) {
        CHSuper(4, SBBannerController, _handleGestureState, state, location, location, displacement, displacement, velocity, velocity);
    }
}

void CouriaGesturesInit(void)
{
    CHLoadLateClass(SBBannerController);
    CHHook(4, SBBannerController, _handleGestureState, location, displacement, velocity);
}
