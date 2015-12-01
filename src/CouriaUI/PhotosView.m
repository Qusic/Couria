#import "../Headers.h"

CHDeclareClass(CKPhotoPickerSheetViewController)
CHDeclareClass(CKPhotoPickerCollectionViewController)

@interface CouriaPhotosViewController ()
@property (retain, nonatomic) UIViewController *viewController;
@end

@implementation CouriaPhotosViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initController];
    }
    return self;
}

- (BOOL)accessGranted {
    return [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized;
}

- (void)requestAccess {
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined) {
        if (PHPhotoLibrary.class) {
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                dispatch_semaphore_signal(semaphore);
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
    }
}

- (void)initController {
    [self requestAccess];
    if (self.accessGranted || [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined) {
        if (CHClass(CKPhotoPickerSheetViewController)) {
            self.viewController = [CHAlloc(CKPhotoPickerSheetViewController) initWithPresentationViewController:nil];
        } else if (CHClass(CKPhotoPickerCollectionViewController)) {
            self.viewController = [CHAlloc(CKPhotoPickerCollectionViewController) initWithNibName:nil bundle:nil];
        }
    } else {
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectZero];
        label.text = CouriaLocalizedString(@"NO_ACCESS_TO_PHOTOS");
        label.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        label.textColor = [[UIColor whiteColor]colorWithAlphaComponent:0.3];
        label.textAlignment = NSTextAlignmentCenter;
        UIViewController *viewController = [[UIViewController alloc]initWithNibName:nil bundle:nil];
        viewController.view = label;
        self.viewController = viewController;
    }
}

- (CKPhotoPickerSheetViewController *)sheetViewController { // iOS 8.0+
    return [self.viewController isKindOfClass:CHClass(CKPhotoPickerSheetViewController)] ? (CKPhotoPickerSheetViewController *)self.viewController : nil;
}

- (CKPhotoPickerCollectionViewController *)collectionViewController { // iOS 8.3+
    return [self.viewController isKindOfClass:CHClass(CKPhotoPickerCollectionViewController)] ? (CKPhotoPickerCollectionViewController *)self.viewController : nil;
}

- (UIView *)view {
    if (self.sheetViewController) {
        return self.sheetViewController.photosCollectionView;
    } else if (self.collectionViewController) {
        return self.collectionViewController.collectionView;
    } else {
        return self.viewController.view;
    }
}

- (NSArray *)fetchAndClearSelectedPhotos {
    NSMutableArray *photos = [NSMutableArray array];
    if (self.sheetViewController) {
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
    } else if (self.collectionViewController) {
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
    }
    return photos;
}

@end

CHOptimizedMethod(1, self, void, CKPhotoPickerSheetViewController, setPhotosCollectionView, CKPhotoPickerCollectionView *, photosCollectionView) {
    if (photosCollectionView != nil) {
        photosCollectionView.backgroundColor = [UIColor clearColor];
        CHSuper(1, CKPhotoPickerSheetViewController, setPhotosCollectionView, photosCollectionView);
    }
}

CHOptimizedMethod(1, self, void, CKPhotoPickerCollectionViewController, setCollectionView, UICollectionView *, collectionView) {
    if (collectionView != nil) {
        collectionView.backgroundColor = [UIColor clearColor];
        CHSuper(1, CKPhotoPickerCollectionViewController, setCollectionView, collectionView);
    }
}

void CouriaUIPhotosViewInit(void) {
    CHLoadLateClass(CKPhotoPickerSheetViewController);
    CHLoadLateClass(CKPhotoPickerCollectionViewController);
    CHHook(1, CKPhotoPickerSheetViewController, setPhotosCollectionView);
    CHHook(1, CKPhotoPickerCollectionViewController, setCollectionView);
}
