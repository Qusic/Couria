// Heavily based on https://github.com/autresphere/ASMediaFocusManager

#import "CouriaImageViewerController.h"

@interface CouriaImageViewerView : UIScrollView

- (void)setImage:(UIImage *)image;

@end

@interface CouriaImageViewerController ()

@property(strong, nonatomic) CouriaImageViewerView* viewerView;

@end

@implementation CouriaImageViewerController

- (id)init
{
    self = [super init];
    if (self) {
        _viewerView = [[CouriaImageViewerView alloc]initWithFrame:[UIScreen mainScreen].bounds];
        [_viewerView addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(viewerViewTapped:)]];
    }
    return self;
}

- (void)viewImage:(UIImage *)image inView:(UIView *)view
{
    CGRect startFrame = view.frame, endFrame = startFrame;
    startFrame.origin.y += endFrame.size.height;
    [_viewerView setImage:image];
    [view addSubview:_viewerView];
    _viewerView.frame = startFrame;
    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationCurveEaseInOut animations:^{
        _viewerView.frame = endFrame;
    } completion:NULL];
}

- (void)viewerViewTapped:(UITapGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        CGRect startFrame = _viewerView.superview.frame, endFrame = startFrame;
        endFrame.origin.y += startFrame.size.height;
        _viewerView.frame = startFrame;
        [UIView animateWithDuration:0.4 animations:^{
            _viewerView.frame = endFrame;
        } completion:^(BOOL finished) {
            [_viewerView setImage:nil];
            [_viewerView removeFromSuperview];
        }];
    }
}

@end

@interface CouriaImageViewerView () <UIScrollViewDelegate>

@property(strong, nonatomic) UIImageView *imageView;

@property(assign) CGSize imageSize;
@property(assign) CGPoint pointToCenterAfterResize;
@property(assign) CGFloat scaleToRestoreAfterResize;

@end

@implementation CouriaImageViewerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bounces = YES;
        self.alwaysBounceVertical = YES;
        self.alwaysBounceHorizontal = YES;
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // center the zoom view as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.imageView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    self.imageView.frame = frameToCenter;
}

- (void)setFrame:(CGRect)frame
{
    BOOL sizeChanging = !CGSizeEqualToSize(frame.size, self.frame.size);
    
    if (sizeChanging) {
        [self prepareToResize];
    }
    
    [super setFrame:frame];
    
    if (sizeChanging) {
        [self recoverFromResizing];
    }
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    
}

#pragma mark - Configure scrollView to display new image

- (void)setImage:(UIImage *)image
{
    if(self.imageView == nil)
    {
        self.zoomScale = 1.0;
        
        // make a new UIImageView for the new image
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView = imageView;
        [self addSubview:self.imageView];
    }
    else
    {
        self.imageView.image = image;
    }
    
    [self configureForImageSize:image.size];
}

- (void)configureForImageSize:(CGSize)imageSize
{
    _imageSize = imageSize;
    self.contentSize = imageSize;
    [self setMaxMinZoomScalesForCurrentBounds];
    self.zoomScale = self.minimumZoomScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds
{
    CGSize boundsSize = self.bounds.size;
    CGFloat maxScale = 1;
    
    // calculate min/max zoomscale
    CGFloat xScale = boundsSize.width  / _imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / _imageSize.height;   // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                   // use minimum of these to allow the image to become fully visible
    
    // Image must fit the screen, even if its size is smaller.
    CGFloat xImageScale = maxScale*_imageSize.width / boundsSize.width;
    CGFloat yImageScale = maxScale*_imageSize.height / boundsSize.width;
    CGFloat maxImageScale = MAX(xImageScale, yImageScale);
    
    maxImageScale = MAX(minScale, maxImageScale);
    maxScale = MIN(maxScale, maxImageScale);
    
    // don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)
    if (minScale > maxScale) {
        minScale = maxScale;
    }
    
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
}

#pragma mark -
#pragma mark Methods called during rotation to preserve the zoomScale and the visible portion of the image

#pragma mark - Rotation support

- (void)prepareToResize
{
    CGPoint boundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    _pointToCenterAfterResize = [self convertPoint:boundsCenter toView:self.imageView];
    
    _scaleToRestoreAfterResize = self.zoomScale;
    
    // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
    // allowable scale when the scale is restored.
    if (_scaleToRestoreAfterResize <= self.minimumZoomScale + FLT_EPSILON)
        _scaleToRestoreAfterResize = 0;
}

- (void)recoverFromResizing
{
    [self setMaxMinZoomScalesForCurrentBounds];
    
    // Step 1: restore zoom scale, first making sure it is within the allowable range.
    CGFloat maxZoomScale = MAX(self.minimumZoomScale, _scaleToRestoreAfterResize);
    self.zoomScale = MIN(self.maximumZoomScale, maxZoomScale);
    
    // Step 2: restore center point, first making sure it is within the allowable range.
    
    // 2a: convert our desired center point back to our own coordinate space
    CGPoint boundsCenter = [self convertPoint:_pointToCenterAfterResize fromView:self.imageView];
    
    // 2b: calculate the content offset that would yield that center point
    CGPoint offset = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0,
                                 boundsCenter.y - self.bounds.size.height / 2.0);
    
    // 2c: restore offset, adjusted to be within the allowable range
    CGPoint maxOffset = [self maximumContentOffset];
    CGPoint minOffset = [self minimumContentOffset];
    
    CGFloat realMaxOffset = MIN(maxOffset.x, offset.x);
    offset.x = MAX(minOffset.x, realMaxOffset);
    
    realMaxOffset = MIN(maxOffset.y, offset.y);
    offset.y = MAX(minOffset.y, realMaxOffset);
    
    self.contentOffset = offset;
}

- (CGPoint)maximumContentOffset
{
    CGSize contentSize = self.contentSize;
    CGSize boundsSize = self.bounds.size;
    return CGPointMake(contentSize.width - boundsSize.width, contentSize.height - boundsSize.height);
}

- (CGPoint)minimumContentOffset
{
    return CGPointZero;
}

@end