/* 
   CARenderer.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vučica <ivan@vucica.net>
   Date: March 2012

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
#import "QuartzCore/CARenderer.h"
#import "QuartzCore/CATransform3D.h"
#import "QuartzCore/CATransform3D_Private.h"
#import "QuartzCore/CALayer.h"
#import "CALayer.h"
#import "CALayer+FrameworkPrivate.h"
#import "CATransaction+FrameworkPrivate.h"
#import "CABackingStore.h"
#import "CAMovieLayer.h"
#import "CALayer+Texture.h"
#import "CALayer+CARender.h"

#if defined (__APPLE__)
#   if TARGET_OS_IPHONE
#   import <OpenGLES/ES2/gl.h>
#   import <OpenGLES/ES2/glext.h>
#   else
#   import <OpenGL/OpenGL.h>
#   import <OpenGL/gl.h>
#   import <OpenGL/glu.h>
#   endif
#elif defined(ANDROID)
#import <GLES2/gl2.h>
#import <GLES2/gl2ext.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#else
#define GL_GLEXT_PROTOTYPES 1
#import <GL/gl.h>
#import <GL/glu.h>
#import <GL/glext.h>
#endif

#if defined(ANDROID) || defined(TARGET_OS_IPHONE)
#import <OpenGLES/EAGL.h>
#else
#import <AppKit/NSOpenGL.h>
#endif

#import "GLHelpers/CAGLTexture.h"
#import "GLHelpers/CAGLSimpleFramebuffer.h"
#import "GLHelpers/CAGLShader.h"
#import "GLHelpers/CAGLProgram.h"

#if GNUSTEP
#import <CoreGraphics/CoreGraphics.h>
#endif

#import "CATextureLoader.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

typedef NS_ENUM(GLint, CAVertexAttrib)
{
    CAVertexAttribPosition,
    CAVertexAttribNormal,
    CAVertexAttribColor,
    CAVertexAttribTexCoord0,
    CAVertexAttribTexCoord1
};


@interface CARenderer()
#if ANDROID || TARGET_OS_IPHONE
@property (assign) EAGLContext *GLContext;
- (id) initWithEAGLContext:(EAGLContext *)ctx options: (NSDictionary *)options;
#else
@property (assign) NSOpenGLContext *GLContext;
- (id) initWithNSOpenGLContext: (NSOpenGLContext*)ctx
                       options: options;

#endif
- (void) _determineAndScheduleRasterizationForLayer: (CALayer *) layer;
- (void) _scheduleRasterization: (CALayer *) layer;
- (void) _rasterize: (NSDictionary *) rasterizationSpec;
- (void) _rasterizeAll;
- (void) _updateLayer: (CALayer *)layer
               atTime: (CFTimeInterval)theTime;
- (void) _renderLayer: (CALayer *)layer
        withTransform: (CATransform3D)transform;
@end

@implementation CARenderer {
    CATransform3D _modelViewProjectionMatrix;
    CATransform3D _projectionMatrix;

    GLuint _normalSolt;
    GLuint _projectionUniform;
    GLuint _texture_2dUniform;
    GLuint _textureFlagUniform;

    GLuint _videoProjectionUniform;

    NSMutableArray *_callTimeArray;
    
    CATextureLoader *_textureLoader;
    
    CAGLProgram *_videoProgram;
    GLuint _stencilMaskDepth;
}
@synthesize layer=_layer;
@synthesize bounds=_bounds;

@synthesize GLContext=_GLContext;

#define PROFILE_ENABLE 0
#if PROFILE_ENABLE
#define PROFILE_METHOD_INIT clock_t start,end;double usage=0.0f
#define PROFILE_BEGIN start = clock()
#define PROFILE_END(x) end = clock();usage = (end-start)/(double)CLOCKS_PER_SEC;[_callTimeArray addObject:@[(x),@(usage)]]
#else
#define PROFILE_METHOD_INIT do {} while(0)
#define PROFILE_BEGIN do {} while(0)
#define PROFILE_END(x) do {} while(0)

#endif

/* *** class methods *** */
/* Creates a renderer which renders into an OpenGL context. */
#if ANDROID || TARGET_OS_IPHONE
+ (CARenderer *)rendererWithEAGLContext:(EAGLContext *)context options:(NSDictionary *)options
{
    return [[[self alloc] initWithEAGLContext: context
                                      options: options] autorelease];
    
}
#else
+ (CARenderer*) rendererWithNSOpenGLContext: (NSOpenGLContext*)ctx
                                    options: (NSDictionary*)options;
{
  return [[[self alloc] initWithNSOpenGLContext: ctx 
	                                options: options] autorelease];
}

#endif

/* *** methods *** */
#if ANDROID || TARGET_OS_IPHONE
- (id) initWithEAGLContext:(EAGLContext *)ctx options: (NSDictionary *)options
#else
- (id) initWithNSOpenGLContext: (NSOpenGLContext*)ctx
                       options: options
#endif
{
  if ((self = [super init]) != nil)
    {
      [self setGLContext: ctx];
      
        _textureLoader = [[CATextureLoader alloc] init];
        
      /* SHADER SETUP */
#ifdef ANDROID
        [EAGLContext setCurrentContext:ctx];
#else
        [ctx makeCurrentContext];
#endif
        
        [self _setupGL];
        
#if __OPENGL_ES__
        
        
#endif
    }
  return self;
}

- (void) dealloc
{
  [_layer release];
  [_rasterizationSchedule release];
  
  /* Release all GL programs */
  [_simpleProgram release];
  [_videoProgram release];
  [_blurHorizProgram release];
  [_blurVertProgram release];
  
  [super dealloc];
}

#pragma mark - 
- (void)_setupGL
{
    [self loadShaders];
    
#if __OPENGL_ES__
    glEnableVertexAttribArray(CAVertexAttribPosition);
//    glEnableVertexAttribArray(CAVertexAttribNormal);
//    glVertexAttribPointer(CAVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    glEnableVertexAttribArray(CAVertexAttribColor);
    glEnableVertexAttribArray(CAVertexAttribTexCoord0);
#endif
}

void gl_check_error(NSString *state) {
    GLint err = glGetError();
    if (err != GL_NO_ERROR) {
        NSLog(@"%@ error: %#04x",state, err);
    }
}
#pragma mark Shaders
- (void)loadShaders
{
    // Shader
    
    /* Simple, passthrough shader */
    CAGLVertexShader * simpleVS = [[CAGLVertexShader alloc] initWithSource:[self vertexShaderString]];
    
    CAGLFragmentShader * simpleFS = [[CAGLFragmentShader alloc] initWithSource:[self fragmentShaderString]];
    
    NSArray * basicShaders = [NSArray arrayWithObjects: simpleVS, simpleFS, nil];
    [simpleVS release];
    [simpleFS release];

    
    // Create programs
    // simple program
    CAGLProgram * simpleProgram = [[CAGLProgram alloc] initWithArrayOfShaders:basicShaders];
    [simpleProgram bindAttrib:@"position" toLocation:CAVertexAttribPosition];
    [simpleProgram bindAttrib:@"color" toLocation:CAVertexAttribColor];
    [simpleProgram bindAttrib:@"texturecoord_2d" toLocation:CAVertexAttribTexCoord0];
    [simpleProgram link];
    _simpleProgram = simpleProgram;
    
#if __OPENGL_ES__

    [_simpleProgram use];
    
    // Get uniform locations.
    _projectionUniform = [_simpleProgram locationForUniform:@"modelViewProjectionMatrix"];
    _texture_2dUniform = [_simpleProgram locationForUniform:@"texture_2d"];
    _textureFlagUniform = [_simpleProgram locationForUniform:@"textureFlag"];
#endif
    
    CAGLFragmentShader * GLFS = [[CAGLFragmentShader alloc] initWithSource:[self glFragmentShaderString]];
    
    NSArray *glShaders = [NSArray arrayWithObjects:simpleVS,GLFS,nil];
    
    CAGLProgram * glProgram = [[CAGLProgram alloc] initWithArrayOfShaders:glShaders];
    [glProgram bindAttrib:@"position" toLocation:CAVertexAttribPosition];
    [glProgram bindAttrib:@"color" toLocation:CAVertexAttribColor];
    [glProgram bindAttrib:@"texturecoord_2d" toLocation:CAVertexAttribTexCoord0];
    
    [glProgram link];
    
    _videoProgram = glProgram;
    
    [glProgram use];
    _videoProjectionUniform = [glProgram locationForUniform:@"modelViewProjectionMatrix"];
    
    [_simpleProgram use];
    
    // blur program
    //    NSArray *blurShaders = [self _blurShaders];
    //    CAGLProgram * blurHorizProgram = [CAGLProgram alloc];
    //    blurHorizProgram = [blurHorizProgram initWithArrayOfShaders: blurShaders[0]];
    //    [blurHorizProgram link];
    //    _blurHorizProgram = blurHorizProgram;
    //
    //    CAGLProgram * blurVertProgram = [CAGLProgram alloc];
    //    blurVertProgram = [blurVertProgram initWithArrayOfShaders: blurShaders[1]];
    //    [blurVertProgram link];
    //    _blurVertProgram = blurVertProgram;
}

- (NSString *)glFragmentShaderString
{
    return @"\
    #extension GL_OES_EGL_image_external:require\n\
    precision highp float;\
    \
    uniform samplerExternalOES sTexture;\
    \
    varying vec4 colorVarying;\
    varying mediump vec2 fragmentTextureCoordinates;\
    \
    void main()\
    {\
    gl_FragColor =  texture2D(sTexture, fragmentTextureCoordinates);\
    }\
    ";
}

- (NSString *)vertexShaderString
{
    return @"\
    attribute vec4 position;\
    attribute vec4 color;\
    attribute vec3 normal;\
    attribute vec2 texturecoord_2d;\
    \
    uniform mat4 modelViewProjectionMatrix;\
    varying vec4 colorVarying;\
    varying vec2 fragmentTextureCoordinates;\
    \
    void main()\
    {\
    gl_Position = modelViewProjectionMatrix * position;\
    \
    colorVarying.xyz = normal;\
    colorVarying = color;\
    fragmentTextureCoordinates = texturecoord_2d;\
    }\
    ";
}

- (NSString *)fragmentShaderString
{
    return @"\
    precision highp float;\
    \
    uniform sampler2D texture_2d;\
    uniform lowp float textureFlag;\
    \
    varying vec4 colorVarying;\
    varying mediump vec2 fragmentTextureCoordinates;\
    \
    void main()\
    {\
    gl_FragColor = textureFlag * texture2D(texture_2d, fragmentTextureCoordinates).bgra * colorVarying + (1.0 - textureFlag) * colorVarying;\
    }\
    ";
}


- (NSArray *)_blurShaders
{
/* Horizontal and vertical blur shader */
//    CAGLVertexShader * blurBaseVS = [CAGLVertexShader alloc];
//    blurBaseVS = [blurBaseVS initWithFile: @"blurbase"
//                                   ofType: @"vsh"];
//    CAGLFragmentShader * blurHorizFS = [CAGLFragmentShader alloc];
//    blurHorizFS = [blurHorizFS initWithFile: @"blurhoriz"
//                                     ofType: @"fsh"];
//    CAGLFragmentShader * blurVertFS = [CAGLFragmentShader alloc];
//    blurVertFS = [blurVertFS initWithFile: @"blurvert"
//                                   ofType: @"fsh"];
//    NSArray * objectsForBlurHorizShader = [NSArray arrayWithObjects: blurBaseVS, blurHorizFS, nil];
//    NSArray * objectsForBlurVertShader = [NSArray arrayWithObjects: blurBaseVS, blurVertFS, nil];
//    [blurBaseVS release];
//    [blurHorizFS release];
//    [blurVertFS release];
//    return @[objectsForBlurHorizShader,objectsForBlurVertShader]

    return @[];
}

- (void)setBounds: (CGRect)bounds
{
  _bounds = bounds;
  
  /* This value is returned from -updateBounds in case nothing has changed */
  _updateBounds = CGRectMake(__builtin_inf(), __builtin_inf(), 0, 0);
  
  [self addUpdateRect: bounds];
}
/* Adds a rectangle to the update region. */
- (void) addUpdateRect: (CGRect)updateRect
{
  if(isinf(_updateBounds.origin.x) && isinf(_updateBounds.origin.y))
    _updateBounds = updateRect;
  else
    _updateBounds = CGRectUnion(_updateBounds, updateRect);
}

static CARenderer *_currentRenderr = nil;
+ (CARenderer *)currentRenderer
{
    return _currentRenderr;
}

+ (void)setCurrentRenderer:(CARenderer *)renderer
{
    _currentRenderr = renderer;
}

- (EAGLContext *)context
{
    return _GLContext;
}
/* Begins rendering a frame at the specified time.
   Timestamp is currently ignored. */
- (void) beginFrameAtTime: (CFTimeInterval)timeInterval
                timeStamp: (CVTimeStamp *)timeStamp
{
#if PROFILE_ENABLE
    _callTimeArray = [[NSMutableArray alloc] init];
#endif
    PROFILE_METHOD_INIT;
    
    PROFILE_BEGIN;
  if (!_firstRender)
    {
      _firstRender = timeInterval;
    }
  _nextFrameTime = __builtin_inf();
  
  /* Prepare for rasterization */
  [_rasterizationSchedule release];
  _rasterizationSchedule = [[NSMutableArray alloc] init];
    PROFILE_END(@"beginFrame Init");
    PROFILE_BEGIN;
  /* Update layers (including determining and scheduling rasterization) */
  [self _updateLayer: _layer atTime: timeInterval];
    PROFILE_END(@"beginFrame Update");
  
}

/* Ends rendering the frame, releasing any temporary data. */
- (void) endFrame
{
  /* This value is returned from -updateBounds in case nothing has changed */
  _updateBounds = CGRectMake(__builtin_inf(), __builtin_inf(), 0, 0);

  _previousFrameWasANoop = isinf(_nextFrameTime);
    
#if PROFILE_ENABLE
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (NSArray *record in _callTimeArray) {
        NSString *name = record[0];
        NSNumber *time = record[1];
        NSNumber *value = result[name];
        if (value) {
            value = @([value doubleValue] + [time doubleValue]);
        } else {
            value = time;
        }
        
        result[name] = value;
    }
    
    NSMutableDictionary *count = [NSMutableDictionary dictionary];
    for (NSArray *record in _callTimeArray) {
        NSString *name = record[0];
        NSNumber *value = count[name];
        if (value) {
            value = @([value integerValue] + 1);
        } else {
            value = @1;
        }
        
        count[name] = value;
    }
    
    
    NSArray *keys = [result keysSortedByValueUsingSelector:@selector(compare:)];
    for (NSString *key in keys) {
        double funcUsage = [result[key] doubleValue];
        NSInteger funcCount = [count[key] integerValue];
        NSLog(@"func: %@, time:%.8fs count:%d funcAvgUsage:%.8f",key ,funcUsage,funcCount,funcUsage/funcCount);
    }

    [_callTimeArray release];
    _callTimeArray = nil;
#endif
}
/* Returns time at which next update should be performed.
   Current time denotes continuous animation and next update
   should be scheduled as soon as appropriate. Infinity denotes
   that no update should be scheduled. */
- (CFTimeInterval) nextFrameTime
{
  return _nextFrameTime;
}

- (void)recursionLayoutLayerIfNeeded:(CALayer *)layer
{
    [layer layoutIfNeeded];
    
    for (CALayer *sublayer in layer.sublayers) {
        [self recursionLayoutLayerIfNeeded:sublayer];
    }
}

/* Renders a frame to the target context. Best case scenario, it 
   should be rendering the update region only. */
#if __OPENGL_ES__
- (void)render
{
#if PROFILE_ENABLE
    NSDate *begin = [NSDate date];
#endif
    
    /* If we have nothing to render, just skip rendering */
    CGRect updateBounds = [self updateBounds];
    if (isinf(updateBounds.origin.x) &&
        isinf(updateBounds.origin.y))
        return;

#ifdef ANDROID
    [EAGLContext setCurrentContext:_GLContext];
#else
    [_GLContext makeCurrentContext];
#endif

    glViewport(0, 0, _bounds.size.width, _bounds.size.height);
    
    _projectionMatrix = CATransform3DMakeOrtho(0, _bounds.size.width, 0, _bounds.size.height, -1024, 1024);
    
//    CATransform3D modelViewMatrix = CATransform3DIdentity;
//    _modelViewProjectionMatrix = CATransform3DMultiply(projectionMatrix, modelViewMatrix);

    
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT| GL_DEPTH_BUFFER_BIT);
    
    // reset stencil buffer
    glEnable(GL_STENCIL_TEST);
    glStencilMask(0xFF);
    glClear(GL_STENCIL_BUFFER_BIT);
    _stencilMaskDepth = 0;

    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    [self _rasterizeAll];
    
    /* Perform render */
    
    // flip coordinate
    CATransform3D transform = CATransform3DMakeScale(1, -1, 1);
    transform = CATransform3DTranslate(transform, 0, -_bounds.size.height, 0);
    
#if PROFILE_ENABLE
    NSDate *callBegin = [NSDate date];
#endif
    [self _renderLayer: [self layer]
         withTransform: transform];
#if PROFILE_ENABLE
    NSTimeInterval callUsage = -[callBegin timeIntervalSinceNow];
#endif
    
    /* Restore defaults */
    glClearColor(0.0, 0.0, 0.0, 0.0);
    glDisable(GL_BLEND);
    glDisable(GL_STENCIL_TEST);
    glBlendFunc(GL_ONE, GL_ZERO);
    glUniformMatrix4fv(_projectionUniform, 1, 0, &_projectionMatrix);

#if PROFILE_ENABLE
    NSTimeInterval usage = -[begin timeIntervalSinceNow];
    
    NSLog(@"Frame Usage: %.2fs _renderLayer %.2f%%",usage, callUsage/usage*100.0);
#endif
}
#else /* OPENGL */
- (void) render
{
  /* If we have nothing to render, just skip rendering */
  CGRect updateBounds = [self updateBounds];
  if (isinf(updateBounds.origin.x) &&
      isinf(updateBounds.origin.y))
    return;

  [_GLContext makeCurrentContext];

  glMatrixMode(GL_MODELVIEW);
  
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_COLOR_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  
  [self _rasterizeAll];
  
  /* Perform render */
  [self _renderLayer: [[self layer] presentationLayer]
       withTransform: CATransform3DIdentity];
       
  /* Restore defaults */
  glMatrixMode(GL_MODELVIEW);
  glClearColor(0.0, 0.0, 0.0, 0.0);
  glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_COLOR_ARRAY);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  glDisable(GL_BLEND);
  glBlendFunc(GL_ONE, GL_ZERO);
  glLoadIdentity();
}
#endif

/* Returns rectangle containing all pixels that should be updated. */
- (CGRect) updateBounds
{
  /* TODO: This one is important to implement, and then make use of,
     in order to keep the number of layers that are rendered to a
     minimum. This is the method Apple seems to use to keep down the
     amount of content rendered upon screen refresh.
     
     https://mail.mozilla.org/pipermail/plugin-futures/2010-March/000023.html

     This quote: "A -render with nothing to do is cheap." leads me to
     believe that -render is actually repeatedly ran, but that it's counted
     on that most often, nothing will be painted. 
     
     Value of -updateBounds is apparently calculated in -beginFrameAtTime:timeStamp:.
     This makes sense and we'll do the same.
     */

  if (isinf(_nextFrameTime) && _previousFrameWasANoop)
    return _updateBounds;

  /* for the time being, we return entire renderer as needing a redraw. */
  return [self bounds];
}

/* *********************** */
/* MARK: - Private methods */

/* Internal method that updates a single presentation layer and then proceeds by recursing, updating its children. */
- (void) _updateLayer: (CALayer *)renderLayer
               atTime: (CFTimeInterval)theTime
{
    PROFILE_METHOD_INIT;
    
    PROFILE_BEGIN;

  [CALayer setCurrentFrameBeginTime: theTime];
    PROFILE_END(@"_updateLayer modelLayer");
    
    PROFILE_BEGIN;
  /* Tell the presentation layer to apply animations. */
  /* Also, determine nextFrameTime */
    CFTimeInterval time = [renderLayer applyAnimationsAtTime: theTime];
  _nextFrameTime = MIN(_nextFrameTime, time);
  _nextFrameTime = MAX(_nextFrameTime, theTime);
    PROFILE_END(@"_updateLayer calcuate nextFrameTime");
    
  /* Tell all children to update themselves. */
    PROFILE_BEGIN;
    NSArray *sublayers = [[renderLayer sublayers] copy];
    PROFILE_END(@"_updateLayer sublayers copy");
  for (CALayer * sublayer in sublayers)
    {
      [self _updateLayer: sublayer
                  atTime: theTime];
    }
    [sublayers release];

  /* Now that children have had a chance to determine
     whether they need to be rendered offscreen, the layer itself
     can determine it, too. */
  /* (Order is important, because the deeper the layer is, earlier
     it needs to be offscreen-rendered.) */
     
  /* TODO: */
  /* First, allow mask layer to determine this, since it's deeper than
     the current layer. */
  #if 0
  [self _determineAndScheduleRasterizationForLayer: [layer mask]];
  #endif
    PROFILE_BEGIN;
  /* Then permit current layer to determine rasterization */
  [self _determineAndScheduleRasterizationForLayer: renderLayer];
    PROFILE_END(@"_updateLayer determineRasterization");
}

void configureColorBuffer(CGFloat *buffer, CGColorRef color, CGFloat opacity)
{
    size_t numberOfComponents = CGColorGetNumberOfComponents(color);
    
    const CGFloat * componentsCG = CGColorGetComponents(color);
    GLfloat components[4] = { 0, 0, 0, 1 };
    
    // convert
    if (numberOfComponents == 2) { // grey + a,
        components[0] = componentsCG[0];
        components[1] = componentsCG[0];
        components[2] = componentsCG[0];
        components[3] = componentsCG[1];
    } else if (numberOfComponents == 4) { // rgb + a
        components[0] = componentsCG[0];
        components[1] = componentsCG[1];
        components[2] = componentsCG[2];
        components[3] = componentsCG[3];
        
    } else if (numberOfComponents == 5) { // cmyk + a
        
        // FIXME: needs convert to rgba
        static BOOL warned = NO;
        if (!warned) {
            NSLog(@"[Warning] color that numberOfComponents == 5 is not correct supported");
            warned = YES;
        }
        components[0] = componentsCG[0];
        components[1] = componentsCG[1];
        components[2] = componentsCG[2];
        components[2] = componentsCG[3];
        
        components[3] = componentsCG[4];
    } else {
        NSLog(@"Expection NumberOfComponents:%zu",numberOfComponents);
    }
    
    //premultiplication, rgb * alpha
    components[0] *= components[3];
    components[1] *= components[3];
    components[2] *= components[3];
    
    // apply opacity
    components[3] *= opacity;
    
    
    // FIXME: here we presume that color contains RGBA channels.
    // However this may depend on colorspace, number of components et al
    memcpy(buffer + 0*4, components, sizeof(GLfloat)*4);
    memcpy(buffer + 1*4, components, sizeof(GLfloat)*4);
    memcpy(buffer + 2*4, components, sizeof(GLfloat)*4);
    memcpy(buffer + 3*4, components, sizeof(GLfloat)*4);
    
}

static CGSize CALayerContentsGetSize(id contents)
{
    if ([contents isKindOfClass:[CABackingStore class]]) {
        CABackingStore *backingStore = contents;
        return CGSizeMake(backingStore.width, backingStore.height);
    }
#if GNUSTEP
    else if ([contents isKindOfClass: NSClassFromString(@"CGImage")])
#else
        else if ([contents isKindOfClass: NSClassFromString(@"__NSCFType")] &&
                 CFGetTypeID(layerContents) == CGImageGetTypeID())
#endif
        {
            CGImageRef image = contents;
            
            CGFloat width = CGImageGetWidth(image);
            CGFloat height = CGImageGetHeight(image);
            return CGSizeMake(width, height);
        }
    
    return CGSizeZero;
}


static CGSize CALayerContentsGetGravitySize(CALayer * layer)
{
    CGSize physicalSizeOfContents = CALayerContentsGetSize(layer.contents);
    CGFloat contentsScale = layer.contentsScale;
    CGSize logicSizeOfContents = CGSizeMake(physicalSizeOfContents.width/contentsScale,
                                            physicalSizeOfContents.height/contentsScale);
    NSString *contentsGravity = layer.contentsGravity;
    CGSize boundsSize = layer.bounds.size;

    CGFloat widthRatio = boundsSize.width / logicSizeOfContents.width;
    CGFloat heightRatio = boundsSize.height / logicSizeOfContents.height;

    if (!contentsGravity || [contentsGravity isEqualToString:kCAGravityResize]) {
        return boundsSize;
    }
    
    if ([contentsGravity isEqualToString:kCAGravityResizeAspect]) {
        CGFloat ratio = MIN(widthRatio, heightRatio);
        return CGSizeMake(logicSizeOfContents.width * ratio,
                          logicSizeOfContents.height * ratio);

    } else if ([contentsGravity isEqualToString:kCAGravityResizeAspectFill]) {
        CGFloat ratio = MAX(widthRatio, heightRatio);
        return CGSizeMake(logicSizeOfContents.width * ratio,
                          logicSizeOfContents.height * ratio);
    }
    
    return logicSizeOfContents;
}

static CGRect CALayerContentsGetGravityRect(CALayer *layer)
{
    // assume origin at top-left, to calc draw rect of texture:
    //  1. calc the size base on gravity
    //  2. then adjust origin base on gravity
    
    CGSize boundsSize = layer.bounds.size;
    NSString *contentsGravity = layer.contentsGravity;
    
    // calc gravity size of contents
    CGSize gravitySize = CALayerContentsGetGravitySize(layer);
    
    CGRect gravityRect = {CGPointZero, gravitySize};
    
    // adjust origin to match gravity
    CGFloat leftX = 0;
    CGFloat centerX = (boundsSize.width - gravityRect.size.width)/2;
    CGFloat rightX = boundsSize.width - gravityRect.size.width;
    
    CGFloat topY = 0;
    CGFloat centerY = (boundsSize.height - gravityRect.size.height)/2;
    CGFloat bottomY = boundsSize.height - gravityRect.size.height;
    
    if ([contentsGravity isEqualToString:kCAGravityResize] || contentsGravity == nil) {
        gravityRect.size = boundsSize;
        gravityRect.origin = CGPointZero;
    } else if ([contentsGravity isEqualToString:kCAGravityCenter]) {
        gravityRect.origin.y = centerY;
        gravityRect.origin.x = centerX;
    } else if ([contentsGravity isEqualToString:kCAGravityTop]) {
        gravityRect.origin.y = topY;
        gravityRect.origin.x = centerX;
    } else if ([contentsGravity isEqualToString:kCAGravityBottom]) {
        gravityRect.origin.y = bottomY;
        gravityRect.origin.x = centerX;
    } else if ([contentsGravity isEqualToString:kCAGravityLeft]) {
        gravityRect.origin.y = centerY;
        gravityRect.origin.x = leftX;
    } else if ([contentsGravity isEqualToString:kCAGravityRight]) {
        gravityRect.origin.y = centerY;
        gravityRect.origin.x = rightX;
    } else if ([contentsGravity isEqualToString:kCAGravityTopLeft]) {
        gravityRect.origin.y = topY;
        gravityRect.origin.x = leftX;
    } else if ([contentsGravity isEqualToString:kCAGravityTopRight]) {
        gravityRect.origin.y = topY;
        gravityRect.origin.x = rightX;
    } else if ([contentsGravity isEqualToString:kCAGravityBottomLeft]) {
        gravityRect.origin.y = bottomY;
        gravityRect.origin.x = leftX;
    } else if ([contentsGravity isEqualToString:kCAGravityBottomRight]) {
        gravityRect.origin.y = bottomY;
        gravityRect.origin.x = rightX;
    } else if ([contentsGravity isEqualToString:kCAGravityResizeAspect]) {
        // position at center
        gravityRect.origin.y = centerY;
        gravityRect.origin.x = centerX;
    } else if ([contentsGravity isEqualToString:kCAGravityResizeAspectFill]) {
        // resize, keep aspect, position at center
        //position at center
        gravityRect.origin.y = centerY;
        gravityRect.origin.x = centerX;
    }
    
    return gravityRect;
}

/* Internal method that renders a single layer and then proceeds by recursing, rendering its children. */

#define GL_TEXTURE_EXTERNAL_OES 0x8D65

#if __OPENGL_ES__
- (void) _renderLayer: (CALayer *)layer
        withTransform: (CATransform3D)transform
{
//    NSLog(@"will render layer %@, position:{%.2f,%.2f} size:{%.2f,%.2f} anchorPoint:{%.2f,%.2f} ",layer,layer.position.x,layer.position.y, layer.bounds.size.width,layer.bounds.size.height,layer.anchorPoint.x,layer.anchorPoint.y);
//    if (!layer.opaque) {
//        glEnable(GL_BLEND);
//        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
//    } else {
//        glDisable(GL_BLEND);
//        glBlendFunc(GL_ONE, GL_ZERO);
//    }
    
    
//    NSDate *allBegin = [NSDate date];
    
//    NSDate *begin = nil;
//    NSTimeInterval usage = 0;
    
//    clock_t start,end;
//    double usage = 0.0f;

    PROFILE_BEGIN;
    PROFILE_END(@"empty profile");
    
    PROFILE_BEGIN;
    if (layer.isHidden || layer.opacity == 0) {
        return;
    }
    PROFILE_END(@"visible checking");

    PROFILE_BEGIN;
    // apply transform and translate to position
    CGPoint layerPosition = [layer position];
    
    transform = CATransform3DTranslate(transform, layerPosition.x, layerPosition.y, 0);
    transform = CATransform3DConcat([layer transform], transform);
    
    _modelViewProjectionMatrix = CATransform3DMultiply(_projectionMatrix, transform);
    glUniformMatrix4fv(_projectionUniform, 1, 0, &_modelViewProjectionMatrix);
    PROFILE_END(@"mvp calcuate");
    
    PROFILE_BEGIN;
    // if the layer was offscreen-rendered, render just the texture
    CAGLTexture * texture = [[layer backingStore] offscreenRenderTexture];
    PROFILE_END(@"offscreenRenderTexture");
    
    if (texture) {
//        glClearColor(0, 1, 0, 1);
//        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        NSLog(@"[WARNING]render texture unimplemented!!");

    } else { // not offscreen-rendered
        PROFILE_BEGIN;
        [layer displayIfNeeded];
        PROFILE_END(@"displayIfNeeded");
        
        PROFILE_BEGIN;
        // fill vertex arrays
        CGRect layerBounds = layer.bounds;
        GLfloat vertices[] = {
            0.0, layerBounds.size.height,
            layerBounds.size.width, layerBounds.size.height,
            0.0, 0.0,
            layerBounds.size.width, 0.0,
        };
        CGRect cr = [layer contentsRect];

        GLfloat texCoords[] = {
            cr.origin.x,                 1.0 - (cr.origin.y),
            cr.origin.x + cr.size.width, 1.0 - (cr.origin.y),
            cr.origin.x,                 1.0 - (cr.origin.y + cr.size.height),
            cr.origin.x + cr.size.width, 1.0 - (cr.origin.y + cr.size.height),
        };
        GLfloat whiteColor[] = {
            1.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 1.0,
        };
        GLfloat backgroundColor[] = {
            1.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 1.0,
        };
        
        // apply anchor point
        for (int i = 0; i < 4; i++)
        {
            vertices[i*2 + 0] -= [layer anchorPoint].x * [layer bounds].size.width;
            vertices[i*2 + 1] -= [layer anchorPoint].y * [layer bounds].size.height;
        }
        
        // apply opacity to white color
        for (int i = 0; i < 4; i++)
        {
            whiteColor[i*4 + 3] *= [layer opacity];
        }
        
//        NSLog(@"will draw arrays");

        
        glVertexAttribPointer(CAVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);
        glVertexAttribPointer(CAVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, texCoords);
        glUniform1f(_textureFlagUniform, 0);

        PROFILE_END(@"vertex prepare");
        
        PROFILE_BEGIN;
        // apply background color
        if ([layer backgroundColor] && CGColorGetAlpha([layer backgroundColor]) > 0)
        {
//            NSLog(@"render with background");
            configureColorBuffer(backgroundColor, layer.backgroundColor, layer.opacity);
            glVertexAttribPointer(CAVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, backgroundColor);
            
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        }
        PROFILE_END(@"draw background");

        
        
        PROFILE_BEGIN;
        
        CATransform3D mvp = _modelViewProjectionMatrix;
        GLuint mask = 0xFF;
        if (layer.masksToBounds) {
            if (_stencilMaskDepth == 0) {
                glEnable(GL_STENCIL_TEST);
                glStencilMask(0xFF);
                glClear(GL_STENCIL_BUFFER_BIT);
            }
            _stencilMaskDepth ++;
            
            glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
            glDepthMask(GL_FALSE);
            
            // incr draw area value
            glStencilFunc(GL_ALWAYS, _stencilMaskDepth, mask);
            glStencilOp(GL_INCR, GL_INCR, GL_INCR);
            glStencilMask(0xFF);
            
            glUniformMatrix4fv(_projectionUniform, 1, 0, &mvp);
            glVertexAttribPointer(CAVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);
            glVertexAttribPointer(CAVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, texCoords);
            glVertexAttribPointer(CAVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, backgroundColor);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            
            glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
            glDepthMask(GL_TRUE);
            glStencilMask(0x00);
            
            glStencilFunc(GL_EQUAL, _stencilMaskDepth, mask);
            glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
            
        }

        // if there are some contents, draw them
        if ([layer contents])
        {
            
//            NSLog(@"rendering contents");
            glUniform1f(_textureFlagUniform, 1);
            
            CGRect vr = CALayerContentsGetGravityRect(layer);
           
            // apply anchor point
            vr = CGRectOffset(vr,
                              -[layer anchorPoint].x * [layer bounds].size.width,
                              -[layer anchorPoint].y * [layer bounds].size.height);
            
            GLfloat contentsVertices[] = {
                CGRectGetMinX(vr),  CGRectGetMaxY(vr),
                 CGRectGetMaxX(vr),  CGRectGetMaxY(vr),
                 CGRectGetMinX(vr),  CGRectGetMinY(vr),
                 CGRectGetMaxX(vr),  CGRectGetMinY(vr),
            };
            
            glVertexAttribPointer(CAVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, contentsVertices);
            
            CAGLTexture * texture = [self _textureToDisplayWithLayer:layer
                                                            vertices:vertices texCoords:texCoords];
            
#if !__OPENGL_ES__
            if ([texture textureTarget] == GL_TEXTURE_RECTANGLE_ARB)
            {
                // Rectangle textures use non-normalized coordinates.
                
                for (int i = 0; i < 4; i++)
                {
                    texCoords[i*2 + 0] *= [texture width];
                    texCoords[i*2 + 1] *= [texture height];
                }
            }
#endif
            if (texture.isInvalidated) {
                NSLog(@"[Warning] rendering a invalidated texture");
            }
            [texture bind];
            CAGLTexture *maskTexture = nil;
            if (layer.mask) {
                maskTexture = [layer.mask maskTextureWithLoader:_textureLoader];
            }
            glVertexAttribPointer(CAVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, whiteColor);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            [texture unbind];
            
            if ([layer isKindOfClass:[CAMovieLayer class]]) {
                [_simpleProgram use];
            }
        }
        PROFILE_END(@"layer contents rendering");
        
        if (layer.borderWidth > 0 && layer.borderColor) {
            glUniform1f(_textureFlagUniform, 0);

            GLfloat borderColor[] = {
                1.0, 1.0, 1.0, 1.0,
                1.0, 1.0, 1.0, 1.0,
                1.0, 1.0, 1.0, 1.0,
                1.0, 1.0, 1.0, 1.0,
            };

            GLfloat borderVertices[8];
            borderVertices[0] = vertices[0];
            borderVertices[1] = vertices[1];
            borderVertices[2] = vertices[2];
            borderVertices[3] = vertices[3];
            borderVertices[4] = vertices[6];
            borderVertices[5] = vertices[7];
            borderVertices[6] = vertices[4];
            borderVertices[7] = vertices[5];
        
            configureColorBuffer(borderColor, layer.borderColor, layer.opacity);
            glLineWidth(layer.borderWidth);
            glVertexAttribPointer(CAVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, borderVertices);
            glVertexAttribPointer(CAVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, borderColor);
            glDrawArrays(GL_LINE_LOOP, 0, 4);
        }
        PROFILE_BEGIN;
        transform = CATransform3DConcat ([layer sublayerTransform], transform);
        transform = CATransform3DTranslate (transform, -layerBounds.origin.x, -layerBounds.origin.y, 0);
        transform = CATransform3DTranslate (transform, -layerBounds.size.width/2, -layerBounds.size.height/2, 0);
        PROFILE_END(@"sublayer transform perpare");
        
        PROFILE_BEGIN;
        NSArray *subLayers = [layer sublayers];
        PROFILE_END(@"subLayers getting");
//        PROFILE_BEGIN;
        subLayers = [subLayers copy];
//        PROFILE_END(@"subLayers copy");
        
#if PROFILE_ENABLE
        NSTimeInterval allTime = -[allBegin timeIntervalSinceNow];
        [_callTimeArray addObject:@[@"RenderLayerWIthTransform",@(allTime)]];
#endif

        
        for (CALayer * sublayer in subLayers)
        {
            [self _renderLayer: sublayer withTransform: transform];
        }
        
        if (layer.masksToBounds) {
            glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
            glDepthMask(GL_FALSE);

            glStencilFunc(GL_ALWAYS, _stencilMaskDepth, mask);
            glStencilOp(GL_DECR, GL_DECR, GL_DECR);
            glStencilMask(0xFF);

            glUniformMatrix4fv(_projectionUniform, 1, 0, &mvp);
            glVertexAttribPointer(CAVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);
            glVertexAttribPointer(CAVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, texCoords);
            glVertexAttribPointer(CAVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, backgroundColor);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

            glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
            glDepthMask(GL_TRUE);
            glStencilMask(0x00);
            
            _stencilMaskDepth --;
            
            glStencilFunc(GL_EQUAL, _stencilMaskDepth, mask);
            glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);

            if (_stencilMaskDepth == 0) {
                glDisable(GL_STENCIL_TEST);
            }
        }
        [subLayers release];
    }
}

- (CAGLTexture *)_textureToDisplayWithLayer:(CALayer *)layer
                                   vertices:(GLfloat *)vertices
                                  texCoords:(GLfloat *)texCoords
{
    CAGLTexture *texture;
    if (layer.mask) {
        texture = nil;
    } else {
        texture = [self _textureOfLayer:layer vertices:vertices texCoords:texCoords];
    }
    return texture;
}

- (CAGLTexture *)_textureOfLayer:(CALayer *)layer
                        vertices:(GLfloat *)vertices
                       texCoords:(GLfloat *)texCoords
{
    CAGLTexture *texture = nil;
    id layerContents = [layer contents];
    
    if ([layer isKindOfClass:[CAMovieLayer class]]) {
        [_videoProgram use];
        
        CAMovieLayer *eglLayer = [layer modelLayer];
        static CATransform3D t;
        [eglLayer updateTextureIfNeeds:&t];
        
        //_modelViewProjectionMatrix = CATransform3DMultiply(_modelViewProjectionMatrix, t);
        glVertexAttribPointer(CAVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);
        
        glUniformMatrix4fv(_videoProjectionUniform, 1, 0, &_modelViewProjectionMatrix);
        glVertexAttribPointer(CAVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, texCoords);
        
        texture = [layer.backingStore contentsTexture];
        
    } else if ([layerContents isKindOfClass: [CABackingStore class]]) {
        
//                NSLog(@"contents is CABackingStore");
        CABackingStore * backingStore = layerContents;
        if (backingStore.needsRefresh) {
            [backingStore refresh];
        }
        texture = [backingStore contentsTexture];
    }
#if GNUSTEP
    else if ([layerContents isKindOfClass: NSClassFromString(@"CGImage")])
#else
    else if ([layerContents isKindOfClass: NSClassFromString(@"__NSCFType")] &&
                     CFGetTypeID(layerContents) == CGImageGetTypeID())
#endif
    {
//          NSLog(@"contents is CGImageRef, load it");
        CGImageRef image = (CGImageRef)layerContents;
        texture = [_textureLoader textureForLayer:layer];
        if (texture.contents == nil) {
            NSLog(@"Texture:load image");
            [texture loadImage: image];
            texture.contents = layerContents;
        }
    } else {
        NSLog(@"UnSupported layerContents:%@",layerContents);
    }
    return texture;
}

#else
- (void) _renderLayer: (CALayer *)layer
        withTransform: (CATransform3D)transform
{
  if (![layer isPresentationLayer])
    layer = [layer presentationLayer];
  
  // apply transform and translate to position
  transform = CATransform3DTranslate(transform, [layer position].x, [layer position].y, 0);
  transform = CATransform3DConcat([layer transform], transform);
#ifndef __OPENGL_ES__
    if (sizeof(transform.m11) == sizeof(GLdouble))
        glLoadMatrixd((GLdouble*)&transform);
    else
#endif

  // if the layer was offscreen-rendered, render just the texture
  CAGLTexture * texture = [[layer backingStore] offscreenRenderTexture];
  if (texture)
    {
      /* have to paint shadow? */
      if ([layer shadowOpacity] > 0.0)
        {
          /* first paint shadow */
          
          /* TODO: we might be able to skip blurring in case radius == 1. */
          /* TODO: shouldRasterize means that shadow should be included in
                   rasterized bitmap. Currently, we still render shadow separately */
          
          /* here, we do blurring in two passes. first horizontal, then vertical. */
          /* IDEA: perform blurring during offscreen-rendering, so we group all
                   FBO operations in once place? */
          
          /* TODO: these not correct sizes for shadow rasterization */
          const GLuint shadow_rasterize_w = 512, shadow_rasterize_h = 512;
          
          CATransform3D shadowRasterizeTransform = CATransform3DMakeTranslation(shadow_rasterize_w/2.0, shadow_rasterize_h/2.0, 0);
          CATransform3D rasterizedTextureTransform = CATransform3DMakeTranslation([texture width]/2.0, [texture height]/2.0, 0);
          
          
          /* Setup transform for first pass */
#if !__OPENGL_ES__
            if (sizeof(rasterizedTextureTransform.m11) == sizeof(GLdouble))
                glLoadMatrixd((GLdouble*)&rasterizedTextureTransform);
            else
#endif
            glLoadMatrixf((GLfloat*)&rasterizedTextureTransform);

          /* Setup FBO for first pass */
          CAGLSimpleFramebuffer * framebuffer = [[CAGLSimpleFramebuffer alloc] initWithWidth: shadow_rasterize_w height: shadow_rasterize_h];
          [framebuffer bind];
          
          glClearColor(0.0, 0.0, 0.0, 0.0);
          glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

          /* Render first pass */
          [_blurHorizProgram use];
          GLint loc = [_blurHorizProgram locationForUniform:@"RTScene"];
          [_blurHorizProgram bindUniformAtLocation: loc
                                     toUnsignedInt: 0];
          
          // TODO: replace use of glBegin()/glEnd()
          [texture bind];
          
          GLfloat textureMaxX = 1.0, textureMaxY = 1.0;
#if !__OPENGL_ES__
            if ([texture textureTarget] == GL_TEXTURE_RECTANGLE_ARB)
            {
                textureMaxX = [texture width];
                textureMaxY = [texture height];
            }
            else
#endif
            {
              glTexParameteri([texture textureTarget], GL_TEXTURE_MIN_FILTER, GL_LINEAR);
              glTexParameteri([texture textureTarget], GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            }
#if __OPENGL_ES__

#else
            glBegin(GL_QUADS);
            glTexCoord2f(0, 0);
            glVertex2f(-[texture width]/2.0, -[texture height]/2.0);
            glTexCoord2f(0, textureMaxY);
            glVertex2f(-[texture width]/2.0, [texture height]/2.0);
            glTexCoord2f(textureMaxX, textureMaxY);
            glVertex2f([texture width]/2.0, [texture height]/2.0);
            glTexCoord2f(textureMaxX, 0);
            glVertex2f([texture width]/2.0, -[texture height]/2.0);
            glEnd();
#endif

          glDisable([texture textureTarget]);
          
          
          glUseProgram(0);

          [texture unbind];
          [framebuffer unbind];
                        
          /* Preserve the FBO texture and discard framebuffer */
          CAGLTexture * firstPassTexture = [[framebuffer texture] retain];
          [framebuffer release];
          
          /************************************/
          
          /* Setup transform for second pass */
#if !__OPENGL_ES__
            if (sizeof(shadowRasterizeTransform.m11) == sizeof(GLdouble))
                glLoadMatrixd((GLdouble*)&shadowRasterizeTransform);
            else
#endif
            glLoadMatrixf((GLfloat*)&shadowRasterizeTransform);
           
          
          /* Setup FBO for second pass */
          framebuffer = [[CAGLSimpleFramebuffer alloc] initWithWidth: shadow_rasterize_w height: shadow_rasterize_h];
          [framebuffer bind];
          
          glDisable([[framebuffer texture] textureTarget]);

          glClearColor(0.0, 0.0, 0.0, 0.0);
          glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

          /* Render second pass */
          [_blurVertProgram use];
          loc = [_blurVertProgram locationForUniform: @"RTBlurH"];
          [_blurVertProgram bindUniformAtLocation: loc
                                     toUnsignedInt: 0];
          loc = [_blurVertProgram locationForUniform: @"shadowColor"];
          GLfloat components[4] = { 0 };
          if (CGColorGetNumberOfComponents([layer shadowColor]) == 4)
            {
              const CGFloat * componentsOrig = CGColorGetComponents([layer shadowColor]);
              components[0] = componentsOrig[0];
              components[1] = componentsOrig[1];
              components[2] = componentsOrig[2];
              components[3] = componentsOrig[3];
              components[3] *= [layer shadowOpacity];
            }
          else if (CGColorGetNumberOfComponents([layer shadowColor]) == 3)
            {
              static BOOL warned = NO;
              if (!warned)
                {
                  NSLog(@"One time warning: possible Opal bug - shadowColor has only 3 components");
                  warned = YES;
                }
              const CGFloat * componentsOrig = CGColorGetComponents([layer shadowColor]);
              components[0] = componentsOrig[0];
              components[1] = componentsOrig[1];
              components[2] = componentsOrig[2];
              components[3] = 1.0;
              components[3] *= [layer shadowOpacity]; 
            }
          else
            {
              NSLog(@"Invalid number of color components in shadowColor");
            }

          [_blurVertProgram bindUniformAtLocation: loc
                                        toFloat4v: components];
                                        
          // TODO: replace use of glBegin()/glEnd()
          [firstPassTexture bind];
          
          GLfloat firstPassTextureMaxX = 1.0, firstPassTextureMaxY = 1.0;
#if !__OPENGL_ES__
            if ([firstPassTexture textureTarget] == GL_TEXTURE_RECTANGLE_ARB)
            {
                firstPassTextureMaxX = [firstPassTexture width];
                firstPassTextureMaxY = [firstPassTexture height];
            }
            else
#endif
            {
              glTexParameteri([firstPassTexture textureTarget], GL_TEXTURE_MIN_FILTER, GL_LINEAR);
              glTexParameteri([firstPassTexture textureTarget], GL_TEXTURE_MAG_FILTER, GL_LINEAR);

            }
#if __OPENGL_ES__
#else
          glBegin(GL_QUADS);
          glTexCoord2f(0, 0);
          glVertex2f(-[firstPassTexture width]/2.0, -[firstPassTexture height]/2.0);
          glTexCoord2f(0, firstPassTextureMaxY);
          glVertex2f(-[firstPassTexture width]/2.0, [firstPassTexture height]/2.0);
          glTexCoord2f(firstPassTextureMaxX, firstPassTextureMaxY);
          glVertex2f([firstPassTexture width]/2.0, [firstPassTexture height]/2.0);
          glTexCoord2f(firstPassTextureMaxX, 0);
          glVertex2f([firstPassTexture width]/2.0, -[firstPassTexture height]/2.0);
          glEnd();
#endif
          glDisable([firstPassTexture textureTarget]);
          
          glUseProgram(0);

          [firstPassTexture unbind];
          [framebuffer unbind];
          
          /* Preserve the FBO texture and discard framebuffer */
          CAGLTexture * secondPassTexture = [[framebuffer texture] retain];
          [framebuffer release];
          
          /************************************/
          
          /* Finally! Draw shadow into draw buffer */
#if !__OPENGL_ES__
            if (sizeof(transform.m11) == sizeof(GLdouble))
                glLoadMatrixd((GLdouble*)&transform);
            else
#endif
            glLoadMatrixf((GLfloat*)&transform);
          glTranslatef([layer shadowOffset].width, [layer shadowOffset].height, 0);

          [secondPassTexture bind];

          GLfloat secondPassTextureMaxX = 1.0, secondPassTextureMaxY = 1.0;
#if !__OPENGL_ES__
            if ([secondPassTexture textureTarget] == GL_TEXTURE_RECTANGLE_ARB)
            {
                secondPassTextureMaxX = [secondPassTexture width];
                secondPassTextureMaxY = [secondPassTexture height];
            }
            else
#endif
            {
              glTexParameteri([secondPassTexture textureTarget], GL_TEXTURE_MIN_FILTER, GL_LINEAR);
              glTexParameteri([secondPassTexture textureTarget], GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            }
#if __OPENGL_ES__
#else
          glBegin(GL_QUADS);
          glTexCoord2f(0, 0);
          glVertex2f(-[secondPassTexture width]/2.0, -[secondPassTexture height]/2.0);
          glTexCoord2f(0, secondPassTextureMaxY);
          glVertex2f(-[secondPassTexture width]/2.0, [secondPassTexture height]/2.0);
          glTexCoord2f(secondPassTextureMaxX, secondPassTextureMaxY);
          glVertex2f([secondPassTexture width]/2.0, [secondPassTexture height]/2.0);
          glTexCoord2f(secondPassTextureMaxX, 0);
          glVertex2f([secondPassTexture width]/2.0, -[secondPassTexture height]/2.0);
          glEnd();
#endif
          glDisable([secondPassTexture textureTarget]);
          
          [firstPassTexture release];
          [secondPassTexture release];
          
          /* Without shadow offset */
#if !__OPENGL_ES__
            if (sizeof(transform.m11) == sizeof(GLdouble))
                glLoadMatrixd((GLdouble*)&transform);
            else
#endif
            glLoadMatrixf((GLfloat*)&transform);

        }

      #warning Intentionally coloring offscreen-rendered layer
      glColor3f(0.4, 1.0, 1.0);
      
      #warning Intentionally applying shader to offscreen-rendered layer
      [_simpleProgram use];
      GLint loc;
#if !__OPENGL_ES__
        if ([texture textureTarget] == GL_TEXTURE_RECTANGLE_ARB)
            loc = [_simpleProgram locationForUniform:@"texture_2drect"];
        else
#endif
        loc = [_simpleProgram locationForUniform:@"texture_2d"];
      
      [_simpleProgram bindUniformAtLocation: loc
                              toUnsignedInt: 0];
      
      
      // TODO: replace use of glBegin()/glEnd()
      [texture bind];
      
      GLfloat textureMaxX = 1.0, textureMaxY = 1.0;
#if !__OPENGL_ES__
        if ([texture textureTarget] == GL_TEXTURE_RECTANGLE_ARB)
        {
            textureMaxX = [texture width];
            textureMaxY = [texture height];
        }
        else
#endif
        {
          glTexParameteri([texture textureTarget], GL_TEXTURE_MIN_FILTER, GL_LINEAR);
          glTexParameteri([texture textureTarget], GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        }
        
#if __OPENGL_ES__
#else
      glBegin(GL_QUADS);
      glTexCoord2f(0, 0);
      glVertex2f(-256, -256);
      glTexCoord2f(0, textureMaxY);
      glVertex2f(-256, 256);
      glTexCoord2f(textureMaxX, textureMaxY);
      glVertex2f(256, 256);
      glTexCoord2f(textureMaxX, 0);
      glVertex2f(256, -256);
      glEnd();
#endif
      glDisable([texture textureTarget]);
      
      #warning Intentionally coloring offscreen-rendered layer
      glColor3f(1.0, 1.0, 1.0);
      #warning Intentionally applying shader to offscreen-rendered layer
      glUseProgram(0);
      
      return;
    }

  [layer displayIfNeeded];

  // fill vertex arrays
  GLfloat vertices[] = {
    0.0, 0.0,
    [layer bounds].size.width, 0.0,
    [layer bounds].size.width, [layer bounds].size.height,
    
    [layer bounds].size.width, [layer bounds].size.height,
    0.0, [layer bounds].size.height,
    0.0, 0.0,
  };
  CGRect cr = [layer contentsRect];
  GLfloat texCoords[] = {
    cr.origin.x,                 1.0 - (cr.origin.y),
    cr.origin.x + cr.size.width, 1.0 - (cr.origin.y),
    cr.origin.x + cr.size.width, 1.0 - (cr.origin.y + cr.size.height),
    
    cr.origin.x + cr.size.width, 1.0 - (cr.origin.y + cr.size.height),
    cr.origin.x,                 1.0 - (cr.origin.y + cr.size.height),
    cr.origin.x,                 1.0 - (cr.origin.y),
  };
  GLfloat whiteColor[] = {
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
  };
  GLfloat backgroundColor[] = {
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
  };
  glVertexPointer(2, GL_FLOAT, 0, vertices);
  glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
  
  // apply anchor point
  for (int i = 0; i < 6; i++)
    {
      vertices[i*2 + 0] -= [layer anchorPoint].x * [layer bounds].size.width;
      vertices[i*2 + 1] -= [layer anchorPoint].y * [layer bounds].size.height;
    }

  // apply opacity to white color
  for (int i = 0; i < 6; i++)
    {
      whiteColor[i*4 + 3] *= [layer opacity];
    }

  // apply background color
  if ([layer backgroundColor] && CGColorGetAlpha([layer backgroundColor]) > 0)
    {
      const CGFloat * componentsCG = CGColorGetComponents([layer backgroundColor]);
      GLfloat components[4] = { 0, 0, 0, 1 };
      
      // convert
      components[0] = componentsCG[0];
      components[1] = componentsCG[1];
      components[2] = componentsCG[2];
      if (CGColorGetNumberOfComponents([layer backgroundColor]) == 4)
        components[3] = componentsCG[3];
      
      // apply opacity
      components[3] *= [layer opacity];

      
      // FIXME: here we presume that color contains RGBA channels.
      // However this may depend on colorspace, number of components et al
      memcpy(backgroundColor + 0*4, components, sizeof(GLfloat)*4);
      memcpy(backgroundColor + 1*4, components, sizeof(GLfloat)*4);
      memcpy(backgroundColor + 2*4, components, sizeof(GLfloat)*4);
      memcpy(backgroundColor + 3*4, components, sizeof(GLfloat)*4);
      memcpy(backgroundColor + 4*4, components, sizeof(GLfloat)*4);
      memcpy(backgroundColor + 5*4, components, sizeof(GLfloat)*4);
      glColorPointer(4, GL_FLOAT, 0, backgroundColor);
      
      glDrawArrays(GL_TRIANGLES, 0, 6);
  
    }

  // if there are some contents, draw them
  if ([layer contents])
    {
      CAGLTexture * texture = nil;
      id layerContents = [layer contents];
      
      if ([layerContents isKindOfClass: [CABackingStore class]])
        {
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
          
          texture = [CAGLTexture texture];
          [texture loadImage: image];
        }
      
#if !__OPENGL_ES__
        if ([texture textureTarget] == GL_TEXTURE_RECTANGLE_ARB)
        {
            /* Rectangle textures use non-normalized coordinates. */
            
            for (int i = 0; i < 6; i++)
            {
                texCoords[i*2 + 0] *= [texture width];
                texCoords[i*2 + 1] *= [texture height];
            }
        }
#endif
      
      [texture bind];
      glColorPointer(4, GL_FLOAT, 0, whiteColor);
      glDrawArrays(GL_TRIANGLES, 0, 6);
      [texture unbind];

    }

  transform = CATransform3DConcat ([layer sublayerTransform], transform);
  transform = CATransform3DTranslate (transform, -[layer bounds].size.width/2, -[layer bounds].size.height/2, 0);
  for (CALayer * sublayer in [layer sublayers])
    {
      [self _renderLayer: sublayer withTransform: transform];
    }
}
#endif

- (void) _determineAndScheduleRasterizationForLayer: (CALayer*)layer
{
    // Rasterization not supported now
    // below code cause memory leak
    // disable it.
    return;
  BOOL shouldRasterize = NO;
  /* Whether a layer needs to be rasterized is complex to determine,
     but the first thing to check is user-specifiable property
     'shouldRasterize'. */
  if (!shouldRasterize && [[layer presentationLayer] shouldRasterize])
    {
      shouldRasterize = YES;
    }
    
  if (!shouldRasterize && [[layer presentationLayer] shadowOpacity] > 0.0)
    {
      shouldRasterize = YES;
    }
  
  /* Now, based on results, either rasterize or invalidate rasterization */
  if (shouldRasterize)
    [self _scheduleRasterization: layer];
  else
    [[layer backingStore] setOffscreenRenderTexture: nil];
  
}

- (void) _scheduleRasterization: (CALayer *)layer
{
  NSMutableDictionary * rasterizationSpec = [NSMutableDictionary new];
  
  [rasterizationSpec setValue: layer forKey: @"layer"];
  [_rasterizationSchedule addObject: rasterizationSpec];
  [rasterizationSpec release];
}

- (void) _rasterize: (NSDictionary*) rasterizationSpec
{
  CALayer * layer = [rasterizationSpec valueForKey: @"layer"];
  
  /* we need to render the presentationLayer */
  if (![layer isPresentationLayer])
    layer = [layer presentationLayer];

  /* Empty the cache so redraw gets performed in -[CARenderer _renderLayer:withTransform:] */
  [[layer backingStore] setOffscreenRenderTexture: nil];

  // TODO: 512x512 is NOT correct, we need to determine the actual layer size together with sublayers
  const GLuint rasterize_w = 512, rasterize_h = 512;
  CAGLSimpleFramebuffer * framebuffer = [[CAGLSimpleFramebuffer alloc] initWithWidth: rasterize_w height: rasterize_h];
  [framebuffer setDepthBufferEnabled: YES];
  [framebuffer bind];
  
  glDisable([[framebuffer texture] textureTarget]);

  glClearColor(0.0, 0.0, 0.0, 0.0);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  [self _renderLayer: layer withTransform: CATransform3DMakeTranslation(rasterize_w/2.0 - [layer position].x, rasterize_h/2.0 - [layer position].y, 0)];
  
  [framebuffer unbind];
  
  if (![layer backingStore])
    [layer setBackingStore: [CABackingStore backingStoreWithWidth: rasterize_w height: rasterize_h]];
  [[layer backingStore] setOffscreenRenderTexture: [framebuffer texture]];
  
  [framebuffer release];
}


- (void) _rasterizeAll
{
  /* Rasterize */
  for (NSDictionary * rasterizationSpec in _rasterizationSchedule)
  {
    [self _rasterize: rasterizationSpec];
  }
  
  /* Release rasterization schedule */
  [_rasterizationSchedule release];
  _rasterizationSchedule = nil;
}



@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
