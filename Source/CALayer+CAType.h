//
//  CALayer+CAType.h
//  GSQuartzCore
//
//  Created by TaoZeyu on 15/12/25.
//  Copyright © 2015年 Ivan Vučica. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CALayer.h"

@interface CALayer (CAType)

- (BOOL) isRootLayer;
- (BOOL) isPresentationLayer;
- (BOOL) isRenderLayer;
- (BOOL) isModelLayer;

@end
