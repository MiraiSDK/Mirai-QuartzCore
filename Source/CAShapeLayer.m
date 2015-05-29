/* CAShapeLayer.m

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

- (void)dealloc
{
    CGColorRelease(_strokeColor);
    CGColorRelease(_fillColor);
    CGPathRelease(_path);
    
    [_lineCap release];
    [_lineJoin release];
    [_lineDashPattern release];
    [_fillRule release];
    [super dealloc];
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
                                             kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -self.bounds.size.height);
    
    if (_fillColor && _path) {
        CGContextSetFillColorWithColor(ctx, self.fillColor);
        //FIXME: why access self.path leading crash?
        CGContextAddPath(ctx, _path);
        CGContextFillPath(ctx);
    }
    
    if (_strokeColor && _path) {
        CGContextAddPath(ctx, self.path);
        CGContextSetStrokeColorWithColor(ctx, self.strokeColor);
        CGContextStrokePath(ctx);
    }
    
    CGImageRef image = CGBitmapContextCreateImage(ctx);
    self.contents = (id)image;
    CGImageRelease(image);
    CGContextRelease(ctx);
    CGColorSpaceRelease(cs);
}

- (void)setFillColor:(CGColorRef)fillColor
{
    CGColorRelease(_fillColor);
    _fillColor = CGColorRetain(fillColor);
    [self setNeedsDisplay];
}

- (CGColorRef)fillColor
{
    return _fillColor;
}

- (void)setStrokeColor:(CGColorRef)strokeColor
{
    CGColorRelease(_strokeColor);
    _strokeColor = CGColorRetain(strokeColor);
    [self setNeedsDisplay];
}

- (CGColorRef)strokeColor
{
    return _strokeColor;
}

- (void)setPath:(CGPathRef)path
{
    CGPathRelease(_path);
    _path = CGPathRetain(path);
    [self setNeedsDisplay];
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
