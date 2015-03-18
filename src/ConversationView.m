#import "Headers.h"

@implementation CouriaConversationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.conversation) {
        return [super collectionView:collectionView numberOfItemsInSection:section];
    } else {
        //TODO: third party apps
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CKTranscriptCell *cell;
    if (self.conversation) {
        cell = (CKTranscriptCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    } else {
        //TODO: third party apps
    }
    if ([cell isKindOfClass:CKTranscriptBalloonCell.class]) {
        CKBalloonView *balloonView = ((CKTranscriptBalloonCell *)cell).balloonView;
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
