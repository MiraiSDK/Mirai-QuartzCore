//
//  CAGLExternalTexture.m
//  GSQuartzCore
//
//  Created by Chen Yonghui on 7/27/14.
//  Copyright (c) 2014 Ivan Vučica. All rights reserved.
//

#import "CAGLExternalTexture.h"

#define GL_TEXTURE_EXTERNAL_OES 0x8D65

@implementation CAGLExternalTexture
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self bind];
        glTexParameterf(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        [self unbind];
    }
    return self;
}
- (void) bind
{
    glBindTexture(GL_TEXTURE_EXTERNAL_OES, _textureID);
}

- (void) unbind
{
    glBindTexture(GL_TEXTURE_EXTERNAL_OES, 0);
}

- (GLenum) textureTarget
{
    return GL_TEXTURE_EXTERNAL_OES;
}

@end
