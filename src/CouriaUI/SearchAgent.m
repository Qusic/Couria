#import "../Headers.h"

@implementation CouriaSearchAgent {
    NSString *queryString;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.searchDomains = @[@(SPSearchDomainPerson)];
        self.delegate = self;
    }
    return self;
}

- (NSString *)queryString {
    return queryString;
}

- (void)setQueryString:(NSString *)string inputMode:(UITextInputMode *)mode {
    if ([queryString isEqualToString:string]) {
        [self notifyResults];
    } else {
        queryString = string;
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
            [super setQueryString:string keyboardLanguage:inputTypeForInputMode(mode) keyboardPrimaryLanguage:mode.primaryLanguage levelZKW:0 allowInternet:NO];
        } else if ([super respondsToSelector:@selector(setQueryString:)]) {
            [super setQueryString:string];
        }
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
    if ([self respondsToSelector:@selector(sections)] && [SPSearchResult instanceMethodForSelector:@selector(searchResultDomain)]) {
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

- (void)notifyResults {
    if (self.updateHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.updateHandler();
        });
    }
}

- (void)searchAgentUpdatedResults:(SPSearchAgent *)agent {
    [self notifyResults];
}

- (void)searchAgentClearedResults:(SPSearchAgent *)agent {
    [self notifyResults];
}

@end
