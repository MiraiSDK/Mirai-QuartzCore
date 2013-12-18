/* Demo/DemoOpenGLView.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vucica <ivan@vucica.net>
   Date: August 2012

   This file is part of QuartzCore.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

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
#endif

#import "TextLayer.h"
#import "GradientLayer.h"


@implementation CATextLayerTestView

- (void) dealloc
{
  if (_isAnimating)
    [self stopAnimation];

  [super dealloc];
}

- (void) startAnimation
{
  if (!_timer)
    _timer = [NSTimer scheduledTimerWithTimeInterval: 1./60. 
                                              target: self 
                                            selector: @selector(timerAnimation:) 
                                            userInfo: nil 
                                             repeats: YES];
  _isAnimating = YES;

}

- (void) stopAnimation
{
  [_timer invalidate];
  _timer = nil;

  _isAnimating = NO;
}


- (void) prepareOpenGL
{
  [super prepareOpenGL];
  CGColorRef whiteColor = CGColorCreateGenericRGB(1, 1, 1, 1);
  CGColorRef yellowColor = CGColorCreateGenericRGB(1, 1, 0, 1);
  CGColorRef blackColor = CGColorCreateGenericRGB(0, 0, 0, 1);
  CGColorRef grayColor = CGColorCreateGenericRGB(0.4, 0.4, 0.4, 1);

  /* Create renderer */
#if GNUSTEP || GSIMPL_UNDER_COCOA
  _renderer = [CARenderer rendererWithNSOpenGLContext: [self openGLContext]
                                              options: nil];
#else
  _renderer = [CARenderer rendererWithCGLContext: [self openGLContext].CGLContextObj
                                         options: nil];
#endif
  [_renderer retain];
  [_renderer setBounds: NSRectToCGRect([self bounds])];

  /* Create root layer */
  {
    CALayer * layer = [CALayer layer];
    [_renderer setLayer: layer];
    [layer setBounds: NSRectToCGRect([self bounds])];
    [layer setBackgroundColor: whiteColor];  
    CGPoint midPos = CGPointMake([_renderer bounds].size.width/2,
                                 [_renderer bounds].size.height/2);
    [layer setPosition: midPos];

    /* Load a perspective transform */
    CATransform3D perspective = CATransform3DIdentity;
    perspective.m34 = 1.0 / -500.;
    [layer setSublayerTransform: perspective];

    _rootLayer = [layer retain];
  }
    
    
    [self testNSString];
    [self testAString];
    [self testCTFont];
    [self testCGFtont];
    //[self testWarpped];
    
  [self startAnimation];
  
  CGColorRelease(yellowColor);
  CGColorRelease(whiteColor);
  CGColorRelease(blackColor);
  CGColorRelease(grayColor);

  glViewport(0, 0, [self frame].size.width, [self frame].size.height);
  glClear(GL_COLOR_BUFFER_BIT);

}

-(void)testNSString {

    CGColorRef yellowColor = CGColorCreateGenericRGB(1, 1, 0, 1);
    CATextLayer* textLayerUsingNSString = [CATextLayer layer];
    [textLayerUsingNSString setBounds:CGRectMake(0.0, 0.0, 300.0, 85.0)];
    [textLayerUsingNSString setPosition:CGPointMake(160.0, 30)];
    [textLayerUsingNSString setForegroundColor: yellowColor];
    [textLayerUsingNSString setString: @"NSString"];
    [_rootLayer addSublayer:textLayerUsingNSString];
    [textLayerUsingNSString setNeedsDisplay];
}

-(void)testAString {
    
    CGColorRef yellowColor = CGColorCreateGenericRGB(1, 1, 0, 1);
    CATextLayer* textLayerUsingAString = [CATextLayer layer];
    [textLayerUsingAString setBounds:CGRectMake(0.0, 0.0, 300.0, 85.0)];
    [textLayerUsingAString setPosition:CGPointMake(160.0, 60)];
    [textLayerUsingAString setForegroundColor: yellowColor];
    CTFontRef font = CTFontCreateWithName((CFStringRef)@"Helvetica-Bold", 36, NULL);
    NSDictionary * attributesDict;
    attributesDict = [NSDictionary dictionaryWithObjectsAndKeys:
                      (id)font, (id)kCTFontAttributeName,
                      (id)yellowColor, (id)kCTForegroundColorAttributeName,
                      nil];
    NSAttributedString * aString;
    aString = [[NSAttributedString alloc] initWithString: @"AString"
                                              attributes: attributesDict];
    [textLayerUsingAString setString:aString];
    [_rootLayer addSublayer:textLayerUsingAString];
    [textLayerUsingAString setNeedsDisplay];
}

-(void)testCTFont {
    
    CGColorRef blackColor = CGColorCreateGenericRGB(0, 0, 0, 1);
    CATextLayer* textLayerUsingArial18 = [CATextLayer layer];
    [textLayerUsingArial18 setBounds:CGRectMake(0.0, 0.0, 300.0, 85.0)];
    [textLayerUsingArial18 setPosition:CGPointMake(160.0, 90)];
    [textLayerUsingArial18 setForegroundColor: blackColor];
    [textLayerUsingArial18 setString: @"ArialMT 18 CT"];
    CTFontRef fontArial = CTFontCreateWithName((CFStringRef)@"ArialMT", 18, NULL);
    [textLayerUsingArial18 setFont:fontArial];
    [_rootLayer addSublayer:textLayerUsingArial18];
    [textLayerUsingArial18 setNeedsDisplay];
}

-(void)testCGFtont {

    CGColorRef blackColor = CGColorCreateGenericRGB(0, 0, 0, 1);
    CATextLayer* textLayerUsingArial50AndCGFontRef = [CATextLayer layer];
    [textLayerUsingArial50AndCGFontRef setBounds:CGRectMake(0.0, 0.0, 300.0, 85.0)];
    [textLayerUsingArial50AndCGFontRef setPosition:CGPointMake(160.0, 120)];
    [textLayerUsingArial50AndCGFontRef setForegroundColor: blackColor];
    [textLayerUsingArial50AndCGFontRef setString: @"ArialMT 40 CG"];
    CGFontRef fontArialAndCGFontRef = CGFontCreateWithFontName((CFStringRef)@"ArialMT");
    [textLayerUsingArial50AndCGFontRef setFont:fontArialAndCGFontRef];
    [textLayerUsingArial50AndCGFontRef setFontSize:40.0];
    [_rootLayer addSublayer:textLayerUsingArial50AndCGFontRef];
    [textLayerUsingArial50AndCGFontRef setNeedsDisplay];
}

-(void)testWarpped {
    
    CGColorRef blackColor = CGColorCreateGenericRGB(0, 0, 0, 1);
    CATextLayer* layer = [CATextLayer layer];
    [layer setBounds:CGRectMake(0.0, 0.0, 300.0, 300.0)];
    [layer setPosition:CGPointMake(160.0, 150)];
    [layer setForegroundColor: blackColor];
    [layer setString: @"When true the string is wrapped to fit within the layer bounds. Defaults to NO."];
    [layer setWrapped:YES];
    CGFontRef fontArialAndCGFontRef = CGFontCreateWithFontName((CFStringRef)@"ArialMT");
    [layer setFont:fontArialAndCGFontRef];
    [layer setFontSize:18];
    [_rootLayer addSublayer:layer];
    [layer setNeedsDisplay];
}

- (void) timerAnimation: (NSTimer *)timer
{
  [[self openGLContext] makeCurrentContext];

  glViewport(0, 0, [self frame].size.width, [self frame].size.height);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrtho(0, [self frame].size.width, 0, [self frame].size.height, -2500, 2500);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  /* */
  [_renderer beginFrameAtTime: CACurrentMediaTime()
                    timeStamp: NULL];
  [self clearBounds: [_renderer updateBounds]];
  [_renderer render];
  [_renderer endFrame];
  /* */

  glFlush();

  [[self openGLContext] flushBuffer];
}

- (void)clearBounds:(CGRect)bounds
{  
  glBegin(GL_QUADS);
  glColor4f(0,0,0,1);
  glVertex2f(bounds.origin.x, bounds.origin.y);
  glVertex2f(bounds.origin.x+bounds.size.width, bounds.origin.y);
  glVertex2f(bounds.origin.x+bounds.size.width, bounds.origin.y+bounds.size.height);
  glVertex2f(bounds.origin.x, bounds.origin.y+bounds.size.height);
  glEnd();
}


@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
