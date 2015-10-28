#import "../Headers.h"

static NSUInteger const contactsSearchDomain = 2;

@implementation CouriaSearchAgent

- (instancetype)init {
    self = [super init];
    if (self) {
        self.searchDomains = @[@(contactsSearchDomain)];
        self.delegate = self;
    }
    return self;
}

- (void)searchAgentUpdatedResults:(SPSearchAgent *)agent {
    if (self.updateHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.updateHandler();
        });
    }
}

- (void)searchAgentClearedResults:(SPSearchAgent *)agent {
    if (self.updateHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.updateHandler();
        });
    }
}

- (BOOL)hasResults {
    if ([super respondsToSelector:@selector(hasResults)]) {
        return [super hasResults];
    } else if ([super respondsToSelector:@selector(resultCount)]) {
        return super.resultCount > 0;
    } else {
        return NO;
    }
}

- (SPSearchResultSection *)contactsSection {
    return [self.sections filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(SPSearchResultSection *section, NSDictionary *bindings) {
        return section.domain == contactsSearchDomain;
    }]].firstObject;
}

@end
