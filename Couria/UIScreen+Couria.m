//
//  UIScreen+Couria.m
//  Couria
//
//  Created by Qusic on 8/15/13.
//  Copyright (c) 2013 Qusic. All rights reserved.
//

#import "UIScreen+Couria.h"

@implementation UIScreen (Couria)

- (UIInterfaceOrientation)frontMostAppOrientation
{
    UIInterfaceOrientation orientation = ((SpringBoard *)[NSClassFromString(@"SpringBoard")sharedApplication])._frontMostAppOrientation;
    return orientation;
}

- (CGRect)viewFrame
{
    UIInterfaceOrientation orientation = self.frontMostAppOrientation;
    CGSize screenSize = self.bounds.size;
    CGSize viewSize = UIInterfaceOrientationIsPortrait(orientation) ? screenSize : CGSizeMake(screenSize.height, screenSize.width);
    CGRect viewFrame = {CGPointZero, viewSize};
    return viewFrame;
}

@end
