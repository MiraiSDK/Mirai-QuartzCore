//
//  CALayer+Texture.m
//  GSQuartzCore
//
//  Created by Chen Yonghui on 3/28/14.
//  Copyright (c) 2014 Ivan Vučica. All rights reserved.
//

#import "CALayer+Texture.h"
#import <objc/objc.h>

@implementation CALayer (Texture)
static char *TextureKey = "textureKey";

- (CAGLTexture *)texture
{
   return objc_getAssociatedObject(self, TextureKey);
}

- (void)setTexture:(CAGLTexture *)texture
{
    objc_setAssociatedObject(self, TextureKey, texture, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
