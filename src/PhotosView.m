#include "Headers.h"

@implementation CouriaPhotosViewController

- (void)setPhotosCollectionView:(CKPhotoPickerCollectionView *)photosCollectionView
{
    if (photosCollectionView != nil) {
        photosCollectionView.backgroundColor = [UIColor clearColor];
        [super setPhotosCollectionView:photosCollectionView];
    }
}

- (NSArray *)fetchAndClearSelectedAssets
{
    NSArray *allAssets = CHIvar(self, _assets, NSArray * const);
    NSMutableArray *selectedAssets = [NSMutableArray array];
    [self.photosCollectionView.indexPathsForSelectedItems enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger index, BOOL *stop) {
        [selectedAssets addObject:allAssets[indexPath.item]];
        [self.photosCollectionView deselectItemAtIndexPath:indexPath animated:NO];
        [self.photosCollectionView.delegate collectionView:self.photosCollectionView didDeselectItemAtIndexPath:indexPath];
    }];
    return selectedAssets;
}

@end
