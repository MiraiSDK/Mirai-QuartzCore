//
//  CAGradientLayerTestView.m
//  QuartzCoreDemo
//
//  Created by pei hao on 13-12-20.
//  Copyright (c) 2013年 Free Software Foundation. All rights reserved.
//

#import "CAGradientLayerTestView.h"
#import "CATextLayerTestView.h"

#if !(__APPLE__)
#import <GL/gl.h>
#import <GL/glu.h>
#else
#import <OpenGL/gl.h>
#endif
#import <CoreGraphics/CoreGraphics.h>

#if !(GSIMPL_UNDER_COCOA)
#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>
#else
#import <AppKit/NSOpenGL.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenu.h>
#import <GSQuartzCore/AppleSupport.h>
#import <GSQuartzCore/QuartzCore.h>
#import <GSQuartzCore/CATextLayer.h>
#import <GSQuartzCore/CAGradientLayer.h>

#endif


@implementation CAGradientLayerTestView

-(void) doTest {

    [self test1];
}

-(void)test1 {
    
    CAGradientLayer * backgroundLayer = [CAGradientLayer layer];
    [backgroundLayer setBounds: CGRectMake(0, 0, 200, 200)];
    [_rootLayer addSublayer: backgroundLayer];
    [backgroundLayer setNeedsDisplay];
}


@end
