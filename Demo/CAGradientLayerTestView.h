//
//  CAGradientLayerTestView.h
//  QuartzCoreDemo
//
//  Created by pei hao on 13-12-20.
//  Copyright (c) 2013年 Free Software Foundation. All rights reserved.
//

#import <AppKit/NSOpenGLView.h>

#if !(GSIMPL_UNDER_COCOA)
#else
#import <GSQuartzCore/AppleSupport.h>
#endif

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import "LayerTestView.h"


@interface CAGradientLayerTestView : LayerTestView {
    
}
@end
