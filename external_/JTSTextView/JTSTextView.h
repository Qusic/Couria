//
//  JTSTextView.h
//  JSTTextView
//
//  Created by Jared Sinclair on 10/26/13.
//  Copyright (c) 2013 Nice Boy LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JTSTextView;



// PROXIED TEXT VIEW DELEGATE ===============================================================================================

@protocol JTSTextViewDelegate <NSObject>
@optional

- (BOOL)textViewShouldBeginEditing:(JTSTextView *)textView;
- (BOOL)textViewShouldEndEditing:(JTSTextView *)textView;

- (void)textViewDidBeginEditing:(JTSTextView *)textView;
- (void)textViewDidEndEditing:(JTSTextView *)textView;

- (BOOL)textView:(JTSTextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
- (void)textViewDidChange:(JTSTextView *)textView;

- (void)textViewDidChangeSelection:(JTSTextView *)textView;

- (BOOL)textView:(JTSTextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange NS_AVAILABLE_IOS(7_0);
- (BOOL)textView:(JTSTextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange NS_AVAILABLE_IOS(7_0);

@end



// JTSTextView INTERFACE PROPER ===============================================================================================

@interface JTSTextView : UIScrollView

- (instancetype)initWithFrame:(CGRect)frame
                  textStorage:(NSTextStorage*)textStorage;

@property (weak, nonatomic) id <JTSTextViewDelegate> textViewDelegate;
@property (copy, nonatomic) NSAttributedString *attributedText;
@property (copy, nonatomic) NSString *text;

@property (assign, nonatomic) BOOL automaticallyAdjustsContentInsetForKeyboard; // Defaults to YES

@property(nonatomic,retain) UIFont *font;
@property(nonatomic,retain) UIColor *textColor;
@property(nonatomic) NSTextAlignment textAlignment;    // default is NSLeftTextAlignment
@property(nonatomic) NSRange selectedRange;
@property(nonatomic,getter=isEditable) BOOL editable;
@property(nonatomic,getter=isSelectable) BOOL selectable NS_AVAILABLE_IOS(7_0); // toggle selectability, which controls the ability of the user to select content and interact with URLs & attachments
@property(nonatomic) UIDataDetectorTypes dataDetectorTypes NS_AVAILABLE_IOS(3_0);
@property(nonatomic) BOOL allowsEditingTextAttributes NS_AVAILABLE_IOS(6_0); // defaults to NO
@property(nonatomic,copy) NSDictionary *typingAttributes NS_AVAILABLE_IOS(6_0); // automatically resets when the selection changes
@property(nonatomic, strong) UIView *jts_inputView;
@property(nonatomic, strong) UIView *jts_inputAccessoryView;
@property(nonatomic) BOOL clearsOnInsertion NS_AVAILABLE_IOS(6_0);
@property(nonatomic,readonly) NSTextContainer *textContainer NS_AVAILABLE_IOS(7_0);
@property(nonatomic, assign) UIEdgeInsets textContainerInset NS_AVAILABLE_IOS(7_0);
@property(nonatomic,readonly) NSLayoutManager *layoutManager NS_AVAILABLE_IOS(7_0);
@property(nonatomic,readonly,retain) NSTextStorage *textStorage NS_AVAILABLE_IOS(7_0); 
@property(nonatomic, copy) NSDictionary *linkTextAttributes NS_AVAILABLE_IOS(7_0);
@property(nonatomic) UITextAutocapitalizationType autocapitalizationType; 
@property(nonatomic) UITextAutocorrectionType autocorrectionType;
@property(nonatomic) UITextSpellCheckingType spellCheckingType NS_AVAILABLE_IOS(5_0);
@property(nonatomic) UIKeyboardType keyboardType;
@property(nonatomic) UIKeyboardAppearance keyboardAppearance;
@property(nonatomic) UIReturnKeyType returnKeyType;
@property(nonatomic) BOOL enablesReturnKeyAutomatically;
@property(nonatomic,getter=isSecureTextEntry) BOOL secureTextEntry;

- (void)scrollRangeToVisible:(NSRange)range;
- (void)insertText:(NSString *)text;

@end




