/* CALayer.m

   Copyright (C) 2012 Free Software Foundation, Inc.
   
   Author: Ivan Vučica <ivan@vucica.net>
   Date: June 2012

   Author: Amr Aboelela <amraboelela@gmail.com>
   Date: December 2011

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

#import <Foundation/Foundation.h>
#import "QuartzCore/CAAnimation.h"
#import "QuartzCore/CALayer.h"
#import "CALayer+CARender.h"
#import "CALayer+CAType.h"
#import "CABackingStore.h"
#import "CALayer+FrameworkPrivate.h"
#import "CAAnimation+FrameworkPrivate.h"
#import <objc/runtime.h>
#import "CALayer+DynamicProperties.h"
#import "QuartzCore/CATransaction.h"
#import "CABackingStore.h"
#import "CATransaction+FrameworkPrivate.h"
#import "CATransformDecompose.h"
#import "CAMovieLayer.h"
#import "CATextureLoader.h"
#import "CAGLNestingSequencer.h"

#if GNUSTEP
#import <CoreGraphics/CoreGraphics.h>
#endif
#import <stdlib.h>

static CFTimeInterval currentFrameBeginTime = 0;

NSString *const kCAGravityResize = @"CAGravityResize";
NSString *const kCAGravityResizeAspect = @"CAGravityResizeAspect";
NSString *const kCAGravityResizeAspectFill = @"CAGravityResizeAspectFill";
NSString *const kCAGravityCenter = @"CAGravityCenter";
NSString *const kCAGravityTop = @"CAGravityTop";
NSString *const kCAGravityBottom = @"CAGravityBottom";
NSString *const kCAGravityLeft = @"CAGravityLeft";
NSString *const kCAGravityRight = @"CAGravityRight";
NSString *const kCAGravityTopLeft = @"CAGravityTopLeft";
NSString *const kCAGravityTopRight = @"CAGravityTopRight";
NSString *const kCAGravityBottomLeft = @"CAGravityBottomLeft";
NSString *const kCAGravityBottomRight = @"CAGravityBottomRight";
NSString *const kCATransition = @"CATransition";

typedef NS_ENUM(NSInteger, CALayerType) {
    CALayerModelType,
    CALayerPresentationType,
    CALayerRenderingType
};

@interface CALayer()
@property (nonatomic, assign) CALayer * superlayer;
@property (nonatomic, retain) NSMutableDictionary * animations;
@property (retain) NSMutableArray * animationKeys;
@property (retain) CABackingStore * backingStore;
@property (retain) CABackingStore * combinedBackingStore;
@property (assign,getter = isDirty) BOOL dirty;
@property (nonatomic, retain) NSMutableArray *finishedAnimations;

- (void)setModelLayer: (id)modelLayer;

// commit
@property (assign) BOOL needsCommit;
@property (assign) CALayerType type;
@property (assign) CALayer *renderingLayer;
@property (retain) CAGLTexture *texture;

@end

@implementation CALayer

@synthesize delegate=_delegate;
@synthesize contents=_contents;
@synthesize layoutManager=_layoutManager;
@synthesize superlayer=_superlayer;
@synthesize sublayers=_sublayers;
@synthesize frame=_frame;
@synthesize bounds=_bounds;
@synthesize anchorPoint=_anchorPoint;
@synthesize position=_position;
@synthesize opacity=_opacity;
@synthesize transform=_transform;
@synthesize sublayerTransform=_sublayerTransform;
@synthesize shouldRasterize=_shouldRasterize;
@synthesize opaque=_opaque;
@synthesize geometryFlipped=_geometryFlipped;
@synthesize backgroundColor=_backgroundColor;
@synthesize masksToBounds=_masksToBounds;
@synthesize contentsRect=_contentsRect;
@synthesize hidden=_hidden;
@synthesize contentsGravity=_contentsGravity;
@synthesize needsDisplayOnBoundsChange=_needsDisplayOnBoundsChange;
@synthesize zPosition=_zPosition;
@synthesize actions=_actions;
@synthesize style=_style;

@synthesize shadowColor=_shadowColor;
@synthesize shadowOffset=_shadowOffset;
@synthesize shadowOpacity=_shadowOpacity;
@synthesize shadowPath=_shadowPath;
@synthesize shadowRadius=_shadowRadius;

/* properties in protocol CAMediaTiming */
@synthesize beginTime=_beginTime;
@synthesize timeOffset=_timeOffset;
@synthesize repeatCount=_repeatCount;
@synthesize repeatDuration=_repeatDuration;
@synthesize autoreverses=_autoreverses;
@synthesize fillMode=_fillMode;
@synthesize duration=_duration;
@synthesize speed=_speed;

/* private or publicly read-only properties */
@synthesize animations=_animations;
@synthesize animationKeys=_animationKeys;
@synthesize backingStore=_backingStore;
@synthesize combinedBackingStore=_combinedBackingStore;

@synthesize dirty = _dirty;
@synthesize type = _type;
@synthesize borderColor = _borderColor;
@synthesize borderWidth = _borderWidth;
@synthesize contentsScale = _contentsScale;
@synthesize name = _name;
@synthesize finishedAnimations = _finishedAnimations;
@synthesize renderingLayer = _renderingLayer;
@synthesize texture = _texture;
@synthesize mask = _mask;

static CAGLNestingSequencer *_animationFinishCallbackNestingSequencer;

+ (void) initialize
{
    _animationFinishCallbackNestingSequencer = [[CAGLNestingSequencer alloc] init];
}

/* *** dynamic synthesis of properties *** */
#if 0
+ (void) initialize
{
     
  unsigned int count;
  objc_property_t * properties = class_copyPropertyList([self class], &count);
    
  for (unsigned int i = 0; i < count; i++)
    {
        
      objc_property_t property = properties[i];
      
      const char * attributesC = property_getAttributes(property);
      if(!attributesC)
	{
	  NSLog(@"Property %s could not be examined", property_getName(property));
	  continue;
	}
      NSString * attributes = [NSString stringWithCString: attributesC
                                                 encoding: NSASCIIStringEncoding];
        
      NSArray* components = [attributes componentsSeparatedByString: @","];
        
      for (NSString* component in components)
        {
          if ([component isEqualToString:@"D"])
            {
              [self _dynamicallyCreateProperty:property];
            }
        }
    }
    
  free(properties);
}
#else
#warning Disabled dynamic synthesis of properties
#endif

/* *** class methods *** */
+ (id) layer
{
  return [[self new] autorelease];
}

- (void) _convertToRootLayer
{
    _isRootLayer = YES;
}

+ (id) defaultValueForKey: (NSString *)key
{
  if ([key isEqualToString:@"delegate"])
    {
      return nil;
    }
  if ([key isEqualToString: @"anchorPoint"])
    {
      CGPoint pt = CGPointMake(0.5, 0.5);
      return [NSValue valueWithBytes: &pt objCType: @encode(CGPoint)];
    }
  if ([key isEqualToString: @"transform"])
    {
      return [NSValue valueWithCATransform3D: CATransform3DIdentity];
    }
  if ([key isEqualToString: @"sublayerTransform"])
    {
      return [NSValue valueWithCATransform3D: CATransform3DIdentity];
    }
  if ([key isEqualToString: @"shouldRasterize"])
    {
      return [NSNumber numberWithBool: NO];
    }
  if ([key isEqualToString: @"opacity"])
    {
      return [NSNumber numberWithFloat: 1.0];
    }
  if ([key isEqualToString: @"contentsRect"])
    {
      CGRect rect = CGRectMake(0.0, 0.0, 1.0, 1.0);
      return [NSValue valueWithBytes: &rect objCType: @encode(CGRect)];
    }
  if ([key isEqualToString: @"shadowColor"])
    {
      /* opaque black color */
      /* note: under Cocoa this is an opaque Core Foundation type.
         these types are nonetheless retainable, releasable, autoreleasable,
         just like Opal's Objective-C class instances */
        const CGFloat components[] = {0.0,0.0,0.0,1.0};
        CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
        CGColorRef color = CGColorCreate(space, components);
        CGColorSpaceRelease(space);
        
      return [(id)color autorelease];
    }
  if ([key isEqualToString: @"shadowOffset"])
    {
      CGSize offset = CGSizeMake(0.0, -3.0);
      return [NSValue valueWithBytes: &offset objCType: @encode(CGSize)];
    }
  if ([key isEqualToString: @"shadowRadius"])
    {
      return [NSNumber numberWithFloat: 3.0];
    }
    
  /* CAMediaTiming */
  if ([key isEqualToString:@"duration"])
    {
      return [NSNumber numberWithFloat: __builtin_inf()];
      /* FIXME: is there a cleaner way to get inf apart from "1./0"? */
    }
  if ([key isEqualToString:@"speed"])
    {
      return [NSNumber numberWithFloat: 1.0];
    }
  if ([key isEqualToString:@"autoreverses"])
    {
      return [NSNumber numberWithBool: NO];
    }
  if ([key isEqualToString:@"repeatCount"])
    {
      return [NSNumber numberWithFloat: 1.0];
    }
  if ([key isEqualToString: @"beginTime"])
    {
      return [NSNumber numberWithFloat: 0.0];
    }
    if ([key isEqualToString: @"contentsScale"])
    {
        return [NSNumber numberWithFloat: 1.0];
    }

    if ([key isEqualToString: @"contentsGravity"])
    {
        return kCAGravityResize;
    }
  return nil;
}

/* *** methods *** */
- (id) init
{
  if ((self = [super init]) != nil)
    {
      _needsDisplay = YES;
      _layersMaskedByMe = [[NSMutableSet alloc] init];
      _animations = [[NSMutableDictionary alloc] init];
      _animationKeys = [[NSMutableArray alloc] init];
      _sublayers = [[NSMutableArray alloc] init];
      _finishedAnimations = [[NSMutableArray alloc] init];
      /* TODO: list all properties below */
      static NSString * keys[] = {
        @"transform", @"sublayerTransform",
        @"opacity", @"delegate", @"shouldRasterize",
        @"backgroundColor",
        
        @"beginTime", @"duration", @"speed", @"autoreverses",
        @"repeatCount",
        
        @"shadowColor", @"shadowOpacity",
        @"shadowPath", @"shadowRadius",

          @"contentsScale"};
        
        // Workaround: defaultValueForKey: leaked. why?
        _contentsRect = CGRectMake(0.0, 0.0, 1.0, 1.0);
        _bounds = CGRectZero;
        _position = CGPointZero;
        
        _anchorPoint = CGPointMake(0.5, 0.5);
        _shadowOffset =CGSizeMake(0.0, -3.0);
        
      
      for (int i = 0; i < sizeof(keys)/sizeof(keys[0]); i++)
        {
          id defaultValue = [[self class] defaultValueForKey: keys[i]];
          if (defaultValue)
            {
            
              #if 0
              NSString * setter = [NSString stringWithFormat:@"set%@%@:", [[keys[i] substringToIndex: 1] uppercaseString], [keys[i] substringFromIndex: 1]];
              
              if (![self respondsToSelector: NSSelectorFromString(setter)])
                {
                  NSLog(@"Key %@ is missing setter", keys[i]);
                }
              else
                {
                  NSLog(@"setter %@ found", setter);
                }
              #endif
              
              [self setValue: defaultValue
                      forKey: keys[i]];
            }

          /* implicit animations support */
          /* TODO: only animatable properties should be observed */
          /* TODO: @dynamically created properties also need to be
              set up and observed. */
        }
        _inited = YES;

    }
  return self;
}

- (id) initWithLayer: (CALayer*)layer
{
  /* Used when creating shadow copies of 'layer', e.g. when creating 
     presentation layer. Not to be used by app developer for copying existing
     layers. */
  if ((self = [super init]) != nil)
    {
        _layoutManager = [layer->_layoutManager retain];
        _superlayer = layer->_superlayer; /* if copied for use in presentation layer, then ignored */
        _sublayers = [layer->_sublayers copy]; /* if copied for use in presentation layer, then ignored */
      /* frame not copied: dynamically generated */
        _bounds = layer->_bounds;
        _anchorPoint = layer->_anchorPoint;
        _position = layer->_position;
        _opacity = layer->_opacity;
        _isRootLayer = layer->_isRootLayer;
        _transform = layer->_transform;
        _sublayerTransform = layer->_sublayerTransform;
        _shouldRasterize = layer->_shouldRasterize;
        _opaque = layer->_opaque;
        _geometryFlipped = layer->_geometryFlipped;
        _backgroundColor = CGColorRetain(layer->_backgroundColor);
        _masksToBounds = layer->_masksToBounds;
        _contentsRect = layer->_contentsRect;
        _hidden = layer->_hidden;
        _contentsGravity = [layer->_contentsGravity copy];
        _needsDisplayOnBoundsChange = layer->_needsDisplayOnBoundsChange;
        _zPosition = layer->_zPosition;
        
        
        _contentsScale = layer->_contentsScale;
        
        _borderColor = CGColorRetain(layer->_borderColor);
        _borderWidth = layer->_borderWidth;
        
        _shadowColor = CGColorRetain(layer->_shadowColor);
        _shadowOffset = layer->_shadowOffset;
        _shadowOpacity = layer->_shadowOpacity;
        _shadowPath = CGPathRetain(layer->_shadowPath);
        _shadowRadius = layer->_shadowRadius;
      
      /* FIXME
         setting contents currently needs to be below setting bounds, 
         because setting the bounds currently destroys the contents. */
      [self setContents: [layer contents]]; 
      
      /* properties in protocol CAMediaTiming */
        _beginTime = layer->_beginTime;
        _timeOffset = layer->_timeOffset;
        _repeatCount = layer->_repeatCount;
        _repeatDuration = layer->_repeatDuration;
        _autoreverses = layer->_autoreverses;
        _fillMode = [layer->_fillMode copy];
        _duration = layer->_duration;
        _speed = layer->_speed;
      
      /* private or publicly read-only properties */
        _animations = [layer->_animations retain];
        _animationKeys = [layer->_animationKeys retain];
        
        _type = layer->_type;
        _name = [layer->_name copy];
        
        _needsLayout = layer.needsLayout;
        _texture = [layer->_texture retain];
        
        _combinedBackingStore = [layer->_combinedBackingStore retain];
        _layersMaskedByMe = [layer->_layersMaskedByMe retain];
    }
  return self;
}

- (void) dealloc
{
  CGColorRelease(_shadowColor);
  CGPathRelease(_shadowPath);
    CGColorRelease(_borderColor);
  [_layoutManager release];
  [_contents release];
    
    // should clear reference in sublayers,
    // without doing this, sublayer will crash on -[CALayer removeFromSuperlayer] call
    // this can be remove after we convert project to ARC enabled, and declare superlayer as weak reference
    for (CALayer *subLayer in _sublayers) {
        [subLayer setSuperlayer:nil];
    }
  [_sublayers release];
  CGColorRelease(_backgroundColor);
  [_contentsGravity release];
  [_fillMode release];
  
  [_backingStore release];
  [_combinedBackingStore release];
  [_layersMaskedByMe release];
  [_animations release];
  [_animationKeys release];
    if (_modelLayer) {
        CALayer * m = _modelLayer;
        if (_type == CALayerPresentationType && m->_presentationLayer == self) {
            m->_presentationLayer = nil;
        } else if (_type == CALayerRenderingType && m->_renderingLayer == self) {
            m->_renderingLayer = nil;
        }
        [_modelLayer release];
    }
  [_finishedAnimations release];
    [_texture release];
    [_mask release];
    
  [super dealloc];
}

- (NSString *)description
{
    NSMutableString *str = [NSMutableString stringWithFormat: @"<%@:%p; position = CGPoint (%g %g); bounds = CGRect (%g %g; %g %g);",
                            [self class],
                            self,
                            [self position].x, [self position].y,
                            [self bounds].origin.x,[self bounds].origin.y,[self bounds].size.width,[self bounds].size.height];

    if (self.delegate) {
        [str appendFormat:@"delegate = <%@:%p>",[self.delegate class],self.delegate];
    }
    
    if (self.name) {
        [str appendFormat:@"name = %@",self.name];
    }

    NSString *type;
    switch (_type) {
        case CALayerModelType: type = @"model"; break;
        case CALayerPresentationType: type = @"presentation"; break;
        case CALayerRenderingType: type = @"rendering"; break;
            
        default:
            break;
    }
    [str appendFormat:@" layerType: %@",type];
    [str appendString:@">"];
    return str;
}

/* *** properties *** */
#if GNUSTEP
#warning KVO under GNUstep does not work without custom setters for any struct type!
/* For more info, refer to NSKeyValueObserving.m. */
/* Once we implement @dynamic generation, this won't be important, but
   it's still a GNUstep bug. */
#define GSCA_OBSERVABLE_SETTER(settername, type, prop, comparator) \
  - (void) settername: (type)prop \
  { \
    if (comparator(prop, _ ## prop)) \
      return; \
    \
    [self beginChangeKeyPath: @ #prop];\
    [self willChangeValueForKey: @ #prop]; \
    _ ## prop = prop; \
    [self didChangeValueForKey: @ #prop]; \
  }

#define GSCA_OBSERVABLE_ACCESSES(settername, type, prop, comparator) \
  - (void) settername: (type)prop \
  { \
    @synchronized(self) {\
      if (comparator(prop, _ ## prop)) \
      return; \
      \
      [self beginChangeKeyPath: @ #prop];\
      [self willChangeValueForKey: @ #prop]; \
      _ ## prop = prop; \
      [self didChangeValueForKey: @ #prop]; \
    }\
  }\
  - (type) prop \
  {\
    @synchronized(self) {\
      return _  ## prop;  \
    }\
  }

#define GSCA_OBSERVABLE_ACCESSES_NONATOMIC(settername, type, prop, comparator) \
- (void) settername: (type)prop \
{ \
if (comparator(prop, _ ## prop)) \
return; \
\
[self beginChangeKeyPath: @ #prop];\
[self willChangeValueForKey: @ #prop]; \
_ ## prop = prop; \
[self didChangeValueForKey: @ #prop]; \
}\
- (type) prop \
{\
return _  ## prop;  \
}

#define GSCA_OBSERVABLE_ACCESSES_BASIC_ATOMIC(settername, type, prop) \
  - (void) settername: (type)prop \
  { \
    @synchronized(self) {\
      if (prop == _ ## prop) \
        return; \
      \
      [self beginChangeKeyPath: @ #prop];\
      [self willChangeValueForKey: @ #prop]; \
      _ ## prop = prop; \
      [self didChangeValueForKey: @ #prop]; \
    }\
  }\
  - (type) prop \
  {\
    @synchronized(self) {\
      return _  ## prop;  \
    }\
  }

#define GSCA_OBSERVABLE_ACCESSES_BASIC_NONATOMIC(settername, type, prop) \
- (void) settername: (type)prop \
{ \
if (prop == _ ## prop) \
return; \
\
[self beginChangeKeyPath: @ #prop];\
[self willChangeValueForKey: @ #prop]; \
_ ## prop = prop; \
[self didChangeValueForKey: @ #prop]; \
}\
- (type) prop \
{\
return _  ## prop;  \
}

#define GSCA_OBSERVABLE_SETTER_BASIC_NONATOMIC(settername, type, prop) \
- (void) settername: (type)prop \
{ \
if (prop == _ ## prop) \
return; \
\
[self beginChangeKeyPath: @ #prop];\
[self willChangeValueForKey: @ #prop]; \
_ ## prop = prop; \
[self didChangeValueForKey: @ #prop]; \
}


GSCA_OBSERVABLE_SETTER(setPosition, CGPoint, position, CGPointEqualToPoint)
GSCA_OBSERVABLE_SETTER(setAnchorPoint, CGPoint, anchorPoint, CGPointEqualToPoint)
GSCA_OBSERVABLE_SETTER(setTransform, CATransform3D, transform, CATransform3DEqualToTransform)
GSCA_OBSERVABLE_SETTER(setSublayerTransform, CATransform3D, sublayerTransform, CATransform3DEqualToTransform)
GSCA_OBSERVABLE_SETTER(setShadowOffset, CGSize, shadowOffset, CGSizeEqualToSize)

GSCA_OBSERVABLE_ACCESSES_NONATOMIC(setContentsRect, CGRect, contentsRect, CGRectEqualToRect)

GSCA_OBSERVABLE_SETTER_BASIC_NONATOMIC(setRepeatCount, float, repeatCount)
GSCA_OBSERVABLE_SETTER_BASIC_NONATOMIC(setBeginTime, CFTimeInterval, beginTime)
GSCA_OBSERVABLE_SETTER_BASIC_NONATOMIC(setSpeed, float, speed)
GSCA_OBSERVABLE_SETTER_BASIC_NONATOMIC(setDuration, CFTimeInterval, duration)
GSCA_OBSERVABLE_SETTER_BASIC_NONATOMIC(setAutoreverses, BOOL, autoreverses)

GSCA_OBSERVABLE_ACCESSES_BASIC_NONATOMIC(setOpacity, float, opacity)
GSCA_OBSERVABLE_ACCESSES_BASIC_NONATOMIC(setShadowOpacity, float, shadowOpacity)
GSCA_OBSERVABLE_ACCESSES_BASIC_NONATOMIC(setShadowRadius, CGFloat, shadowRadius)

- (void)beginChangeKeyPath:(NSString *)keyPath
{
    if (!_inited) {
        return;
    }
    if (![self isModelLayer])
    {
        return;
    }

    NSObject<CAAction>* action = (id)[self actionForKey: keyPath];
    if (!action || [action isKindOfClass: [NSNull class]])
        return;
    [[CATransaction topTransaction] registerAction: action
                                          onObject: self
                                           keyPath: keyPath];
    [self markDirty];
}


#endif

- (BOOL)isRootLayer
{
    return _isRootLayer;
}

- (id)delegate
{
    if ([self isRenderLayer]) {
        return ((CALayer *)_modelLayer)->_delegate;
    }
    return _delegate;
}

- (void)releaseDelegate
{
    [self setDelegate:nil];
}

- (void)setMask:(CALayer *)mask
{
//    if (_mask != mask) {
//        [self setNeedsDisplay];
//        if ([self isModelLayer]) {
//            if (_mask) {
//                NSValue *value = [NSValue valueWithNonretainedObject:self];
//                [_mask->_layersMaskedByMe removeObject:value];
//                [value release];
//            }
//            if (mask) {
//                NSValue *value = [NSValue valueWithNonretainedObject:self];
//                [mask->_layersMaskedByMe addObject:value];
//                [value release];
//            }
//        }
//        [_mask release];
//        _mask = [mask retain];
//    }
}


- (CGRect)frame
{
    CGAffineTransform t = self.affineTransform;
    
    CGSize size = _bounds.size;
    size = CGSizeApplyAffineTransform(size, t);
    CGPoint position = CGPointMake(_position.x + t.tx, _position.y + t.ty);
    
    return CGRectMake(position.x - (size.width * _anchorPoint.x),
                      position.y - (size.height * _anchorPoint.y),
                      size.width,
                      size.height);
}

- (void)setFrame:(CGRect)frame
{
    CGAffineTransform invertedTransform = CGAffineTransformInvert(self.affineTransform);
    CGSize transformedSize = CGSizeApplyAffineTransform(frame.size, invertedTransform);
    CGPoint newOrigin = frame.origin;
    CGPoint transformedPosition = CGPointMake(newOrigin.x + (frame.size.width * _anchorPoint.x),
                                              newOrigin.y + (frame.size.height * _anchorPoint.y));
    
    BOOL sizeChanged = CGSizeEqualToSize(transformedSize, frame.size);
    BOOL positionChanged = CGPointEqualToPoint(transformedPosition, frame.origin);
    
    _bounds.size = transformedSize;
    _position = transformedPosition;
    
    if (sizeChanged || (self.mask && positionChanged)) {
        [self setNeedsDisplay];
    }
    if (sizeChanged || positionChanged) {
        [self setNeedsLayout];
    }
}

- (void) setBounds: (CGRect)bounds
{
  if (CGRectEqualToRect(bounds, _bounds))
    return;
  
#if !GNUSTEP
  _bounds = bounds;
#else
#warning KVO under GNUstep doesn't work without custom setters for any struct type!
    [self beginChangeKeyPath:@"bounds"];
  [self willChangeValueForKey: @"bounds"];
  _bounds = bounds;
  [self didChangeValueForKey: @"bounds"];
#endif

  if ([self needsDisplayOnBoundsChange])
    {
      [self setNeedsDisplay];
    }
}

- (void)setBackgroundColor: (CGColorRef)backgroundColor
{
  if (backgroundColor == _backgroundColor)
    return;
  
    [self beginChangeKeyPath:@"backgroundColor"];
  [self willChangeValueForKey: @"backgroundColor"];
  CGColorRetain(backgroundColor);
  CGColorRelease(_backgroundColor);
  _backgroundColor = backgroundColor;
  [self didChangeValueForKey: @"backgroundColor"];
}

- (void)setBorderColor:(CGColorRef)borderColor
{
    if (borderColor == _borderColor)
        return;

    [self beginChangeKeyPath:@"borderColor"];
    [self willChangeValueForKey: @"borderColor"];
    CGColorRelease(_borderColor);
    _borderColor = CGColorRetain(borderColor);
    [self didChangeValueForKey:@"borderColor"];
}

- (CGColorRef)borderColor
{
    return _borderColor;
}

- (void)setShadowColor: (CGColorRef)shadowColor
{
  if (shadowColor == _shadowColor)
    return;
  
    [self beginChangeKeyPath:@"shadowColor"];
  [self willChangeValueForKey: @"shadowColor"];
  CGColorRetain(shadowColor);
  CGColorRelease(_shadowColor);
  _shadowColor = shadowColor;
  [self didChangeValueForKey: @"shadowColor"];
}

- (void)setShadowPath: (CGPathRef)shadowPath
{
  if (shadowPath == _shadowPath)
    return;
    
    [self beginChangeKeyPath:@"shadowPath"];
  [self willChangeValueForKey: @"shadowPath"];
  CGPathRetain(shadowPath);
  CGPathRelease(_shadowPath);
  _shadowPath = shadowPath;
  [self didChangeValueForKey: @"shadowPath"];
}

/* ***************** */
/* MARK: - Redisplay */

- (void) display
{
    if (self.mask) {
        CALayer *maskLayer = [self.mask isModelLayer]? self.mask: [self modelLayer];
        [maskLayer displayIfNeeded];
    }
    [self displayAccordingToSpecialCondition];
}

- (void) displayIfNeeded
{
    if (_needsDisplay) {
        if ([self isModelLayer]) {
            @try {
                [[CARenderer layerDisplayLock] lock];
                [self display];
            } @finally {
                [[CARenderer layerDisplayLock] unlock];
            }
        }
        _needsDisplay = NO;
    }
}

- (BOOL) needsDisplay
{
  return _needsDisplay;
}

- (void) setNeedsDisplay
{
  /* TODO: schedule redraw of the scene */
  _needsDisplay = YES;
    if ([self isModelLayer]) {
        for (NSValue *maskedLayerValue in _layersMaskedByMe) {
            CALayer *maskedLayer  = [maskedLayerValue nonretainedObjectValue];
            [maskedLayer setNeedsDisplay];
        }
    }
    [self markDirty];
}

- (void) setNeedsDisplayInRect: (CGRect)r
{
  [self setNeedsDisplay];
}

- (void) drawInContext: (CGContextRef)context
{
  if ([_delegate respondsToSelector: @selector(drawLayer:inContext:)])
    {
      [_delegate drawLayer: self inContext: context];
    }
}

- (CAGLTexture *) maskTextureWithLoader:(CATextureLoader *)texureLoader
{
    CAGLTexture * texture = nil;
    id layerContents = [self contents];
    
    if ([self isKindOfClass:[CAMovieLayer class]]) {
        texture = [self.backingStore contentsTexture];
    } else if ([layerContents isKindOfClass: [CABackingStore class]]) {
        CABackingStore * backingStore = layerContents;
        texture = [backingStore contentsTexture];
    }
#if GNUSTEP
    else if ([layerContents isKindOfClass: NSClassFromString(@"CGImage")])
#else
    else if ([layerContents isKindOfClass: NSClassFromString(@"__NSCFType")] &&
             CFGetTypeID(layerContents) == CGImageGetTypeID())
#endif
    {
        CGImageRef image = (CGImageRef)layerContents;
        texture = [texureLoader textureForLayer:self];
        if (texture.contents == nil) {
            NSLog(@"Texture:load image");
            [texture loadImage: image];
            texture.contents = layerContents;
        }
    } else {
            NSLog(@"UnSupported layerContents:%@ class:%@",layerContents, NSStringFromClass(self.class));
    }
    
    if (texture && texture.isInvalidated) {
        NSLog(@"[Warning] rendering a invalidated texture");
        texture = nil;
    }
    return texture;
}

/* ********************** */
/* MARK: - Layout methods */
- (CGSize)preferredFrameSize
{
    if (self.layoutManager && [self.layoutManager respondsToSelector:@selector(preferredSizeOfLayer:)]) {
        return [self.layoutManager preferredSizeOfLayer:self];
    }
    
    return self.bounds.size;
}

- (void) layoutIfNeeded
{
    if (_needsLayout) {
        [self layoutSublayers];
    }
    
    _needsLayout = NO;
}

- (void) layoutSublayers
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(layoutSublayersOfLayer:)]) {
        [self.delegate layoutSublayersOfLayer:self];
    } else if (self.layoutManager && [self.layoutManager respondsToSelector:@selector(layoutSublayersOfLayer:)]) {
        [self.layoutManager layoutSublayersOfLayer:self];
    }
}

- (void) setNeedsLayout
{
  _needsLayout = YES;
    self.dirty = YES;
}

- (BOOL)needsLayout
{
    return _needsLayout;
}

- (void)_recursionLayoutAndDisplayIfNeeds
{
    [self layoutIfNeeded];
    [self displayIfNeeded];
    
    NSArray *sublayers = [self.sublayers copy];
    for (CALayer *layer in sublayers) {
        [layer _recursionLayoutAndDisplayIfNeeds];
    }
    [sublayers release];
    if (self.mask) {
        [self.mask _recursionLayoutAndDisplayIfNeeds];
    }
}

- (void)_recursionLayoutIfNeeds
{
    [self layoutIfNeeded];
    
    NSArray *sublayers = [self.sublayers copy];
    for (CALayer *layer in sublayers) {
        [layer _recursionLayoutIfNeeds];
    }
    [sublayers release];
    if (self.mask) {
        [self _recursionLayoutIfNeeds];
    }
}

- (void)_recursionDisplayIfNeeds
{
    [self displayIfNeeded];
    
    NSArray *sublayers = [self.sublayers copy];
    for (CALayer *layer in sublayers) {
        [layer _recursionDisplayIfNeeds];
    }
    [sublayers release];
    if (self.mask) {
        [self _recursionDisplayIfNeeds];
    }
}
/* ************************************* */
/* MARK: - Model and presentation layers */
- (id) presentationLayer
{
    if (self.isDirty && _presentationLayer) {
        [self discardPresentationLayer];
    }
    
  if (!_modelLayer && !_presentationLayer)
    {
      [self displayIfNeeded];

      _presentationLayer = [[[[self class] alloc] initWithLayer: self] autorelease];
      [_presentationLayer setModelLayer: self];
        [(CALayer *)_presentationLayer setType:CALayerPresentationType];
        
      assert([_presentationLayer isPresentationLayer]);
        self.dirty = NO;
      
    }
  return _presentationLayer;
}

- (void) discardPresentationLayer
{
//  [_presentationLayer release];
  _presentationLayer = nil;
}

- (id) modelLayer
{
  return _modelLayer;
}

- (void) setModelLayer: (id)modelLayer
{
    [_modelLayer release];
  _modelLayer = [modelLayer retain];
}

- (BOOL) isPresentationLayer
{
    return (self.type == CALayerPresentationType);
}

- (BOOL)isRenderLayer
{
    return (self.type == CALayerRenderingType);
}

- (BOOL)isModelLayer
{
    return (self.type == CALayerModelType);
}

- (CALayer *) superlayer
{
  if (![self isPresentationLayer])
    {
      return _superlayer;
    }
  else
    {
      return [[[self modelLayer] superlayer] presentationLayer];
    }
}

- (NSArray *) sublayers
{
  if (![self isPresentationLayer])
    {
        return _sublayers;
    }
  else
    {
      NSMutableArray * presentationSublayers = [NSMutableArray arrayWithCapacity:[[[self modelLayer] sublayers] count]];
      for (id modelSublayer in [[self modelLayer] sublayers])
        {
          [presentationSublayers addObject: [modelSublayer presentationLayer]];
        }
      return presentationSublayers;
    }
}

/* **************** */
/* MARK: Animations */
- (void) addAnimation: (CAAnimation *)anim forKey: (NSString *)key
{
    if (key == nil) {
        key = @"__CALayer_NIL_KEY";;
    }
    // if animation key already exist, we must notify exist animation cancelled.
    if ([_animationKeys containsObject:key]) {
        CAAnimation *existAnimation = [_animations valueForKey:key];
        if (existAnimation) {
            [self performSelectorOnMainThread:@selector(notifyAnimationsCancelled:) withObject:@[existAnimation] waitUntilDone:NO];
        } else {
            NSLog(@"[Warning] exepect animation doesn't exist");
        }
    }
  [_animations setValue: anim
                 forKey: key];
  [key retain];
  [_animationKeys removeObject: key];
  [_animationKeys addObject: key];
  [key release];
  
  if (![anim duration])
    [anim setDuration: [CATransaction animationDuration]];
  /* Timing function intentionally set ONLY within transaction. */
  
  if ([anim isKindOfClass: [CABasicAnimation class]])
    {
      CABasicAnimation * basicAnimation = (id)anim;
      CALayer * layer = self;

        // TODO: presentationLayer currently broken.
        // also needs to figure out the fromValue should come from presentation value?
//      if (![layer isPresentationLayer])
//        layer = [layer presentationLayer];
      
      if (![basicAnimation fromValue])
        {
          /* Should not be using setFromValue: since this method is not
             triggered under Cocoa either when we offer it a CABasicAnimation
             subclass. */
          
          [basicAnimation setFromValue: [layer valueForKeyPath: [basicAnimation keyPath]]];
        }
    } else if ([anim isKindOfClass: [CAAnimationGroup class]]){
        CAAnimationGroup *group = anim;
        CALayer * layer = self;

        for (CAAnimation *a in group.animations) {
            if ([a isKindOfClass: [CABasicAnimation class]]) {
                CABasicAnimation * basicAnimation = a;
                if (![basicAnimation fromValue]) {
                    [basicAnimation setFromValue: [layer valueForKeyPath: [basicAnimation keyPath]]];
                }
            }
        }
        
    }
}

- (void)removeAllAnimations
{
    [_animationKeys removeAllObjects];
    [_animations removeAllObjects];
}

- (void) removeAnimationForKey: (NSString *)key
{
  [_animations removeObjectForKey: key];
  [_animationKeys removeObject: key];
}

- (CAAnimation *)animationForKey: (NSString *)key
{
    if (key == nil) {
        key = @"__CALayer_NIL_KEY";;
    }
    
  return [_animations valueForKey: key];
}

- (CFTimeInterval) applyAnimationsAtTime: (CFTimeInterval)theTime
{
  if ([self isModelLayer])
    {
      static BOOL warned = NO;
      if (!warned)
        {
          NSLog(@"One time warning: Attempted to apply animations to model layer. Redirecting to presentation layer since applying animations only makes sense for presentation layers.");
          warned = YES;
        }
      return [[self presentationLayer] applyAnimationsAtTime: theTime];
    }
    
  NSMutableArray * animationKeysToRemove = [NSMutableArray new];
  CFTimeInterval lowestNextFrameTime = __builtin_inf();
   NSArray *animationKeys = [self.animationKeys copy];
  for (NSString * animationKey in animationKeys)
    {
      CAAnimation * animation = [[[_animations objectForKey: animationKey] retain] autorelease];

      if ([animation beginTime] == 0)
        {
          // FIXME: this MUST be grabbed from CATransaction, and
          // it must be done by the animation itself!
          // alternatively, this needs to be applied to the
          // animation upon +[CATransaction commit]
          
          // Additional observed behavior:
          // beginTime appears to be applied not to the original
          // animation object, but to the presentationLayer replica's
          // animation object. Test by printing beginTime immediately after
          // creating a non-implicit animation and printing presentationLayer's
          // beginTime. Original object should still have 0 as beginTime,
          // but the replica's animation object should now have the calculated
          // begin time.
            
          CFTimeInterval oldFrameBeginTime = currentFrameBeginTime;
          currentFrameBeginTime = CACurrentMediaTime();
          [animation setBeginTime: [animation activeTimeWithTimeAuthorityLocalTime: [self localTime]]];
          currentFrameBeginTime = oldFrameBeginTime;
        }

      CFTimeInterval nextFrameTime = [animation beginTime];
      nextFrameTime = [self convertTime: nextFrameTime toLayer: nil];
      
      if(nextFrameTime < lowestNextFrameTime)
        lowestNextFrameTime = nextFrameTime;
      
      if (nextFrameTime > CACurrentMediaTime())
        {
          /* TODO: update for correctness once we support fillMode */
          /* TODO: take into account animation groups once we support them */
          
          continue;
        }
      
      if ([animation isKindOfClass: [CAPropertyAnimation class]])
        {
          CAPropertyAnimation * propertyAnimation = ((CAPropertyAnimation *)animation);
                        
          if ([propertyAnimation removedOnCompletion] && [propertyAnimation activeTimeWithTimeAuthorityLocalTime: [self localTime]] > [propertyAnimation duration] * ([propertyAnimation repeatCount] + 1) * ([propertyAnimation autoreverses] ? 2 : 1))
            {
              /* FIXME: doesn't take into account speed */
                
              [animationKeysToRemove addObject: animationKey];
              continue; /* Prevents animation from applying for one frame longer than its duration */
            }
            
          [propertyAnimation applyToLayer: self];
            
        } else if ([animation isKindOfClass: [CAAnimationGroup class]]) {
            CAAnimationGroup * group = ((CAAnimationGroup *)animation);
            if ([group removedOnCompletion] && [group activeTimeWithTimeAuthorityLocalTime: [self localTime]] > [group duration] * ([group repeatCount] + 1) * ([group autoreverses] ? 2 : 1))
            {
                /* FIXME: doesn't take into account speed */
                NSLog(@"group animation will remove");
                [animationKeysToRemove addObject: animationKey];
                continue; /* Prevents animation from applying for one frame longer than its duration */
            }
            [group applyToLayer:self];
        }
    }
    [animationKeys release];
    
    if ([[self modelLayer] superlayer] != nil) {
        NSArray *animationsToRemove = [_animations objectsForKeys:animationKeysToRemove notFoundMarker:[NSNull null]];
        
        [_animations removeObjectsForKeys: animationKeysToRemove];
        [_animationKeys removeObjectsInArray: animationKeysToRemove];
        
        if (animationsToRemove.count > 0) {
            [[self modelLayer] addFinishedAnimations:animationsToRemove];
        }
    }
    [animationKeysToRemove release];

  return lowestNextFrameTime;
}

- (void)addFinishedAnimations:(NSArray *)animations
{
    [_finishedAnimations addObjectsFromArray:animations];
}

- (void)notifyAnimationsCancelled:(NSArray *)animations
{
    [self notifyAnimationsStopped:animations finished:NO];
}

// should called in main thead
- (void)callAnimationsFinishedCallbackInMainThread
{
    @try {
        [[CARenderer layerDisplayLock] lock];
        [self callAnimationsFinishedCallback];
    }
    @finally {
        [[CARenderer layerDisplayLock] unlock];
    }
}

- (BOOL)_hasFinishedAnimation
{
    if (_finishedAnimations.count > 0) {
        return YES;
    }
    
    BOOL sublayersHasAnimation = NO;
    if (self.sublayers.count == 0) {
        return sublayersHasAnimation;
    }
    
    NSArray *sublayers = [self.sublayers copy];
    for (CALayer *subLayer in sublayers) {
        if ([subLayer _hasFinishedAnimation]) {
            sublayersHasAnimation = YES;
            break;
        }
    }
    [sublayers release];
    
    return sublayersHasAnimation;
}

- (void)callAnimationsFinishedCallback
{
    [self notifyAnimationsStopped:_finishedAnimations finished:YES];

    [_finishedAnimations removeAllObjects];
    
    NSArray *sublayers = [self.sublayers copy];
    for (CALayer *subLayer in sublayers) {
        [subLayer callAnimationsFinishedCallback];
    }
    [sublayers release];
    
    if (self.mask) {
        [self.mask callAnimationsFinishedCallback];
    }
}

- (void)notifyAnimationsStopped:(NSArray *)animations finished:(BOOL)finished
{
    for (NSInteger i = 0; i<animations.count; ++i) {
        CAAnimation *animation = [animations objectAtIndex:i];
        if (animation.delegate && [animation.delegate respondsToSelector:@selector(animationDidStop:finished:)]) {
            [_animationFinishCallbackNestingSequencer invokeTarget:animation.delegate
                                                            method:@selector(animationDidStop:finished:)
                                                            params:@[animation, @(finished)]];
        }
    }
}

/* ***************** */
/* MARK: - Sublayers */
- (void) addSublayer: (CALayer *)layer
{
    if (layer == nil) {return;}
    
    // is better to call [layer removeFromSuperlayer]?
    if (layer.superlayer&& layer.superlayer != self) {
        NSMutableArray * mutableSublayersOfSuperlayer = (NSMutableArray*)[[layer superlayer] sublayers];
        [mutableSublayersOfSuperlayer removeObject:layer];
    }
    
  NSMutableArray * mutableSublayers = (NSMutableArray*)_sublayers;
    if ([mutableSublayers containsObject:layer]) {
        [mutableSublayers removeObject:layer];
    }
  
  [mutableSublayers addObject: layer];
  [layer setSuperlayer: self];
    
    [self setNeedsLayout];
}

- (void)removeFromSuperlayer
{
  NSMutableArray * mutableSublayersOfSuperlayer = (NSMutableArray*)[[self superlayer] sublayers];
    
    [self _forceFinishAllAnimationAndCallback];
  [mutableSublayersOfSuperlayer removeObject: self];
  [self setSuperlayer: nil];
  [self setNeedsLayout];
}

- (void)_forceFinishAllAnimationAndCallback
{
    if (_animations.count > 0 || _finishedAnimations.count > 0) {
        NSMutableArray *allAnimations = [[NSMutableArray alloc] init];
        [allAnimations addObjectsFromArray:[_animations allValues]];
        [allAnimations addObjectsFromArray:_finishedAnimations];
        
        [self notifyAnimationsStopped:allAnimations finished:YES];
        [allAnimations release];
        
        [_animations removeAllObjects];
        [_animationKeys removeAllObjects];
        [_finishedAnimations removeAllObjects];
    }
    NSArray *sublayers = [self.sublayers copy];
    for (CALayer *subLayer in sublayers) {
        [subLayer _forceFinishAllAnimationAndCallback];
    }
    [sublayers release];
    
    if (self.mask) {
        [self.mask _forceFinishAllAnimationAndCallback];
    }
}

- (void) insertSublayer: (CALayer *)layer atIndex: (unsigned)index
{
    if (layer == nil) {return;}
    
  NSMutableArray * mutableSublayers = (NSMutableArray*)_sublayers;
    
    if ([mutableSublayers containsObject:layer]) {
        [mutableSublayers removeObject:layer];
    }
  
    if (index > mutableSublayers.count) {
        [mutableSublayers addObject:layer];
    } else {
        [mutableSublayers insertObject: layer atIndex: index];
    }
  [layer setSuperlayer: self];
    
    [self setNeedsLayout];
}

- (void) insertSublayer: (CALayer *)layer below: (CALayer *)sibling;
{
    if (layer == nil) {return;}
    
  NSMutableArray * mutableSublayers = (NSMutableArray*)_sublayers;
    if ([mutableSublayers containsObject:layer]) {
        [mutableSublayers removeObject:layer];
    }

  NSUInteger siblingIndex = [mutableSublayers indexOfObject: sibling];
    if (siblingIndex == NSNotFound) {
        [mutableSublayers addObject:layer];
    } else {
        [mutableSublayers insertObject: layer atIndex:siblingIndex];
    }
  [layer setSuperlayer: self];
    
    [self setNeedsLayout];
}

- (void) insertSublayer: (CALayer *)layer above: (CALayer *)sibling;
{
    if (layer == nil) {return;}
    
  NSMutableArray * mutableSublayers = (NSMutableArray*)_sublayers;
    if ([mutableSublayers containsObject:layer]) {
        [mutableSublayers removeObject:layer];
    }

  NSUInteger siblingIndex = [mutableSublayers indexOfObject: sibling];
    if (siblingIndex == NSNotFound) {
        [mutableSublayers addObject:layer];
    } else {
        [mutableSublayers insertObject: layer atIndex:siblingIndex+1];
    }
  [layer setSuperlayer: self];
    
    [self setNeedsLayout];
}

- (CALayer *) rootLayer
{
  CALayer * layer = self;
  while([layer superlayer])
    layer = [layer superlayer];
  
  return layer;
}

- (NSArray *) allAncestorLayers
{
  /* This could be cached. It could even be updated at 
    -addSublayer: and -insertSublayer:... methods. */
  
  NSMutableArray * allAncestorLayers = [NSMutableArray array];
  
  CALayer * layer = self;
  while([layer superlayer])
    {
      layer = [layer superlayer];
      if (layer)
        [allAncestorLayers addObject: layer];
    }
  
  return allAncestorLayers;
}

- (CALayer *) nextAncestorOf: (CALayer *)layer
{
  if ([[self sublayers] containsObject: layer])
    return self;
    
  for (id i in [self sublayers])
    {
      if ([i nextAncestorOf: layer])
        return i;
    }
  
  return nil;
}

- (CALayer *)lowestCommonAncestorOfLayer:(CALayer *)layer
{
    NSArray *allAncestor = [self allAncestorLayers];
    allAncestor = [allAncestor arrayByAddingObject:self];
    
    CALayer *superLayer = layer;
    while (superLayer) {
        if ([allAncestor containsObject:superLayer]) {
            return superLayer;
        }
        superLayer = [superLayer superlayer];
    }
    return nil;
}

/* ************ */
/* MARK: - Time */
+ (void) setCurrentFrameBeginTime: (CFTimeInterval)frameTime
{
  currentFrameBeginTime = frameTime;
}

- (CFTimeInterval) activeTimeWithTimeAuthorityLocalTime: (CFTimeInterval)timeAuthorityLocalTime
{
  /* Slides */
  CFTimeInterval activeTime = (timeAuthorityLocalTime - [self beginTime]) * [self speed] + [self timeOffset];
  assert(activeTime > 0);

  return activeTime;
}

- (CFTimeInterval) localTimeWithTimeAuthority: (id<CAMediaTiming>)timeAuthority
{
  /* Slides */
  CFTimeInterval timeAuthorityLocalTime = [timeAuthority localTime];
  if (!timeAuthority)
    timeAuthorityLocalTime = currentFrameBeginTime ? currentFrameBeginTime : CACurrentMediaTime();
  
  CFTimeInterval activeTime = [self activeTimeWithTimeAuthorityLocalTime: timeAuthorityLocalTime];
  if (isinf([self duration]))
    return activeTime;
  
  NSInteger k = floor(activeTime / [self duration]);
  CFTimeInterval localTime = activeTime - k * [self duration];
  if ([self autoreverses] && k % 2 == 1)
    {
      localTime = [self duration] - localTime;
    }
    
  return localTime;
}




- (CFTimeInterval) activeTime
{
  /* Slides */
  id<CAMediaTiming> timeAuthority = [self superlayer];
  if (!timeAuthority)
    return [self activeTimeWithTimeAuthorityLocalTime: currentFrameBeginTime ? currentFrameBeginTime : CACurrentMediaTime()];
  else
    return [self activeTimeWithTimeAuthorityLocalTime: [timeAuthority localTime]];
}

- (CFTimeInterval) localTime
{
  id<CAMediaTiming> timeAuthority = [self superlayer];
  return [self localTimeWithTimeAuthority: timeAuthority];
}

- (CFTimeInterval) convertTime: (CFTimeInterval)theTime fromLayer: (CALayer *)layer
{
  if (layer == nil)
    return [self localTime];

  /* Just make use of convertTime:toLayer: instead of reimplementing */
  return [layer convertTime: theTime toLayer: self];
}
- (CFTimeInterval) convertTime: (CFTimeInterval)theTime toLayer: (CALayer *)layer
{
  /* Method used to convert 'activeTime' of self into 'activeTime' 
     of 'layer'. */

  if (layer == self)
    return theTime;

  /* First, convert theTime to the "media time" timespace, the 
     timespace returned by CACurrentMediaTime(). */
     
  /* For self, invert formula in theTime. */
  theTime -= [self timeOffset];
  theTime /= [self speed];
  theTime += [self beginTime];

  NSArray * ancestorLayers = [self allAncestorLayers];
  for (CALayer * l in ancestorLayers)
    {
      /* layer was one of our ancestors? great! */
      if (layer == l)
        return theTime;
      
      /* For each layer, we invert the formula in -activeTime. */
      theTime -= [l timeOffset];
      theTime /= [l speed];
      theTime += [l beginTime];
    }
  
  if (layer == nil)
    {
      /* We were requested time in "media time" timespace. */
      return theTime;
    }
  
  /* Use activeTime/localTime mechanism to convert media time into 
     layer time */
  CFTimeInterval oldFrameBeginTime = currentFrameBeginTime;
  currentFrameBeginTime = theTime;
  theTime = [layer activeTime];
  currentFrameBeginTime = oldFrameBeginTime;
  
  return theTime;
}

/* *************** */
/* MARK: - Actions */

- (BOOL)_isLayerInVisibleTree
{
    CALayer *layer = self;
    while (layer) {
        if ([layer isRootLayer]) {
            return YES;
        }
        layer = layer.superlayer;
    }
    return NO;
}

+ (id<CAAction>) defaultActionForKey: (NSString *)key;
{
  /* It appears that Cocoa implementation returns nil by default. */
  return nil;
}

- (id<CAAction>) actionForKey: (NSString *)key
{
    if (![self _isLayerInVisibleTree]) {
        return nil;
    }
    
  if ([[self delegate] respondsToSelector: @selector(actionForLayer:forKey:)])
    {
      NSObject<CAAction>* returnValue = (NSObject<CAAction>*)[[self delegate] actionForLayer: self forKey: key];
      
      if ([returnValue isKindOfClass: [NSNull class]])
        {
          /* Abort search */
          return nil;
        }
      if (returnValue)
        {
          /* Return the value */
          return returnValue;
        }
      
      /* It's nil? Continue the search */
    }
  
  NSObject<CAAction>* dictValue = [[self actions] objectForKey: key];
  if ([dictValue isKindOfClass: [NSNull class]])
    {
      /* Abort search */
      return nil;
    }
  if (dictValue)
    {
      /* Return the value */
      return dictValue;
    }
  
  /* It's nil? Continue the search */
  
  
  NSDictionary* styleActions = [[self style] objectForKey: @"actions"];
  if (styleActions)
  {
    NSObject<CAAction>* dictValue = [styleActions objectForKey: key];
    
    if ([dictValue isKindOfClass: [NSNull class]])
      {
        /* Abort search */
      return nil;
      }
    if (dictValue)
      {
        /* Return the value */
        return dictValue;
      }
  
    /* It's nil? Continue the search */
  }
  
  /* Before generating an action, let's also see if 
     defaultActionForKey: has an offering to make to us. */
  NSObject<CAAction>* action = (NSObject<CAAction>*)[[self class] defaultActionForKey: key];
    
  if ([action isKindOfClass: [NSNull class]])
    {
      /* Abort search */
      return nil;
    }
  if (action)
    {
      /* Return the value */
      return action;
    }
  /* It's nil? That's it. Now we can only generate our own animation. */

  /***********************/
  
  /* construct new animation */
  CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath: key];
  if ([self isPresentationLayer])
    [animation setFromValue: [self valueForKeyPath: key]];
  else
    [animation setFromValue: [[self presentationLayer] valueForKeyPath: key]];
  return animation;

}

- (id)valueForKeyPath:(NSString *)aKey
{
    NSRange r = [aKey rangeOfString: @"."];
    if (r.length != 0) {
        NSString	*key = [aKey substringToIndex: r.location];
        NSString	*path = [aKey substringFromIndex: NSMaxRange(r)];
        
        id keyValue = [self valueForKey:key];
        if ([keyValue isKindOfClass:[NSValue class]]) {
            NSValue *v = keyValue;
            const char *objCType = [v objCType];
            if (strcmp(objCType, @encode(CATransform3D)) == 0) {
                CATransform3D t = [v CATransform3DValue];
                CAVector3D translation,scale,rotation;
                CATransform3DDecompose(t, &translation, &scale, &rotation);
                
                if ([path isEqualToString:@"rotation"] || [path isEqualToString:@"rotation.z"]) {
                    return @(rotation.z);
                } else if ([path isEqualToString:@"rotation.x"]) {
                    return @(rotation.x);
                } else if ([path isEqualToString:@"rotation.y"]) {
                    return @(rotation.y);
                } else if ([path isEqualToString:@"scale"]) {
                    // average of all three scale
                    return @((scale.x + scale.y + scale.z)/3.0);
                } else if ([path isEqualToString:@"scale.x"]) {
                    return @(scale.x);
                } else if ([path isEqualToString:@"scale.y"]) {
                    return @(scale.y);
                } else if ([path isEqualToString:@"scale.z"]) {
                    return @(scale.z);
                } else if ([path isEqualToString:@"translation"]) {
                    // NSValue of CGSize, x and y
                    CGSize tr = CGSizeMake(translation.x, translation.y);
                    return [NSValue value:&tr withObjCType:@encode(CGSize)];
                } else if ([path isEqualToString:@"translation.x"]) {
                    return @(translation.x);
                } else if ([path isEqualToString:@"translation.y"]) {
                    return @(translation.y);
                } else if ([path isEqualToString:@"translation.z"]) {
                    return @(translation.z);
                }
            }
            else if (strcmp(objCType, @encode(CGPoint)) ==0 ||
                     strcmp(objCType, @encode(NSPoint)) ==0) { //Foundation doesn't support CGPoint
                CGPoint p;
                [v getValue:&p];
                
                if ([path isEqualToString:@"x"]) {
                    return @(p.x);
                } else if ([path isEqualToString:@"y"]) {
                    return @(p.y);
                }
                
            } else if (strcmp(objCType, @encode(CGSize)) == 0) {
                CGSize size;
                [v getValue:&size];
                
                if ([path isEqualToString:@"width"]) {
                    return @(size.width);
                } else if ([path isEqualToString:@"height"]) {
                    return @(size.height);
                }
                
            } else if (strcmp(objCType, @encode(CGRect)) == 0) {
                CGRect rect;
                [v getValue:&rect];
                
                if ([path isEqualToString:@"origin"]) {
                    return [NSValue valueWithBytes:&rect.origin objCType:@encode(CGPoint)];
                }  else if ([path isEqualToString:@"origin.x"]) {
                    return @(rect.origin.x);
                } else if ([path isEqualToString:@"origin.y"]) {
                    return @(rect.origin.y);
                } else if ([path isEqualToString:@"size"]) {
                    return [NSValue valueWithBytes:&rect.size objCType:@encode(CGSize)];
                } else if ([path isEqualToString:@"size.width"]) {
                    return @(rect.size.width);
                } else if ([path isEqualToString:@"size.height"]) {
                    return @(rect.size.height);
                }
            } else {
                NSLog(@"unknow objCType:%s",objCType);
            }
            
        }
    }
    
    return [super valueForKeyPath:aKey];
}

- (void)setValue:(id)anObject forKeyPath:(NSString *)aKey
{
    NSRange r = [aKey rangeOfString: @"."];
    if (r.length != 0) {
        NSString	*key = [aKey substringToIndex: r.location];
        NSString	*path = [aKey substringFromIndex: NSMaxRange(r)];
        id keyValue = [self valueForKey:key];
        if ([keyValue isKindOfClass:[NSValue class]]) {
            NSValue *v = keyValue;
            const char *objCType = [v objCType];

            NSValue *finalValue = nil;
            if (strcmp(objCType, @encode(CATransform3D)) == 0) {
                CATransform3D t = [v CATransform3DValue];
                CAVector3D translation,scale,rotation;
                CATransform3DDecompose(t, &translation, &scale, &rotation);
                
                if ([path isEqualToString:@"rotation"] || [path isEqualToString:@"rotation.z"]) {
                    rotation.z = [anObject floatValue];
                } else if ([path isEqualToString:@"rotation.x"]) {
                    rotation.x = [anObject floatValue];
                } else if ([path isEqualToString:@"rotation.y"]) {
                    rotation.y = [anObject floatValue];
                } else if ([path isEqualToString:@"scale"]) {
                    // average of all three scale
                    scale.x = [anObject floatValue];
                    scale.y = [anObject floatValue];
                    scale.z = [anObject floatValue];
                } else if ([path isEqualToString:@"scale.x"]) {
                    scale.x = [anObject floatValue];
                } else if ([path isEqualToString:@"scale.y"]) {
                    scale.y = [anObject floatValue];
                } else if ([path isEqualToString:@"scale.z"]) {
                    scale.z = [anObject floatValue];
                } else if ([path isEqualToString:@"translation"]) {
                    // NSValue of CGSize, x and y
                    CGSize tr; [anObject getValue:&tr]; // = / CGSizeMake(t.m41, t.m42);
                    translation.x = tr.width;
                    translation.y = tr.height;
                } else if ([path isEqualToString:@"translation.x"]) {
                    translation.x = [anObject floatValue];
                } else if ([path isEqualToString:@"translation.y"]) {
                    translation.y = [anObject floatValue];
                } else if ([path isEqualToString:@"translation.z"]) {
                    translation.z = [anObject floatValue];
                } else {
                    return [super setValue:anObject forKeyPath:aKey];
                }
                
                CATransform3D mt = CATransform3DCompose(translation, scale, rotation);
                finalValue = [NSValue valueWithCATransform3D:mt];
            }
            else if (strcmp(objCType, @encode(CGPoint)) == 0 ||
                     strcmp(objCType, @encode(NSPoint)) == 0) {
                CGPoint p;
                [v getValue:&p];
                
                if ([path isEqualToString:@"x"]) {
                    p.x = [anObject floatValue];
                } else if ([path isEqualToString:@"y"]) {
                    p.y = [anObject floatValue];
                } else {
                    return [super setValue:anObject forKeyPath:aKey];
                }
                
                finalValue = [NSValue value:&p withObjCType:@encode(CGPoint)];
            } else if (strcmp(objCType, @encode(CGSize)) == 0) {
                CGSize size;
                [v getValue:&size];
                
                if ([path isEqualToString:@"width"]) {
                    size.width = [anObject floatValue];
                } else if ([path isEqualToString:@"height"]) {
                    size.height = [anObject floatValue];
                } else {
                    return [super setValue:anObject forKeyPath:aKey];
                }
                
                finalValue = [NSValue value:&size withObjCType:@encode(CGSize)];
            } else if (strcmp(objCType, @encode(CGRect)) == 0) {
                CGRect rect;
                [v getValue:&rect];
                
                if ([path isEqualToString:@"origin"]) {
                    CGPoint origin; [anObject getValue:&origin];
                    rect.origin = origin;
                }  else if ([path isEqualToString:@"origin.x"]) {
                    rect.origin.x = [anObject floatValue];
                } else if ([path isEqualToString:@"origin.y"]) {
                    rect.origin.y = [anObject floatValue];
                } else if ([path isEqualToString:@"size"]) {
                    CGSize size; [anObject getValue:&size];
                    rect.size = size;
                } else if ([path isEqualToString:@"size.width"]) {
                    rect.size.width = [anObject floatValue];
                } else if ([path isEqualToString:@"size.height"]) {
                    rect.size.height = [anObject floatValue];
                } else {
                    return [super setValue:anObject forKeyPath:aKey];
                }
                finalValue = [NSValue value:&rect withObjCType:@encode(CGRect)];

            } else{
                NSLog(@"Unknow objCType:%s",objCType);
            }
            
            if (finalValue) {
                return [self setValue:finalValue forKey:key];
            }

        }
    }

    [super setValue:anObject forKeyPath:aKey];
}

- (id)valueForUndefinedKey: (NSString *)key
{
  /* Core Graphics types apparently are not KVC-compliant under Cocoa. */
  
  if ([key isEqualToString: @"backgroundColor"])
    {
      return (id)[self backgroundColor];
    }
  if ([key isEqualToString: @"shadowColor"])
    {
      return (id)[self shadowColor];
    }
  if ([key isEqualToString: @"shadowPath"])
    {
      return (id)[self shadowColor];
    }
    if ([key isEqualToString: @"borderColor"])
    {
        return (id)[self borderColor];
    }
  return [super valueForUndefinedKey: key];
}

- (void)setValue: (id)value
 forUndefinedKey: (NSString *)key
{
  /* Core Graphics types apparently are not KVC-compliant under Cocoa. */
  
  if ([key isEqualToString: @"backgroundColor"])
    {
      [self setBackgroundColor: (CGColorRef)value];
      return;
    }
  if ([key isEqualToString: @"shadowColor"])
    {
      [self setShadowColor: (CGColorRef)value];
      return;
    }
  if ([key isEqualToString: @"shadowPath"])
    {
      [self setShadowPath: (CGPathRef)value];
      return;
    }
    if ([key isEqualToString: @"borderColor"])
    {
        [self setBorderColor: (CGColorRef)value];
        return;
    }
    
  [super setValue: value forUndefinedKey: key];
}

#pragma mark - Point Convert

- (CGPoint)anchorPosition
{
    return CGPointMake(self.anchorPoint.x * self.bounds.size.width,
                       self.anchorPoint.y * self.bounds.size.height);
}

- (CATransform3D)anchor_TransformationToSuperlayer
{
    CALayer *superlayer = self.superlayer;
    
    if (!superlayer) return CATransform3DIdentity;
    
    // position of superlayer's anchor point, in view coordinate
    CGPoint parentAnchorPosition = [superlayer anchorPosition];
    
    // layer position in superlayer's anchor-coordinate
    CGPoint anchorOffset = CGPointMake(self.position.x - parentAnchorPosition.x,
                                       self.position.y - parentAnchorPosition.y);
    
    // concat order: bounds_translate <- transform <- sublayerTransform <- anchor_translate
    CATransform3D boundsTranslate = CATransform3DMakeTranslation(-self.bounds.origin.x,-self.bounds.origin.y, 0);
    CATransform3D localeTransform = CATransform3DConcat(boundsTranslate, self.transform);

    CATransform3D anchorTranslate = CATransform3DMakeTranslation(anchorOffset.x, anchorOffset.y, 0);
    CATransform3D parentTransform = CATransform3DConcat(superlayer.sublayerTransform, anchorTranslate);
    
    CATransform3D toSuperlayerTransform = CATransform3DConcat(localeTransform, parentTransform);

    return toSuperlayerTransform;
}

- (CATransform3D)anchor_TransformationFromSuperLayer
{
    CATransform3D inverse = CATransform3DInvert([self anchor_TransformationToSuperlayer]);
    return inverse;
}

- (CATransform3D)anchor_TransformationToScreenSpace
{
    CATransform3D t = [self anchor_TransformationToSuperlayer];
    for (CALayer *l = self.superlayer; l != nil; l= l.superlayer) {
        t = CATransform3DConcat(t, [l anchor_TransformationToSuperlayer]);
    }
    
    return t;
}

- (CATransform3D)anchor_TransformationFromScreenSpace
{
    return CATransform3DInvert([self anchor_TransformationToScreenSpace]);
}

- (CATransform3D)anchor_TransformationtoLayer:(CALayer *)layer
{
    CATransform3D t1 = [self anchor_TransformationToScreenSpace];
    CATransform3D t2 = [layer anchor_TransformationFromScreenSpace];
    
    CATransform3D t = CATransform3DConcat(t1, t2);
    
    return t;
}

- (CGPoint)convertPoint:(CGPoint)p fromLayer:(CALayer *)l
{
    return [l convertPoint:p toLayer:self];
}

- (CGPoint)convertPoint:(CGPoint)p toLayer:(CALayer *)l
{
    // p is in view coordinate, convert it to anchor coordinate
    CGPoint fromAnchorTranslate = [self anchorPosition];
    CGPoint anchor_coord_point = CGPointMake(p.x - fromAnchorTranslate.x,
                                             p.y - fromAnchorTranslate.y);
    
    // get transform
    CATransform3D anchorTransform = [self anchor_TransformationtoLayer:l];
    CGAffineTransform anchorAffineTransform = CATransform3DGetAffineTransform(anchorTransform);
    
    // convert anchor-coordinate point to destination layer
    CGPoint anchorDestPoint = CGPointApplyAffineTransform(anchor_coord_point, anchorAffineTransform);
    
    // convert anchor-coordinate point to view coordinate
    CGPoint destAnchorTranslate = [l anchorPosition];
    CGPoint result = CGPointMake(anchorDestPoint.x + destAnchorTranslate.x,
                                 anchorDestPoint.y + destAnchorTranslate.y);
    
    return result;
}

- (CGRect)convertRect:(CGRect)r fromLayer:(CALayer *)l
{
    return [l convertRect:r toLayer:self];
}

- (CGRect)convertRect:(CGRect)r toLayer:(CALayer *)l
{
    // r is in view coordinate, convert it to anchor coordinate
    CGPoint fromAnchorTranslate = [self anchorPosition];
    CGRect anchor_coord_rect = CGRectOffset(r, -fromAnchorTranslate.x, -fromAnchorTranslate.y);
    
    // get transform
    CATransform3D anchorTransform = [self anchor_TransformationtoLayer:l];
    CGAffineTransform anchorAffineTransform = CATransform3DGetAffineTransform(anchorTransform);
    
    // convert anchor-coordinate rect to destination layer
    CGRect converted_anchor_rect = CGRectApplyAffineTransform(anchor_coord_rect, anchorAffineTransform);
    
    // convert anchor-coordinate rect to view coordinate
    CGPoint destAnchorTranslate = [l anchorPosition];
    CGRect result = CGRectOffset(converted_anchor_rect, destAnchorTranslate.x, destAnchorTranslate.y);
    return result;
}

#pragma mark -
/* TODO:
 * -setSublayers: needs to correctly unset superlayer from old values and set new superlayer for new values.
 */
- (void)renderInContext:(CGContextRef)ctx
{
    
}

- (CGAffineTransform)affineTransform
{
    return CATransform3DGetAffineTransform(self.transform);
}

- (void)setAffineTransform:(CGAffineTransform)m
{
    self.transform = CATransform3DMakeAffineTransform(m);
}

- (void)markDirty
{
    self.dirty = YES;
}

- (BOOL)hasAnimations
{
    return (self.animations.count > 0);
}

- (void)resetPresentationLayerIfNeeds
{
    if ([self hasAnimations]) {
        [self discardPresentationLayer];
    }
}

#pragma mark - commit
- (CALayer *)copyRenderLayer:(CATransaction *)transaction
{
    CALayer *copy = [[[self class] alloc] initWithLayer:self];
    [copy setModelLayer:self];
    [copy setType:CALayerRenderingType];
    if (self.mask) {
        [copy setMask:[self.mask copyRenderLayer:transaction]];
    }
    self.renderingLayer = copy;
    
    NSArray *subLayers = [self.sublayers copy];
    NSMutableArray *subRenderLayers = [NSMutableArray array];
    for (CALayer *subLayer in subLayers) {
        CALayer *subRenderLayer = [subLayer copyRenderLayer:transaction];
        subRenderLayer.superlayer = copy;
        [subRenderLayers addObject:subRenderLayer];
        [subRenderLayer release];
    }
    [subLayers release];
    copy.sublayers = subRenderLayers;
    
    return copy;
}

- (void)commitIfNeeds:(CATransaction *)transaction
{
    
}
@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
