//
//  JTSTextView.m
//  JSTTextView
//
//  Created by Jared Sinclair on 10/26/13.
//  Copyright (c) 2013 Nice Boy LLC. All rights reserved.
//

#import "JTSTextView.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "JTSTextView requires ARC support."
#endif

@interface JTSTextView () <UITextViewDelegate>

@property (assign, nonatomic) CGRect currentKeyboardFrame;
@property (strong, nonatomic) UITextView *textView;
@property (assign, nonatomic) NSRange previousSelectedRange;
@property (assign, nonatomic) BOOL useLinearNextScrollAnimation;
@property (assign, nonatomic) BOOL ignoreNextTextSelectionAnimation;

@end

#define BOTTOM_PADDING 8.0f
#define SLOW_DURATION 0.4f
#define FAST_DURATION 0.2f

@implementation JTSTextView

- (instancetype)initWithFrame:(CGRect)frame
                  textStorage:(NSTextStorage*)textStorage {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInitWithTextStorage:textStorage];
    }
    return self;
}

- (void)dealloc {
    [self removeKeyboardNotifications];
}

- (id)initWithFrame:(CGRect)frame  {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInitWithTextStorage:[[NSTextStorage alloc] init]];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self commonInitWithTextStorage:[[NSTextStorage alloc] init]];
}

- (void)commonInitWithTextStorage:(NSTextStorage*)textStorage {
    [self setBackgroundColor:[UIColor whiteColor]];

    [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    
    // Setup TextKit stack for the private text view.
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [textStorage addLayoutManager:layoutManager];
    NSTextContainer *container = [[NSTextContainer alloc] initWithSize:CGSizeMake(self.frame.size.width, 100000)];
    [layoutManager addTextContainer:container];
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 100000) textContainer:container];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.textView];
    self.textView.showsHorizontalScrollIndicator = NO;
    self.textView.showsVerticalScrollIndicator = NO;
    [self.textView setAlwaysBounceHorizontal:NO];
    [self.textView setAlwaysBounceVertical:NO];
    [self.textView setScrollsToTop:NO];
    [self.textView setDelegate:self];
    
    NSDictionary *defaltAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:17],
                                       NSForegroundColorAttributeName:[UIColor blackColor]};
    [self.textView setAttributedText:[[NSAttributedString alloc] initWithString:@" " attributes:defaltAttributes]];
    
    // Observes keyboard changes by default
    [self setAutomaticallyAdjustsContentInsetForKeyboard:YES];
    [self addKeyboardNotifications];
}

#pragma mark - These Are Why This Works

// The various method & delegate method implementations in this pragma marked section
// are why JTSTextView works. Edit these with extreme care.

- (void)updateContentSize:(BOOL)scrollToVisible delay:(CGFloat)delay {
    CGRect boundingRect = [self.textView.layoutManager usedRectForTextContainer:self.textView.textContainer];
    boundingRect.size.height = roundf(boundingRect.size.height+16.0f); // + 16.0 for content inset.
    boundingRect.size.width = self.frame.size.width;
    [self setContentSize:boundingRect.size];
    if (scrollToVisible) {
        if (delay) {
            __weak JTSTextView *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf setUseLinearNextScrollAnimation:NO];
                [weakSelf simpleScrollToCaret];
            });
        } else {
            [self setUseLinearNextScrollAnimation:NO];
            [self simpleScrollToCaret];
        }
    }
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
    [super setContentOffset:self.contentOffset animated:NO]; // Fixes a bug that breaks scrolling to top via status bar taps.
    // setContentOffset:animated: is called by UIScrollView inside its implementation
    // of scrollRectToVisible:animated:. The super implementation of
    // setContentOffset:animated: is jaggy when it's called multiple times in row.
    // Fuck that noise.
    // The following animation can be called multiple times in a row smoothly, with
    // one minor exception: we flip a dirty bit for "useLinearNextScrollAnimation"
    // for the scroll animation used when mimicking the long-press-and-drag-to-the-top-
    // or-bottom-edge-of-the-view with a selection caret animation.
    contentOffset = CGPointMake(0, roundf(contentOffset.y));
    CGFloat duration;
    UIViewAnimationOptions options;
    if (self.useLinearNextScrollAnimation) {
        duration = (animated) ? SLOW_DURATION : 0;
        options = UIViewAnimationOptionCurveLinear
        | UIViewAnimationOptionBeginFromCurrentState
        | UIViewAnimationOptionOverrideInheritedDuration
        | UIViewAnimationOptionOverrideInheritedCurve;
    } else {
        duration = (animated) ? FAST_DURATION : 0;
        options = UIViewAnimationOptionCurveEaseInOut
        | UIViewAnimationOptionBeginFromCurrentState
        | UIViewAnimationOptionOverrideInheritedDuration
        | UIViewAnimationOptionOverrideInheritedCurve;
    }
    [self setUseLinearNextScrollAnimation:NO];
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        [super setContentOffset:contentOffset];
    } completion:nil];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    // Update the content size in setFrame: (rather than layoutSubviews)
    // because self is a UIScrollView and we don't need to update the
    // content size every time the scroll view calls layoutSubviews,
    // which is often.
    
    // Set delay to YES to boot the scroll animation to the next runloop,
    // or else the scrollRectToVisible: call will be
    // cancelled out by the animation context in which setFrame: is
    // usually called.
    
    [self updateContentSize:YES delay:YES];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    BOOL shouldChange = YES;
    if ([self.textViewDelegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
        shouldChange = [self.textViewDelegate textView:self shouldChangeTextInRange:range replacementText:text];
    }
    if (shouldChange) {
        // Ignore the next animation that would otherwise be triggered by the cursor moving
        // to a new spot. We animate to chase after the cursor as you type via the updateContentSize:(BOOL)scrollToVisible
        // method. Most of the time, we want to also animate inside of textViewDidChangeSelection:, but only when
        // that change is a "true" text selection change, and not the implied change that occurs when a new character is
        // typed or deleted.
        [self setIgnoreNextTextSelectionAnimation:YES];
    }
    return shouldChange;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self updateContentSize:YES delay:NO];
    if ([self.textViewDelegate respondsToSelector:@selector(textViewDidChange:)]) {
        [self.textViewDelegate textViewDidChange:self];
    }
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    NSRange selectedRange = textView.selectedRange;
    if (self.ignoreNextTextSelectionAnimation == YES) {
        [self setIgnoreNextTextSelectionAnimation:NO];
    } else if (selectedRange.length != textView.textStorage.length) {
        if (selectedRange.length == 0 || selectedRange.location < self.previousSelectedRange.location) {
            // Scroll to start caret
            CGRect caretRect = [self.textView caretRectForPosition:self.textView.selectedTextRange.start];
            CGRect targetRect = CGRectInset(caretRect, -1.0f, -8.0f);
            [self setUseLinearNextScrollAnimation:YES];
            [self scrollRectToVisible:targetRect animated:YES];
        }
        else if (selectedRange.location > self.previousSelectedRange.location) {
            CGRect firstRect = [textView firstRectForRange:textView.selectedTextRange];
            CGFloat bottomVisiblePointY = self.contentOffset.y + self.frame.size.height - self.contentInset.top - self.contentInset.bottom;
            if (firstRect.origin.y > bottomVisiblePointY - firstRect.size.height*1.1) {
                // Scroll to start caret
                CGRect caretRect = [self.textView caretRectForPosition:self.textView.selectedTextRange.start];
                CGRect targetRect = CGRectInset(caretRect, -1.0f, -8.0f);
                [self setUseLinearNextScrollAnimation:YES];
                [self scrollRectToVisible:targetRect animated:YES];
            }
        }
        else if (selectedRange.location == self.previousSelectedRange.location) {
            // Scroll to end caret
            CGRect caretRect = [self.textView caretRectForPosition:self.textView.selectedTextRange.end];
            CGRect targetRect = CGRectInset(caretRect, -1.0f, -8.0f);
            [self setUseLinearNextScrollAnimation:YES];
            [self scrollRectToVisible:targetRect animated:YES];
        }
    }
    [self setPreviousSelectedRange:selectedRange];
    if ([self.textViewDelegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
        [self.textViewDelegate textViewDidChangeSelection:self];
    }
}

#pragma mark - Text View Mimicry

- (BOOL)becomeFirstResponder {
   return [self.textView becomeFirstResponder];
}

- (BOOL)isFirstResponder {
    return [self.textView isFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [self.textView resignFirstResponder];
}

- (NSString *)text {
    return self.textView.text;
}

- (void)setText:(NSString *)text {
    [self.textView setText:text];
}

- (NSAttributedString *)attributedText {
    return self.textView.attributedText;
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    [self.textView setAttributedText:attributedText];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    [self.textView setBackgroundColor:backgroundColor];
}

- (UIFont *)font {
    return self.textView.font;
}

- (void)setFont:(UIFont *)font {
    [self.textView setFont:font];
}

- (UIColor *)textColor {
    return self.textView.textColor;
}

- (void)setTextColor:(UIColor *)textColor {
    [self.textView setTextColor:textColor];
}

- (NSTextAlignment)textAlignment {
    return self.textView.textAlignment;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    [self.textView setTextAlignment:textAlignment];
}

- (NSRange)selectedRange {
    return self.textView.selectedRange;
}

- (void)setSelectedRange:(NSRange)selectedRange {
    [self.textView setSelectedRange:selectedRange];
}

- (BOOL)isEditable {
    return [self.textView isEditable];
}

- (void)setEditable:(BOOL)editable {
    [self.textView setEditable:editable];
}

- (BOOL)isSelectable {
    return [self.textView isSelectable];
}

- (void)setSelectable:(BOOL)selectable {
    [self.textView setSelectable:selectable];
}

- (UIDataDetectorTypes)dataDetectorTypes {
    return self.textView.dataDetectorTypes;
}

- (void)setDataDetectorTypes:(UIDataDetectorTypes)dataDetectorTypes {
    [self.textView setDataDetectorTypes:dataDetectorTypes];
}

- (BOOL)allowsEditingTextAttributes {
    return self.textView.allowsEditingTextAttributes;
}

- (void)setAllowsEditingTextAttributes:(BOOL)allowsEditingTextAttributes {
    [self.textView setAllowsEditingTextAttributes:allowsEditingTextAttributes];
}

- (NSDictionary *)typingAttributes {
    return self.textView.typingAttributes;
}

- (void)setTypingAttributes:(NSDictionary *)typingAttributes {
    [self.textView setTypingAttributes:typingAttributes];
}

- (UIView *)jts_inputView {
    return self.textView.inputView;
}

- (void)setJts_inputView:(UIView *)jts_inputView {
    [self.textView setInputView:jts_inputView];
}

- (UIView *)jts_inputAccessoryView {
    return self.textView.inputAccessoryView;
}

- (void)setJts_inputAccessoryView:(UIView *)jts_inputAccessoryView {
    [self.textView setInputAccessoryView:jts_inputAccessoryView];
}

- (BOOL)clearsOnInsertion {
    return self.textView.clearsOnInsertion;
}

- (void)setClearsOnInsertion:(BOOL)clearsOnInsertion {
    [self.textView setClearsOnInsertion:clearsOnInsertion];
}

- (NSTextContainer *)textContainer {
    return [self.textView textContainer];
}

- (UIEdgeInsets)textContainerInset {
    return [self.textView textContainerInset];
}

- (void)setTextContainerInset:(UIEdgeInsets)textContainerInset {
    [self.textView setTextContainerInset:textContainerInset];
}

- (NSLayoutManager *)layoutManager {
    return self.textView.layoutManager;
}

- (NSTextStorage *)textStorage {
    return [self.textView textStorage];
}

- (NSDictionary *)linkTextAttributes {
    return [self.textView linkTextAttributes];
}

- (void)setLinkTextAttributes:(NSDictionary *)linkTextAttributes {
    [self.textView setLinkTextAttributes:linkTextAttributes];
}

- (UITextAutocapitalizationType)autocapitalizationType {
    return self.textView.autocapitalizationType;
}

- (void)setAutocapitalizationType:(UITextAutocapitalizationType)autocapitalizationType {
    [self.textView setAutocapitalizationType:autocapitalizationType];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-property-ivar"
- (UITextAutocorrectionType)autocorrectionType {
    return self.textView.autocorrectionType;
}
#pragma clang diagnostic pop

- (UITextSpellCheckingType)spellCheckingType {
    return self.textView.spellCheckingType;
}

- (void)setSpellCheckingType:(UITextSpellCheckingType)spellCheckingType {
    [self.textView setSpellCheckingType:spellCheckingType];
}

- (UIKeyboardType)keyboardType {
    return self.textView.keyboardType;
}

- (void)setKeyboardType:(UIKeyboardType)keyboardType {
    [self.textView setKeyboardType:keyboardType];
}

- (UIKeyboardAppearance)keyboardAppearance {
    return self.keyboardAppearance;
}

- (void)setKeyboardAppearance:(UIKeyboardAppearance)keyboardAppearance {
    [self.textView setKeyboardAppearance:keyboardAppearance];
}

- (UIReturnKeyType)returnKeyType {
    return self.textView.returnKeyType;
}

- (void)setReturnKeyType:(UIReturnKeyType)returnKeyType {
    [self.textView setReturnKeyType:returnKeyType];
}

- (BOOL)enablesReturnKeyAutomatically {
    return self.textView.enablesReturnKeyAutomatically;
}

- (void)setEnablesReturnKeyAutomatically:(BOOL)enablesReturnKeyAutomatically {
    [self.textView setEnablesReturnKeyAutomatically:enablesReturnKeyAutomatically];
}

- (BOOL)isSecureTextEntry {
    return [self.textView isSecureTextEntry];
}

- (void)setSecureTextEntry:(BOOL)secureTextEntry {
    [self.textView setSecureTextEntry:secureTextEntry];
}

- (void)scrollRangeToVisible:(NSRange)range {
    [self.textView scrollRangeToVisible:range];
}

- (void)insertText:(NSString *)text {
    [self.textView insertText:text];
}

#pragma mark - Text View Delegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    BOOL shouldBegin = YES;
    if ([self.textViewDelegate respondsToSelector:@selector(textViewShouldBeginEditing:)]) {
        shouldBegin = [self.textViewDelegate textViewShouldBeginEditing:self];
    }
    return shouldBegin;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    BOOL shouldEnd = YES;
    if ([self.textViewDelegate respondsToSelector:@selector(textViewShouldEndEditing:)]) {
        shouldEnd = [self.textViewDelegate textViewShouldEndEditing:self];
    }
    return shouldEnd;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [self simpleScrollToCaret];
    if ([self.textViewDelegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
        [self.textViewDelegate textViewDidBeginEditing:self];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([self.textViewDelegate respondsToSelector:@selector(textViewDidEndEditing:)]) {
        [self.textViewDelegate textViewDidEndEditing:self];
    }
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    BOOL shouldInteract = NO;
    if ([self.textViewDelegate respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:)]) {
        shouldInteract = [self.textViewDelegate textView:self shouldInteractWithURL:URL inRange:characterRange];
    }
    return shouldInteract;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange {
    BOOL shouldInteract = NO;
    if ([self.textViewDelegate respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:)]) {
        shouldInteract = [self.textViewDelegate textView:self shouldInteractWithTextAttachment:textAttachment inRange:characterRange];
    }
    return shouldInteract;
}

#pragma mark - Keyboard Changes

- (void)simpleScrollToCaret {
    CGRect caretRect = [self.textView caretRectForPosition:self.textView.selectedTextRange.end];
    [self scrollRectToVisible:CGRectInset(caretRect, -1.0f, -8.0f) animated:YES];
}

- (void)addKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)removeKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    if (self.automaticallyAdjustsContentInsetForKeyboard) {
        NSValue *frameValue = [notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
        CGRect targetKeyboardFrame = CGRectZero;
        [frameValue getValue:&targetKeyboardFrame];
        
        // Convert from window coordinates to my coordinates
        targetKeyboardFrame = [self.superview convertRect:targetKeyboardFrame fromView:nil];
        
        [self setCurrentKeyboardFrame:targetKeyboardFrame];
        [self updateBottomContentInset:targetKeyboardFrame];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if (self.automaticallyAdjustsContentInsetForKeyboard) {
        [self setCurrentKeyboardFrame:CGRectZero];
        [self updateBottomContentInset:CGRectZero];
    }
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    if (self.automaticallyAdjustsContentInsetForKeyboard) {
        NSValue *frameValue = [notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
        CGRect targetKeyboardFrame = CGRectZero;
        [frameValue getValue:&targetKeyboardFrame];
        
        // Convert from window coordinates to my coordinates
        targetKeyboardFrame = [self.superview convertRect:targetKeyboardFrame fromView:nil];
        
        [self setCurrentKeyboardFrame:targetKeyboardFrame];
        [self updateBottomContentInset:targetKeyboardFrame];
    }
}

- (void)updateBottomContentInset:(CGRect)keyboardFrame {
    CGRect intersection = CGRectIntersection(self.frame, keyboardFrame);
    UIEdgeInsets insets = self.contentInset;
    insets.bottom = intersection.size.height;
    [self setContentInset:insets];
    
    UIEdgeInsets scrollInsets = self.scrollIndicatorInsets;
    scrollInsets.bottom = intersection.size.height;
    [self setScrollIndicatorInsets:scrollInsets];
}

- (void)setAutomaticallyAdjustsContentInsetForKeyboard:(BOOL)automaticallyAdjustsContentInsetForKeyboard {
    if (_automaticallyAdjustsContentInsetForKeyboard != automaticallyAdjustsContentInsetForKeyboard) {
        _automaticallyAdjustsContentInsetForKeyboard = automaticallyAdjustsContentInsetForKeyboard;
        if (_automaticallyAdjustsContentInsetForKeyboard == NO) {
            [self setCurrentKeyboardFrame:CGRectZero];
            [self updateBottomContentInset:CGRectZero];
        }
    }
}

@end
