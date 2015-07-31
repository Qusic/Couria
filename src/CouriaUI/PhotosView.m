#import "../Headers.h"

static NSInteger version;

CHDeclareClass(CKPhotoPickerSheetViewController)
CHDeclareClass(CKPhotoPickerCollectionViewController)

@interface CouriaPhotosViewController ()
@property (retain, nonatomic) CKPhotoPickerSheetViewController *sheetViewController; // iOS 8.0+
@property (retain, nonatomic) CKPhotoPickerCollectionViewController *collectionViewController; // iOS 8.3+
@end

@implementation CouriaPhotosViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        switch (version) {
            case 1:
                self.sheetViewController = [CHAlloc(CKPhotoPickerSheetViewController) initWithPresentationViewController:nil];
                break;
            case 2:
                self.collectionViewController = [CHAlloc(CKPhotoPickerCollectionViewController) initWithNibName:nil bundle:nil];
                break;
        }
    }
    return self;
}

- (UIViewController *)viewController
{
    UIViewController *viewController = nil;
    switch (version) {
        case 1:
            viewController = self.sheetViewController;
            break;
        case 2:
            viewController = self.collectionViewController;
            break;
    }
    return viewController;
}

- (UIView *)view
{
    UIView *view = nil;
    switch (version) {
        case 1:
            view = self.sheetViewController.photosCollectionView;
            break;
        case 2:
            view = self.collectionViewController.collectionView;
            break;
    }
    return view;
}

- (NSArray *)fetchAndClearSelectedPhotos
{
    NSMutableArray *photos = [NSMutableArray array];
    switch (version) {
        case 1: {
            CKPhotoPickerSheetViewController *viewController = self.sheetViewController;
            CKPhotoPickerCollectionView *view = viewController.photosCollectionView;
            NSArray *assets = CHIvar(viewController, _assets, NSArray * const);
            [view.indexPathsForSelectedItems enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger index, BOOL *stop) {
                ALAsset *asset = assets[indexPath.item];
                ALAssetRepresentation *representation = asset.defaultRepresentation;
                NSDictionary *transcoderUserInfo = nil;
                if (representation.url != nil) {
                    transcoderUserInfo = @{IMFileTransferAVTranscodeOptionAssetURI: representation.url.absoluteString};
                }
                CKMediaObject *mediaObject = [[CKMediaObjectManager sharedInstance]mediaObjectWithData:UIImageJPEGRepresentation([UIImage imageWithCGImage:representation.fullResolutionImage scale:1 orientation:(UIImageOrientation)representation.orientation], 0.8) UTIType:(__bridge NSString *)kUTTypeJPEG filename:nil transcoderUserInfo:transcoderUserInfo];
                [photos addObject:mediaObject];
                [view deselectItemAtIndexPath:indexPath animated:NO];
                [view.delegate collectionView:view didDeselectItemAtIndexPath:indexPath];
            }];
            break;
        }
        case 2: {
            CKPhotoPickerCollectionViewController *viewController = self.collectionViewController;
            UICollectionView *view = self.collectionViewController.collectionView;
            NSArray *items = viewController.assetsToSend;
            [items enumerateObjectsUsingBlock:^(CKPhotoPickerItemForSending *item, NSUInteger index, BOOL *stop) {
                [item waitForOutstandingWork];
                NSURL *assetURL = item.assetURL;
                NSURL *localURL = item.localURL;
                NSURL *fileURL = nil;
                NSDictionary *transcoderUserInfo = nil;
                if (PUTIsPersistentURL(assetURL)) {
                    fileURL = [NSURL fileURLWithPath:PUTCreatePathForPersistentURL(assetURL) isDirectory:NO];
                    transcoderUserInfo = @{IMFileTransferAVTranscodeOptionAssetURI: assetURL.absoluteString};
                } else if (localURL.isFileURL) {
                    fileURL = localURL;
                }
                if (fileURL != nil) {
                    CKMediaObject *mediaObject = [[CKMediaObjectManager sharedInstance]mediaObjectWithFileURL:fileURL filename:nil transcoderUserInfo:transcoderUserInfo];
                    [photos addObject:mediaObject];
                }
            }];
            [view.indexPathsForSelectedItems enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger index, BOOL *stop) {
                [view deselectItemAtIndexPath:indexPath animated:NO];
                [view.delegate collectionView:view didDeselectItemAtIndexPath:indexPath];
            }];
            break;
        }
    }
    return photos;
}

@end

CHOptimizedMethod(1, self, void, CKPhotoPickerSheetViewController, setPhotosCollectionView, CKPhotoPickerCollectionView *, photosCollectionView)
{
    if (photosCollectionView != nil) {
        photosCollectionView.backgroundColor = [UIColor clearColor];
        CHSuper(1, CKPhotoPickerSheetViewController, setPhotosCollectionView, photosCollectionView);
    }
}

CHOptimizedMethod(1, self, void, CKPhotoPickerCollectionViewController, setCollectionView, UICollectionView *, collectionView)
{
    if (collectionView != nil) {
        collectionView.backgroundColor = [UIColor clearColor];
        CHSuper(1, CKPhotoPickerCollectionViewController, setCollectionView, collectionView);
    }
}

void CouriaUIPhotosViewInit(void)
{
    CHLoadLateClass(CKPhotoPickerSheetViewController);
    CHLoadLateClass(CKPhotoPickerCollectionViewController);
    if (CHClass(CKPhotoPickerSheetViewController)) {
        version = 1;
        CHHook(1, CKPhotoPickerSheetViewController, setPhotosCollectionView);
    }
    if (CHClass(CKPhotoPickerCollectionViewController)) {
        version = 2;
        CHHook(1, CKPhotoPickerCollectionViewController, setCollectionView);
    }
}
