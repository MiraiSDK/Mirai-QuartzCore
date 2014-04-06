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
    
    CAGradientLayer * layer = [CAGradientLayer layer];
    [layer setBounds: CGRectMake(0, 0, 200, 200)];
    CGColorRef redColor = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1);
    CGColorRef orangeColor = CGColorCreateGenericRGB(1.0, 0.5, 0.0, 1);
    CGColorRef yellowColor = CGColorCreateGenericRGB(1.0, 1.0, 0.0, 1);
    CGColorRef blueColor = CGColorCreateGenericRGB(0.0, 0.0, 1.0, 1);

    layer.colors = [NSArray arrayWithObjects:
                    (id)redColor,
                    (id)orangeColor,
                    (id)yellowColor,
                    (id)blueColor,
                    nil];
    layer.startPoint = CGPointMake(0, 0);
    layer.endPoint = CGPointMake(1, 1);

    [_rootLayer addSublayer: layer];
    [layer setNeedsDisplay];
}


@end
