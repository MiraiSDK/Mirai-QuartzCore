//
//  CATextureLoader.h
//  GSQuartzCore
//
//  Created by Chen Yonghui on 6/19/14.
//  Copyright (c) 2014 Ivan Vučica. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GLHelpers/CAGLTexture.h"
@interface CATextureLoader : NSObject
- (CAGLTexture *)textureForLayer:(CALayer *)layer;
@end
