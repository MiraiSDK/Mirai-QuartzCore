//
//  CATextureLoader.m
//  GSQuartzCore
//
//  Created by Chen Yonghui on 6/19/14.
//  Copyright (c) 2014 Ivan Vučica. All rights reserved.
//

#import "CATextureLoader.h"
#import "CALayer+FrameworkPrivate.h"

@interface CATextureLoader ()
@property (nonatomic, strong) NSMutableDictionary *cachedTexture;
@end

@implementation CATextureLoader
@synthesize cachedTexture = _cachedTexture;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _cachedTexture = [[NSMutableDictionary alloc] init];
    }
    return self;
}
- (CAGLTexture *)cachedTextureForLayer:(CALayer *)layer
{
    CALayer *modelLayer = [layer modelLayer];
    CAGLTexture *texture = modelLayer.texture;
    
    if (texture) {
        if (texture.contents != layer.contents ||
            texture.isInvalidated) {
            layer.texture = nil;
            texture = nil;
        }
    }
    return texture;
}

- (void)cacheTexture:(CAGLTexture *)texture forLayer:(CALayer *)layer
{
    CALayer *modelLayer = [layer modelLayer];
    modelLayer.texture = texture;
}

- (CAGLTexture *)textureForLayer:(CALayer *)layer
{
    CAGLTexture *texture = [self cachedTextureForLayer:layer];
    
    if (texture == nil) {
        texture = [CAGLTexture texture];
        [self cacheTexture:texture forLayer:layer];
    }
    return texture;
}
@end
