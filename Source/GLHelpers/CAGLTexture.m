/* CAGLTexture.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vučica <ivan@vucica.net>
   Date: July 2012

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

#import "CAGLTexture.h"

#define USE_RECT 0
#define USE_BUILDMIPMAPS 0
#if USE_RECT
#define TEXTURE_TARGET GL_TEXTURE_RECTANGLE_ARB
#define qcLoadTexImage(channels, width, height, format, type, data) \
        glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, channels, \
                     width, height, 0, format, type, \
                     data)

#elif USE_BUILDMIPMAPS
#define TEXTURE_TARGET GL_TEXTURE_2D
#define qcLoadTexImage(channels, width, height, format, type, data) \
        gluBuild2DMipmaps(GL_TEXTURE_2D, channels, width, height, format, type, data)
#else
#define TEXTURE_TARGET GL_TEXTURE_2D
#define qcLoadTexImage(channels, width, height, format, type, data) \
        glTexImage2D(GL_TEXTURE_2D, 0, channels, \
                     width, height, 0, format, type, \
                     data)
#endif
#import <CoreGraphics/CoreGraphics.h>

@implementation CAGLTexture
@synthesize textureID=_textureID;
@synthesize width=_width;
@synthesize height=_height;
@synthesize contents = _contents;
@synthesize invalidated = _invalidated;

+ (CAGLTexture *) texture
{
  return [[self new] autorelease];
}

NSString *const CAGLTextureInvalidatedNotification = @"CAGLTextureInvalidatedNotification";
+ (void)invalidate
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CAGLTextureInvalidatedNotification object:nil];
}

- (void)invalidate
{
    self.invalidated = YES;
}

- (BOOL)isInvalidated
{
    return _invalidated || !glIsTexture(_textureID);
}

- (id) init
{
  self = [super init];
  if (!self)
    return nil;
  
  glGenTextures(1, &_textureID);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(invalidate)
                                                 name:CAGLTextureInvalidatedNotification
                                               object:nil];
    _invalidated = NO;
    
  return self;
}

- (void) dealloc
{
  glDeleteTextures(1, &_textureID);
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CAGLTextureInvalidatedNotification object:nil];
  [super dealloc];
}

- (void) loadEmptyImageWithWidth: (GLuint)width
                          height: (GLuint)height
{
#if __APPLE__ && !TARGET_OS_IPHONE
  glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_FALSE);
#endif
    
  /* Used for, for example, renderbuffer's target */
#if !(USE_BUILDMIPMAPS)
  qcLoadTexImage(GL_RGBA,
    width,
    height,
    GL_RGBA,
    GL_UNSIGNED_BYTE,
    0);
#else
  // building mipmaps can't be done with NULL.
  //NOTE: This requires support for non-power-of-two textures.
  glTexImage2D(GL_TEXTURE_2D,
    0,
    GL_RGBA,
    width,
    height,
    0,
    GL_RGBA,
    GL_UNSIGNED_BYTE,
    0);
#endif
  
  _width = width;
  _height = height;
}
- (void) loadRGBATexImage: (void *)data
                    width: (GLuint)width
                   height: (GLuint)height
{
  _width = width;
  _height = height;

  glBindTexture(TEXTURE_TARGET, _textureID);

#if !(__APPLE__)
  qcLoadTexImage(GL_RGBA,
    width,
    height,
    GL_RGBA,
    GL_UNSIGNED_BYTE,
    data);
#else

  #if !USE_RECT && !TARGET_OS_IPHONE
  /* On Apple, and not using rectangular textures?
     Client extension can't be used due to use of gluBuild2DMipmaps(), so
     ensure it's off. */
  glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_FALSE);
  #endif

/* TODO: This Apple-specific section of code refers "Best practices for
   working with texture data" in Apple docs, except that the 'format' 
   argument (the second argument specifying GL_RGBA) should be, according 
   to their docs, BGRA. 
   Explore if we should use this everywhere, and if we can somehow make 
   use of BGRA (probably not due to CGImageRefs and other uses that may
   presume RGBA ordering). */

  qcLoadTexImage(GL_RGBA,
    width,
    height,
    GL_RGBA,
#if TARGET_OS_IPHONE
    GL_UNSIGNED_BYTE,
#else
    GL_UNSIGNED_INT_8_8_8_8_REV,
#endif
    data);
#endif

    GLenum err = glGetError();
    if (err != GL_NO_ERROR) {
        NSLog(@"Got error %04x for TexImage %d x %d\n", err, width, height);
    }

#if !(USE_RECT) && !(USE_BUILDMIPMAPS)
  /* Use of non-power-of-two textures seems to require GL_NEAREST filter */
  glTexParameteri(TEXTURE_TARGET, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(TEXTURE_TARGET, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    
#if TARGET_OS_IPHONE
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
#endif
#endif
}

- (void)loadImage: (CGImageRef) image
{
  CGFloat width = CGImageGetWidth(image);
  CGFloat height = CGImageGetHeight(image);
  size_t bitsPerComponent = 8; //CGImageGetBitsPerComponent(image);
  unsigned long bytesPerRow = width * 4; //CGImageGetBytesPerRow(image); // in some cases, we cannot generate RGB textureContext, it appears; only RGBA
  CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(image);
    
    // speedup image decode if it's dataprovider's formate is RGBA
    if (CGImageGetBitsPerComponent(image) == 8 &&
        (alphaInfo == kCGImageAlphaPremultipliedFirst || alphaInfo == kCGImageAlphaNoneSkipFirst)) {
        //
        // FIXME: Workaround
        // We remove typically styles to get CGImage data
        //  1. CGBitmapContextCreate
        //  2. CGContextDrawImage
        //  3. CGBitmapContextGetData
        // Instead, we use
        //  1. CGImageGetDataProvider
        //  2. CGDataProviderCopyData
        // This workaround implies assume one thing:
        //  1. The CGImage's provider always provider decoded RGBA data
        CGDataProviderRef provider = CGImageGetDataProvider(image);
        CFDataRef dataRef = CGDataProviderCopyData(provider);
        uint8_t * data = malloc(bytesPerRow * height);
        CFDataGetBytes(dataRef, CFRangeMake(0, CFDataGetLength(dataRef)), data);
        
        [self loadRGBATexImage: data
                         width: width
                        height: height];
        
        free(data);
        CFRelease(dataRef);
        return;
    }
    
#if !GNUSTEP
  CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB(); //CGImageGetColorSpace(image); // if we get indexed-colorspace image, creation of bitmap context will fail. also, we load image into OpenGL as RGB. so, force RGB
#else
#warning Opal does not like CGColorSpaceCreateDeviceRGB() passed as colorpsace for bitmap context
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);// 2
#endif

  /* Draw CGImage to a byte array */
  CGContextRef context = CGBitmapContextCreate(NULL,
    width, height,
    bitsPerComponent, 
    bytesPerRow,
    space,
#if !GNUSTEP || (__OPENGL_ES__)
    kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little
#else
#warning GNUstep: forced to pass kCGImageAlphaPremultipliedFirst although we end up with ...Last
    kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little
#endif
  );
  CGColorSpaceRelease(space);
  if (!context)
    {
      NSLog(@"%@: Failed to create bitmap context", NSStringFromSelector(_cmd));
      return;
    }

#if GNUSTEP
#warning Opal bug: context should be cleared automatically
#if 0
  CGContextClearRect (context, CGRectInfinite);
#else
#warning Opal bug: CGContextClearRect() permanently whacks the context
  memset (CGBitmapContextGetData (context), 
          0, bytesPerRow * height);
#endif
#endif  
    
  CGContextDrawImage(context, CGRectMake(0.0, 0.0, width, height), image);

  uint8_t * data = CGBitmapContextGetData(context);
  for(int i=0; i < bytesPerRow * height; i+=4)
	  {
      #if !(GNUSTEP)
      /* let's undo premultiplication */
      /* TODO: do we need to undo premultiplication under GNUstep too? */
      for(int j=0; j<3; j++)
        {
          data[i+j] = data[i+j] / (data[i+3]/255.);
        }
      #endif
    }
  
  #if 0
  BOOL hasAlpha = (CGImageGetBytesPerRow(image) / width == 4);
	GLuint internalFormat = GL_RGBA; /* does not depend on hasAlpha, we always paint a RGBA image into CGContext (sadly) */
  #endif
  

  #if !USE_RECT
  /* Since we release the context, we also release its pixels.
     We cannot use client storage extension. */
    // FIXME: WHAT?
//  glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_FALSE);
  #endif
  
  [self loadRGBATexImage: data
                   width: width
                  height: height];

  CGContextRelease(context);

}

- (void) bind
{
#if !__OPENGL_ES__
  glEnable(TEXTURE_TARGET);
#endif
  glBindTexture(TEXTURE_TARGET, _textureID);
}

- (void) unbind
{
  glBindTexture(TEXTURE_TARGET, 0);
#if !__OPENGL_ES__
  glDisable(TEXTURE_TARGET);
#endif
}

- (GLenum) textureTarget
{
  return TEXTURE_TARGET;
}

- (void) _writeToPNG:(NSString*)path
{
  char pixels[[self width]*[self height]*4];
  [self bind];
#if __OPENGL_ES__
    NSLog(@"%s unimplemented",__PRETTY_FUNCTION__);
#else
    glGetTexImage([self textureTarget], 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
#endif
    
//  CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
//  CGContextRef context = CGBitmapContextCreate(pixels, [self width], [self height], 8, [self width]*4, colorSpace, kCGImageAlphaPremultipliedLast);
//  CGImageRef image = CGBitmapContextCreateImage(context);
//  CGContextRelease(context);
//  CGColorSpaceRelease(colorSpace);
//  
//  NSMutableData * data = [NSMutableData data];
//  CGImageDestinationRef destination = CGImageDestinationCreateWithData((CFMutableDataRef)data, (CFStringRef)@"public.png", 1, NULL);
//  CGImageDestinationAddImage(destination, image, NULL);
//  CGImageDestinationFinalize(destination);
//  CGImageRelease(image);
//  
//  [data writeToFile:path atomically:YES];
}
@end
