//
//  CALayer+CARender.m
//  GSQuartzCore
//
//  Created by TaoZeyu on 15/12/17.
//  Copyright © 2015年 Ivan Vučica. All rights reserved.
//

#import "CALayer+CARender.h"
#import "CARenderer.h"

#import <Foundation/Foundation.h>
#import "QuartzCore/CARenderer.h"
#import "QuartzCore/CATransform3D.h"
#import "QuartzCore/CATransform3D_Private.h"
#import "QuartzCore/CALayer.h"
#import "CALayer.h"
#import "CALayer+FrameworkPrivate.h"
#import "CATransaction+FrameworkPrivate.h"
#import "CABackingStore.h"
#import "CAMovieLayer.h"
#import "CALayer+Texture.h"
#import "CALayer+CARender.h"

#import "CATextureLoader.h"

#if GNUSTEP
#import <CoreGraphics/CoreGraphics.h>
#endif

@implementation CALayer (CARender)

- (void)setNeedsRefreshCombineBuffer
{
    _needsRefreshCombineBuffer = YES;
}

- (void)refreshCombineBufferIfNeed
{
    if (_needsRefreshCombineBuffer && self.mask) {
        [self.mask refreshCombineBufferIfNeed];
        [self _refreshCombineBuffer];
        _needsRefreshCombineBuffer = NO;
    }
}

- (CAGLTexture *)combinedTexture
{
    return [_combinedBackingStore contentsTexture];
}

- (void)_refreshCombineBuffer
{
    NSLog(@"refresh...");
    [self _resizeCombineBackingStoreSize];
    
    if ([_combinedBackingStore context]) {
        CGContextSaveGState ([_combinedBackingStore context]);
        CGContextScaleCTM([_combinedBackingStore context], self.contentsScale, self.contentsScale);
        CGContextClipToRect ([_combinedBackingStore context], [self bounds]);
        [self _drawSelfAppearanceToCombinedContext];
        [self _combineWithMask];
        CGContextRestoreGState ([_combinedBackingStore context]);
    } else {
        NSLog(@"[WARNING] EMPTY backing store context");
    }
    [_combinedBackingStore refresh];
}

- (void)_resizeCombineBackingStoreSize
{
    if (!_combinedBackingStore ||
        [_combinedBackingStore width] != self.bounds.size.width ||
        [_combinedBackingStore height] != self.bounds.size.height)
    {
        [self _resetCombinedBackingStore:[CABackingStore backingStoreWithWidth: self.bounds.size.width
                                                                        height: self.bounds.size.height]];
    }
}

- (void)_resetCombinedBackingStore:(CABackingStore *)backingStore
{
    [_combinedBackingStore release];
    _combinedBackingStore = [backingStore retain];
}

- (void)_drawSelfAppearanceToCombinedContext
{
    id layerContents = [self contents];
#if GNUSTEP
    if ([layerContents isKindOfClass: NSClassFromString(@"CGImage")])
#else
    if ([layerContents isKindOfClass: NSClassFromString(@"__NSCFType")] &&
        CFGetTypeID(layerContents) == CGImageGetTypeID())
#endif
    {
        [self _drawImageToCombinedContext:(CGImageRef)layerContents];
    }
}

- (void)_drawImageToCombinedContext:(CGImageRef)image
{
    CGFloat width = CGImageGetWidth(image);
    CGFloat height = CGImageGetHeight(image);
    CGContextDrawImage([_combinedBackingStore context], CGRectMake(0, 0, width, height), image);
}

- (void)_combineWithMask
{
    int width = [_combinedBackingStore width];
    int height = [_combinedBackingStore height];
    UInt32 *imageData = CGBitmapContextGetData([_combinedBackingStore context]);
    
    if (imageData == NULL) {
        return;
    }
    for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
            int index = x*height + y;
            imageData[index] &= 0xff00ffff;
        }
    }
}

@end
