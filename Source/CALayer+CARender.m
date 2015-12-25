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

- (CAGLTexture *)combinedTexture
{
    if ([_backingStore needsRefresh]) {
        [_backingStore refresh];
    }
    return [_backingStore contentsTexture];
}

- (void)displayAccordingToSpecialCondition
{
    if ([_delegate respondsToSelector: @selector(displayLayer:)]) {
        [_delegate displayLayer: self];
        if ([self _shouldDrawToBackingStore]) {
            [self _drawImageToBackingStoreIfNeed];
        }
    } else {
        [self _drawByCustomToBackingStoreIfNeed];
    }
}

- (BOOL)_shouldDrawToBackingStore
{
    return self.mask || _layersMaskedByMe.count > 0;
}

- (void)_drawImageToBackingStoreIfNeed
{
    id layerContents = [self contents];
#if GNUSTEP
    if ([layerContents isKindOfClass: NSClassFromString(@"CGImage")])
#else
    if ([layerContents isKindOfClass: NSClassFromString(@"__NSCFType")] &&
        CFGetTypeID(layerContents) == CGImageGetTypeID())
#endif
    {
        [self _resizeBackingStoreSize];
        
        if ([_backingStore context]) {
            CGImageRef image = (CGImageRef)layerContents;
            CGFloat width = CGImageGetWidth(image);
            CGFloat height = CGImageGetHeight(image);
            CGContextSaveGState ([_backingStore context]);
            CGContextScaleCTM([_backingStore context], self.contentsScale, self.contentsScale);
            CGContextClipToRect ([_backingStore context], [self bounds]);
            CGContextDrawImage([_backingStore context], CGRectMake(0, 0, width, height), image);
            [self _combineWithMask];
            CGContextRestoreGState ([_backingStore context]);
        } else {
            NSLog(@"[WARNING] EMPTY backing store context");
        }
        [self.backingStore setNeedRefresh];
    }
}

- (void)_drawByCustomToBackingStoreIfNeed
{
    /* By default, uses -drawInContext: to update the 'contents' property. */
    CGRect bounds = [self bounds];
    if (CGRectIsEmpty(bounds)) {
        return;
    }
    
    if (!_backingStore ||
        [_backingStore width] != bounds.size.width ||
        [_backingStore height] != bounds.size.height)
    {
        //TODO: taking account the opaque property, should create a bitmap without alpha channel while opaque is YES.
        CGFloat backingWidth = bounds.size.width * self.contentsScale;
        CGFloat backingHeight = bounds.size.height * self.contentsScale;
        [self setBackingStore: [CABackingStore backingStoreWithWidth: backingWidth height: backingHeight]];
        [self setContents:nil];
    }
    
    if ([_backingStore context]) {
        CGContextSaveGState ([_backingStore context]);
        CGContextScaleCTM([_backingStore context], self.contentsScale, self.contentsScale);
        CGContextClipToRect ([_backingStore context], [self bounds]);
        [self drawInContext: [_backingStore context]];
        [self _combineWithMask];
        CGContextRestoreGState ([_backingStore context]);
    } else {
        NSLog(@"[WARNING] EMPTY backing store context");
    }
    
    /* Call -refresh on backing store to fill its texture */
    if (![self contents])
        [self setContents: [self backingStore]];
    
    [self.backingStore setNeedRefresh];
}

- (void)_resizeBackingStoreSize
{
    if (!_backingStore ||
        [_backingStore width] != self.bounds.size.width ||
        [_backingStore height] != self.bounds.size.height)
    {
        [self setBackingStore:[CABackingStore backingStoreWithWidth: self.bounds.size.width
                                                             height: self.bounds.size.height]];
    }
}

- (void)_combineWithMask
{
    if (self.mask == nil) {
        return;
    }
    CABackingStore *maskBackingStore = self.mask->_backingStore;
    UInt32 *selfImageData = CGBitmapContextGetData([_backingStore context]);
    UInt32 *maskImageData = CGBitmapContextGetData([maskBackingStore context]);
    
    NSLog(@"selfImageData %i, maskImageData %i", selfImageData == NULL, maskImageData == NULL);
    if (selfImageData == NULL || maskImageData == NULL) {
        return;
    }
    NSLog(@"------3");
    
    int maskWidth = [maskBackingStore width];
    int maskHeight = [maskBackingStore height];
    int selfWidth = [_backingStore width];
    int selfHeight = [_backingStore height];
    int dx = self.mask.frame.origin.x;
    int dy = self.mask.frame.origin.y;
    
    int squeezeWidth = MIN(selfWidth, dx + maskWidth) - dx;
    int squeezeHeight = MIN(selfHeight, dy + maskHeight) - dy;
    
    if (squeezeWidth <= 0 || squeezeHeight <= 0) {
        return;
    }
    NSLog(@"------4");
    
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
    NSLog(@"------5");
}

@end
