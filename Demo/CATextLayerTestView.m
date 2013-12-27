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

@implementation CATextLayerTestView

- (void) doTest {

    [self testNSString];
    [self testAString];
    [self testCTFont];
    [self testCGFtont];
//    [self testWarpped];
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

@end

