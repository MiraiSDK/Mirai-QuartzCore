/* CAGradientLayer.m

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

- (instancetype)init
{
    self = [super init];
    if (self) {
        // FIXME:  Should remove this while we support gradient in OpenGL ES renderer
        self.needsDisplayOnBoundsChange = YES;
    }
    return self;
}

- (void)dealloc
{
    [_colors release];
    [_locations release];
    [_type release];
    
    [super dealloc];
}
-(CGPoint) startPoint {

    return _startPoint;
}

- (void)setStartPoint:(CGPoint)newPoint {

    startPointInited = YES;
    _startPoint = newPoint;
}

-(CGPoint) endPoint {
    
    return _endPoint;
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
        
        const CGFloat c1Components[] = {0.0,0.0,0.0,1.0};
        const CGFloat c2Components[] = {1.0,1.0,1.0,1.0};

        CGColorRef c1 = CGColorCreate(colorSpace, c1Components); // CGColorCreateGenericRGB(0.0, 0.0 , 0.0, 1);
        CGColorRef c2 = CGColorCreate(colorSpace, c2Components); //CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1);
        _colors = [NSArray arrayWithObjects:(id)c1,(id)c2,nil];
        CGColorRelease(c1);
        CGColorRelease(c2);
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
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace,
                                                        (CFArrayRef) _colors, locationCArray);
    
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
