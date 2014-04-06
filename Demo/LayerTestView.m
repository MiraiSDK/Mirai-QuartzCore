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

#import "LayerTestView.h"

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

@implementation LayerTestView

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
    
    [self doTest];
    
  [self startAnimation];
  
  CGColorRelease(yellowColor);
  CGColorRelease(whiteColor);
  CGColorRelease(blackColor);
  CGColorRelease(grayColor);

  glViewport(0, 0, [self frame].size.width, [self frame].size.height);
  glClear(GL_COLOR_BUFFER_BIT);

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

- (void)doTest {

}

@end