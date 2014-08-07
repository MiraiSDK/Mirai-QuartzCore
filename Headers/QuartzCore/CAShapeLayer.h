/* CAShapeLayer.h

*/

@interface CAShapeLayer : CALayer

@property CGPathRef path;
@property CGColorRef fillColor;
@property(copy) NSString *fillRule;
@property CGColorRef strokeColor;
@property CGFloat strokeStart, strokeEnd;
@property CGFloat lineWidth;
@property CGFloat miterLimit;
@property(copy) NSString *lineCap;
@property(copy) NSString *lineJoin;
@property CGFloat lineDashPhase;
@property(copy) NSArray *lineDashPattern;

@end

CA_EXTERN NSString *const kCAFillRuleNonZero;
CA_EXTERN NSString *const kCAFillRuleEvenOdd;

CA_EXTERN NSString *const kCALineJoinMiter;
CA_EXTERN NSString *const kCALineJoinRound;
CA_EXTERN NSString *const kCALineJoinBevel;

CA_EXTERN NSString *const kCALineCapButt;
CA_EXTERN NSString *const kCALineCapRound;
CA_EXTERN NSString *const kCALineCapSquare;
