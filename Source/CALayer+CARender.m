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
    if (self.mask) {
        [self _refreshCOmbineBufferIfHasSetNeed];
    }
}

- (CAGLTexture *)combinedTexture
{
    return [_combinedBackingStore contentsTexture];
}

- (void)_refreshCOmbineBufferIfHasSetNeed
{
    if (_needsRefreshCombineBuffer) {
        [self.mask _refreshCOmbineBufferIfHasSetNeed];
        [self _refreshCombineBuffer];
        _needsRefreshCombineBuffer = NO;
    }
}

- (void)_refreshCombineBuffer
{
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
    if (!self.mask) {
        return;
    }
    CABackingStore *maskCombinedBackingStore = self.mask->_combinedBackingStore;
    UInt32 *selfImageData = CGBitmapContextGetData([_combinedBackingStore context]);
    UInt32 *maskImageData = CGBitmapContextGetData([maskCombinedBackingStore context]);
    
    if (selfImageData == NULL || maskImageData == NULL) {
        return;
    }
    
    int maskWidth = [maskCombinedBackingStore width];
    int maskHeight = [maskCombinedBackingStore height];
    int selfWidth = [_combinedBackingStore width];
    int selfHeight = [_combinedBackingStore height];
    int dx = self.mask.frame.origin.x;
    int dy = self.mask.frame.origin.y;
    
    int squeezeWidth = MIN(selfWidth, dx + maskWidth) - dx;
    int squeezeHeight = MIN(selfHeight, dy + maskHeight) - dy;
    
    if (squeezeWidth <= 0 || squeezeHeight <= 0) {
        return;
    }
    
    for (int x = 0; x < selfWidth; x++) {
        for (int y = 0; y < selfHeight; y++) {
            if (x < dx | x >= dx + squeezeWidth | y < dy | y >= dy + squeezeHeight) {
                selfImageData[y*selfWidth + x] &= 0x00ffffff;
            } else {
                UInt32 *selfPixel = &selfImageData[y*selfWidth + x];
                UInt32 *maskPixel = &maskImageData[(y - dy)*maskWidth + x - dx];
                *selfPixel = (*selfPixel | 0xff000000) & (*maskPixel | 0x00ffffff);
            }
        }
    }
}

@end
