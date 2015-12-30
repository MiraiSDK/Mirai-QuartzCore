//
//  CALayer+CARender.h
//  GSQuartzCore
//
//  Created by TaoZeyu on 15/12/17.
//  Copyright © 2015年 Ivan Vučica. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALayer.h"
#import "CAGLTexture.h"

@interface CALayer (CARender)

- (void)displayAccordingToSpecialCondition;
- (CAGLTexture *)combinedTexture;
- (void)prepareContentsBeforeDisplay;

@end
