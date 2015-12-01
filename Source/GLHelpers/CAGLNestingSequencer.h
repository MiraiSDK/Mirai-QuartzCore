//
//  CAGLNestingSequencer.h
//  GSQuartzCore
//
//  Created by TaoZeyu on 15/11/30.
//  Copyright © 2015年 Ivan Vučica. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CAGLNestingSequencer : NSObject

- (instancetype)invokeTarget:(id)target method:(SEL)method;

@end
