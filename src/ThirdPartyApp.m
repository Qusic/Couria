#import "Headers.h"

CHDeclareClass(CKInlineReplyViewController)
CHDeclareClass(CouriaInlineReplyViewController_ThirdPartyApp)

CHOptimizedMethod(0, super, void, CouriaInlineReplyViewController_ThirdPartyApp, setupConversation)
{
    //TODO: third party apps
}

CHOptimizedMethod(0, self, void, CouriaInlineReplyViewController_ThirdPartyApp, setupView)
{
    CHSuper(0, CouriaInlineReplyViewController_ThirdPartyApp, setupView);
    //TODO: third party apps
}

CHOptimizedMethod(0, super, void, CouriaInlineReplyViewController_ThirdPartyApp, interactiveNotificationDidAppear)
{
    //TODO: third party apps
}

CHConstructor
{
    @autoreleasepool {
        CHLoadLateClass(CKInlineReplyViewController);
        CHRegisterClass(CouriaInlineReplyViewController_ThirdPartyApp, CKInlineReplyViewController) {
            CHHook(0, CouriaInlineReplyViewController_ThirdPartyApp, setupConversation);
            CHHook(0, CouriaInlineReplyViewController_ThirdPartyApp, setupView);
            CHHook(0, CouriaInlineReplyViewController_ThirdPartyApp, interactiveNotificationDidAppear);
        }
    }
}
