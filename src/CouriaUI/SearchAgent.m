#import "../Headers.h"

@implementation CouriaSearchAgent

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.searchDomains = @[@2];
        self.delegate = self;
    }
    return self;
}

- (void)searchAgentUpdatedResults:(SPSearchAgent *)agent
{
    if (self.updateHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.updateHandler();
        });
    }
}

- (void)searchAgentClearedResults:(SPSearchAgent *)agent
{
    if (self.updateHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.updateHandler();
        });
    }
}

@end
