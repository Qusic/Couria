#import "../Headers.h"

@implementation CouriaConversationViewController

- (void)configureCell:(CKTranscriptCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [super configureCell:cell forItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:CKTranscriptMessageCell.class]) {
        CKTranscriptMessageCell *messageCell = (CKTranscriptMessageCell *)cell;
        if (self.conversation == nil) {
            messageCell.wantsContactImageLayout = NO;
            messageCell.contactImage = nil;
        }
        if ([messageCell isKindOfClass:CKTranscriptBalloonCell.class]) {
            CKTranscriptBalloonCell *balloonCell = (CKTranscriptBalloonCell *)cell;
            CKBalloonView *balloonView = balloonCell.balloonView;
            balloonView.filled = self.bubbleTheme != CouriaBubbleThemeOutline;
            if ([balloonView isKindOfClass:CKColoredBalloonView.class]) {
                CKColoredBalloonView *coloredBalloonView = (CKColoredBalloonView *)balloonView;
                CKBalloonColor originalColor = ((CKMessagePartChatItem *)self.chatItems[indexPath.item]).color;
                CKUIBehavior *uiBehavior = [CKUIBehavior sharedBehaviors];
                switch (self.bubbleTheme) {
                    case CouriaBubbleThemeOutline:
                        coloredBalloonView.color = CKBalloonColorWhite;
                        break;
                    case CouriaBubbleThemeCustom:
                        coloredBalloonView.color = [uiBehavior colorTypeForColor:coloredBalloonView.orientation == CKBalloonOrientationRight ? self.bubbleColors[0] : self.bubbleColors[2]];
                        break;
                    default:
                        coloredBalloonView.color = originalColor;
                        break;
                }
                if ([balloonView isKindOfClass:CKTextBalloonView.class]) {
                    CKTextBalloonView *textBalloonView = (CKTextBalloonView *)coloredBalloonView;
                    NSMutableAttributedString *text = textBalloonView.attributedText.mutableCopy;
                    switch (self.bubbleTheme) {
                        case CouriaBubbleThemeOutline:
                            [text addAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} range:NSMakeRange(0, text.length)];
                            break;
                        case CouriaBubbleThemeCustom:
                            [text addAttributes:@{NSForegroundColorAttributeName: coloredBalloonView.orientation == CKBalloonOrientationRight ? self.bubbleColors[1] : self.bubbleColors[3]} range:NSMakeRange(0, text.length)];
                            break;
                        default:
                            [text addAttributes:@{NSForegroundColorAttributeName: [uiBehavior balloonTextColorForColorType:originalColor]} range:NSMakeRange(0, text.length)];
                            break;
                    }
                    [text removeAttribute:NSLinkAttributeName range:NSMakeRange(0, text.length)];
                    textBalloonView.attributedText = text;
                }
            }
            [balloonView setNeedsPrepareForDisplay];
            [balloonView prepareForDisplayIfNeeded];
        }
    }
}

- (void)refreshData
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
    });
}

- (BOOL)balloonView:(CKBalloonView *)balloonView canPerformAction:(SEL)action withSender:(id)sender
{
    return sel_isEqual(action, @selector(copy:)) ? [super balloonView:balloonView canPerformAction:action withSender:sender] : NO;
}

@end
