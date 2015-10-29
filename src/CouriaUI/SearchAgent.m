#import "../Headers.h"

@implementation CouriaSearchAgent

- (instancetype)init {
    self = [super init];
    if (self) {
        self.searchDomains = @[@(SPSearchDomainPerson)];
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

- (void)setQueryString:(NSString *)queryString inputMode:(UITextInputMode *)inputMode {
    if ([super respondsToSelector:@selector(setQueryString:keyboardLanguage:keyboardPrimaryLanguage:levelZKW:allowInternet:)]) {
        static NSString * (^ const inputTypeForInputMode)(UITextInputMode *) = ^(UITextInputMode *inputMode) {
            NSString *inputType = nil;
            if ([inputMode isKindOfClass:UITextInputMode.class]) {
                if ([inputMode.identifier isEqualToString:@"dictation"]) {
                    inputType = @"dictation";
                } else if (inputMode.extension != nil) {
                    inputType = @"custom";
                } else {
                    inputType = inputMode.normalizedIdentifierLevels.firstObject;
                }
            }
            return inputType;
        };
        [super setQueryString:queryString keyboardLanguage:inputTypeForInputMode(inputMode) keyboardPrimaryLanguage:inputMode.primaryLanguage levelZKW:0 allowInternet:NO];
    } else if ([super respondsToSelector:@selector(setQueryString:)]) {
        [super setQueryString:queryString];
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

- (NSArray *)contactsResults {
    if ([SPSearchResult instanceMethodForSelector:@selector(searchResultDomain)]) {
        NSMutableArray *results = [NSMutableArray array];
        [self.sections enumerateObjectsUsingBlock:^(SPSearchResultSection *section, NSUInteger index, BOOL *stop) {
            if (section.domain == SPSearchDomainPerson) {
                [results addObjectsFromArray:section.results];
            } else {
                [section.results enumerateObjectsUsingBlock:^(SPSearchResult *result, NSUInteger index, BOOL *stop) {
                    if (result.searchResultDomain == SPSearchDomainPerson) {
                        [results addObject:result];
                    }
                }];
            }
        }];
        return results;
    } else {
        return [self sectionAtIndex:0].results;
    }
}

- (SPSearchResultSection *)contactsSection {
    return [self.sections filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(SPSearchResultSection *section, NSDictionary *bindings) {
        return section.domain == SPSearchDomainPerson;
    }]].firstObject;
}

@end
