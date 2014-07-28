//
//  CAMovieLayer.m
//  GSQuartzCore
//
//  Created by Chen Yonghui on 7/28/14.
//  Copyright (c) 2014 Ivan Vučica. All rights reserved.
//

#import "CAMovieLayer.h"
#import "CABackingStore.h"
#import "CAGLTexture.h"
#import "CAGLTextureAndroid.h"

@implementation CAMovieLayer
@synthesize updateCallback = _updateCallback;

- (void) display
{
    CGRect bounds = self.bounds;
    
    EAGLContext *ctx = [EAGLContext currentContext];
    BOOL customCtx = NO;
    if (!ctx) {
        NSLog(@"create custom texture");
        ctx = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:ctx];
        customCtx = YES;
    }
    
    if (!_backingStore ||
        [_backingStore width] != bounds.size.width ||
        [_backingStore height] != bounds.size.height)
    {
        //TODO: taking account the opaque property, should create a bitmap without alpha channel while opaque is YES.
        [self setBackingStore: [CABackingStore backingStoreWithWidth: bounds.size.width height: bounds.size.height]];
        [self setContents:nil];
    }
    //  FIXME: texture target incorrect, should subclass
    [_backingStore setContentsTexture:[CAGLTextureAndroid texture]];
    
    self.contents = _backingStore;
    
    if (customCtx) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (int)textureID
{
    return [_backingStore contentsTexture].textureID;
}

- (BOOL)updateTextureIfNeeds:(CATransform3D *)t;
{
    BOOL success = NO;
    if (self.updateCallback) {
        success = self.updateCallback(t);
    }
    
    return success;
}

@end
