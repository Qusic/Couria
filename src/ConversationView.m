#import "Headers.h"

@implementation CouriaConversationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CKTranscriptCell *cell = (CKTranscriptCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:CKTranscriptMessageCell.class]) {
        CKTranscriptMessageCell *messageCell = (CKTranscriptMessageCell *)cell;
        if (self.conversation == nil) {
            messageCell.wantsContactImageLayout = NO;
            messageCell.contactImage = nil;
        }
        if ([messageCell isKindOfClass:CKTranscriptBalloonCell.class]) {
            CKTranscriptBalloonCell *balloonCell = (CKTranscriptBalloonCell *)cell;
            CKBalloonView *balloonView = balloonCell.balloonView;
            balloonView.canUseOpaqueMask = NO;
            balloonView.filled = NO;
            if ([balloonView isKindOfClass:CKColoredBalloonView.class]) {
                CKColoredBalloonView *coloredBalloonView = (CKColoredBalloonView *)balloonView;
                coloredBalloonView.color = CKBalloonColorWhite;
                if ([balloonView isKindOfClass:CKTextBalloonView.class]) {
                    CKTextBalloonView *textBalloonView = (CKTextBalloonView *)coloredBalloonView;
                    NSMutableAttributedString *text = textBalloonView.attributedText.mutableCopy;
                    [text addAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} range:NSMakeRange(0, text.length)];
                    [text removeAttribute:NSLinkAttributeName range:NSMakeRange(0, text.length)];
                    textBalloonView.attributedText = text;
                }
            }
            [balloonView setNeedsPrepareForDisplay];
            [balloonView prepareForDisplayIfNeeded];
        }
    }
    return cell;
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
