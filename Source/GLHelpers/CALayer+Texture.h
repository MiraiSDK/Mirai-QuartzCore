//
//  CALayer+Texture.h
//  GSQuartzCore
//
//  Created by Chen Yonghui on 3/28/14.
//  Copyright (c) 2014 Ivan Vučica. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "CAGLTexture.h"

@interface CALayer (Texture)
@property (nonatomic, strong) CAGLTexture *texture;
@end
