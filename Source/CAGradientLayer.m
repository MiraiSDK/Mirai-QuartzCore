/* CAGradientLayer.m

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
#import "CAGradientLayer.h"

@implementation CAGradientLayer{

    BOOL startPointInited;
    BOOL endPointInited;
}
@synthesize colors = _colors;
@synthesize locations = _locations;
@synthesize startPoint = _startPoint;
@synthesize endPoint = _endPoint;
@synthesize type = _type;

-(CGPoint) startPoint {

    return _startPoint;
}

- (void)setStartPoint:(CGPoint)newPoint {

    startPointInited = YES;
    _startPoint = newPoint;
}

-(CGPoint) endPoint {
    
    return _startPoint;
}

- (void)setEndPoint:(CGPoint)newPoint {
    
    endPointInited = YES;
    _endPoint = newPoint;
}

-(CGFloat*)locationArray {

    CGFloat* ret = malloc(sizeof(CGFloat) * [_locations count]);;
    for (int i = 0; i< [_locations count]; i++) {
        
        ret[i] = [[_locations objectAtIndex:i] floatValue];
    }
    return ret;
}

- (void) drawInContext: (CGContextRef)context
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (!_colors) {
        
        CGColorRef c1 = CGColorCreateGenericRGB(0.0, 0.0 , 0.0, 1);
        CGColorRef c2 = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1);
        _colors = [NSArray arrayWithObjects:(id)c1,(id)c2,nil];
    }
    
    if(!_locations || [_locations count]<2) {
        
        NSUInteger count = [_colors count];
        if (count<=2) {
            count = 2;
            _locations = [NSArray arrayWithObjects:
                          [NSNumber numberWithFloat:0],
                          [NSNumber numberWithFloat:1],
                          nil];
        } else {
            
            NSMutableArray* newLocations = [NSMutableArray array];
            CGFloat step = 1.0/(count-1);
            for (NSUInteger i = 0 ; i < count; i++) {
                NSNumber* location = [NSNumber numberWithDouble:i*step];
                [newLocations addObject:location];
            }
            _locations = newLocations;
        }
    }
    
    if (!startPointInited) {
        
        _startPoint = CGPointMake(0.5, 0.0);
    }
    
    if (!endPointInited) {
        
        _endPoint = CGPointMake(0.5, 1.0);
    }

    CGFloat* locationCArray = [self locationArray];
    
#if !GNUSTEP
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace,
                                                        (CFArrayRef) _colors, locationCArray);
#else
    CGFloat components[8] = { 0.9, 0.9, 0.8, 1.0,  // Start color
        1., 1., 1., 1.0 }; // End color
    size_t num_locations = [_locations count];
    CGGradientRef gradient = CGGradientCreateWithColorComponents (colorSpace,
                                                                  components, locationCArray, num_locations);
#endif
    
    CGRect rect = CGContextGetClipBoundingBox(context);
    CGPoint startPoint = CGPointMake(rect.origin.x + rect.size.width * _startPoint.x,
                                     rect.origin.y + rect.size.height * _startPoint.y);
    CGPoint endPoint = CGPointMake(rect.origin.x + rect.size.width * _endPoint.x,
                                   rect.origin.y + rect.size.height * _endPoint.y);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
}


@end
