#import "../Headers.h"

@implementation CouriaAddressBook {
    ABAddressBookRef addressBook;
    CNContactStore *contactStore;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        contactStore = [[CNContactStore alloc]init];
    }
    return self;
}

- (BOOL)accessGranted {
    return ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized;
}

- (void)requestAccess {
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            dispatch_semaphore_signal(semaphore);
        });
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
}

- (NSArray *)processSearchResults:(NSArray *)searchResults withBlock:(id (^)(NSString *identifier, NSString *nickname, UIImage *avatar))block {
    NSMutableArray *results = [NSMutableArray array];
    if (CNContact.class) {
        NSMutableArray *identifiers = [NSMutableArray array];
        [searchResults enumerateObjectsUsingBlock:^(SPSearchResult *searchResult, NSUInteger index, BOOL *stop) {
            [identifiers addObject:searchResult.externalIdentifier];
        }];
        [[contactStore unifiedContactsMatchingPredicate:[CNContact predicateForContactsWithIdentifiers:identifiers] keysToFetch:@[[CNContactFormatter descriptorForRequiredKeysForStyle:CNContactFormatterStyleFullName], [CNAvatarView descriptorForRequiredKeys], CNContactPhoneNumbersKey, CNContactEmailAddressesKey] error:NULL]enumerateObjectsUsingBlock:^(CNContact *contact, NSUInteger index, BOOL *stop) {
            NSString *name = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName];
            UIImage *avatar = [self avatarImageForContacts:@[contact]];
            void (^ processLabeledValue)(NSString *, NSString *) = ^(NSString *label, NSString *value) {
                if (value.length > 0) {
                    NSString *nickname = label.length > 0 ? [NSString stringWithFormat:@"%@ (%@)", name, [CNLabeledValue localizedStringForLabel:label]] : [NSString stringWithFormat:@"%@", name];
                    NSString *identifier = IMStripFormattingFromAddress(value);
                    [results addObject:block(identifier, nickname, avatar)];
                }
            };
            [contact.phoneNumbers enumerateObjectsUsingBlock:^(CNLabeledValue<CNPhoneNumber *> *labeledValue, NSUInteger index, BOOL *stop) {
                processLabeledValue(labeledValue.label, labeledValue.value.stringValue);
            }];
            [contact.emailAddresses enumerateObjectsUsingBlock:^(CNLabeledValue<NSString *> *labeledValue, NSUInteger index, BOOL *stop) {
                processLabeledValue(labeledValue.label, labeledValue.value);
            }];
        }];
    } else {
        [searchResults enumerateObjectsUsingBlock:^(SPSearchResult *searchResult, NSUInteger index, BOOL *stop) {
            ABRecordID recordID = (ABRecordID)searchResult.identifier;
            ABRecordRef record = ABAddressBookGetPersonWithRecordID(addressBook, recordID);
            if (record != NULL) {
                NSString *name = CFBridgingRelease(ABRecordCopyCompositeName(record));
                UIImage *avatar = [CKAddressBook transcriptContactImageOfDiameter:[CKUIBehavior sharedBehaviors].transcriptContactImageDiameter forRecordID:recordID];
                void (^ processMultiValueProperty)(ABPropertyID) = ^(ABPropertyID property) {
                    ABMultiValueRef multiValue = ABRecordCopyValue(record, property);
                    for (CFIndex index = 0, count = ABMultiValueGetCount(multiValue); index < count; index++) {
                        NSString *label = CFBridgingRelease(ABMultiValueCopyLabelAtIndex(multiValue, index));
                        NSString *value = CFBridgingRelease(ABMultiValueCopyValueAtIndex(multiValue, index));
                        if (value.length > 0) {
                            NSString *identifier = IMStripFormattingFromAddress(value);
                            NSString *nickname = label ? [NSString stringWithFormat:@"%@ (%@)", name, CFBridgingRelease(ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)label))] : [NSString stringWithFormat:@"%@", name];
                            [results addObject:block(identifier, nickname, avatar)];
                        }
                    }
                    CFRelease(multiValue);
                };
                processMultiValueProperty(kABPersonPhoneProperty);
                processMultiValueProperty(kABPersonEmailProperty);
            }
        }];
    }
    return results;
}

- (UIImage *)avatarImageForContacts:(NSArray *)contacts {
    static CNAvatarView *avatarView;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGFloat size = [CKUIBehavior sharedBehaviors].transcriptContactImageDiameter;
        avatarView = [[CNAvatarView alloc]initWithFrame:CGRectMake(0, 0, size, size)];
    });
    avatarView.contacts = contacts;
    [avatarView _updateAvatarView];
    return avatarView.contentImage;
}

@end
