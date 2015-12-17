//
//  CALayer+CARender.m
//  GSQuartzCore
//
//  Created by TaoZeyu on 15/12/17.
//  Copyright © 2015年 Ivan Vučica. All rights reserved.
//

#import "CALayer+CARender.h"
#import "CARenderer.h"

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

#if GNUSTEP
#import <CoreGraphics/CoreGraphics.h>
#endif

@implementation CALayer (CARender)

- (void)setNeedsRefreshCombineBuffer
{
    _needsRefreshCombineBuffer = YES;
}

@end
