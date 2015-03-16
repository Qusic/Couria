#import "Headers.h"

@implementation CouriaConversationViewController

- (instancetype)initWithConversation:(CKConversation *)conversation rightBalloonMaxWidth:(CGFloat)rightBalloonMaxWidth leftBalloonMaxWidth:(CGFloat)leftBalloonMaxWidth
{
    self = [super initWithConversation:conversation rightBalloonMaxWidth:rightBalloonMaxWidth leftBalloonMaxWidth:leftBalloonMaxWidth];
    if (self) {
        self.view.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.conversation) {
        return [super collectionView:collectionView numberOfItemsInSection:section];
    } else {
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
                textBalloonView.attributedText = text;
            }
        }
        [balloonView setNeedsPrepareForDisplay];
        [balloonView prepareForDisplayIfNeeded];
    }
    return cell;
}

- (void)setChatItems:(NSArray *)chatItems
{
    [super setChatItems:chatItems];
}

@end
