/* CAShapeLayer.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Amr Aboelela <amraboelela@gmail.com>

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

#import "CAShapeLayer.h"
@implementation CAShapeLayer
@synthesize path = _path;
@synthesize fillColor = _fillColor;
@synthesize fillRule = _fillRule;
@synthesize strokeColor = _strokeColor;
@synthesize strokeStart = _strokeStart, strokeEnd = _strokeEnd;
@synthesize lineWidth = _lineWidth, miterLimit = _miterLimit;
@synthesize lineCap = _lineCap, lineJoin = _lineJoin;
@synthesize lineDashPhase = _lineDashPhase, lineDashPattern = _lineDashPattern;

- (instancetype)init
{
    self = [super init];
    if (self) {
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        
        const CGFloat components[] = {0,0,0,1};
        _fillColor = CGColorCreate(cs, components);
        
        CGColorSpaceRelease(cs);
        
    }
    return self;
}

// FIXME: The Apple's documentation indicate that CAShapeLayer class creates its content by rendering the path into a bitmap image at composite time.
- (void)display
{
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef ctx = CGBitmapContextCreate(NULL,
                                             self.bounds.size.width,
                                             self.bounds.size.height,
                                             8,
                                             self.bounds.size.width * 4,
                                             cs,
                                             kCGImageAlphaPremultipliedLast);
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -self.bounds.size.height);
    
    if (_fillColor && _path) {
        CGContextSetFillColorWithColor(ctx, self.fillColor);
        CGContextAddPath(ctx, self.path);
        CGContextFillPath(ctx);
    }
    
    if (_strokeColor && _path) {
        CGContextAddPath(ctx, self.path);
        CGContextSetStrokeColorWithColor(ctx, self.strokeColor);
        CGContextStrokePath(ctx);
    }
    
    CGImageRef image = CGBitmapContextCreateImage(ctx);
    self.contents = image;
    CGImageRelease(image);
    CGContextRelease(ctx);
    CGColorSpaceRelease(cs);
}

- (void)setFillColor:(CGColorRef)fillColor
{
    _fillColor = CGColorRetain(fillColor);
}

- (CGColorRef)fillColor
{
    return _fillColor;
}

- (void)setStrokeColor:(CGColorRef)strokeColor
{
    _strokeColor = CGColorRetain(strokeColor);
}

- (CGColorRef)strokeColor
{
    return _strokeColor;
}

- (void)setPath:(CGPathRef)path
{
    _path = CGPathRetain(path);
}

- (CGPathRef)path
{
    return _path;
}


@end

NSString *const kCAFillRuleNonZero = @"non-zero";
NSString *const kCAFillRuleEvenOdd = @"even-odd";

NSString *const kCALineJoinMiter = @"miter";
NSString *const kCALineJoinRound = @"round";
NSString *const kCALineJoinBevel = @"bevel";

NSString *const kCALineCapButt = @"butt";
NSString *const kCALineCapRound = @"round";
NSString *const kCALineCapSquare = @"square";
