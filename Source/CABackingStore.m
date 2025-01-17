/* 
   CABackingStore.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vučica <ivan@vucica.net>
   Date: June 2012

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

#import "CABackingStore.h"
#import "GLHelpers/CAGLTexture.h"

static CGContextRef createCGBitmapContext (int pixelsWide,
                                    int pixelsHigh)
{
  CGContextRef    context = NULL;
  CGColorSpaceRef colorSpace;
  void *          bitmapData;
  int             bitmapByteCount;
  int             bitmapBytesPerRow;
  
  bitmapBytesPerRow   = (pixelsWide * 4);
  bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
  
#if TARGET_OS_IPHONE
    colorSpace = CGColorSpaceCreateDeviceRGB();
#else
  colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);// 2
#endif

  // Let CGBitmapContextCreate() allocate the memory.
  // This should be good under Cocoa too.
  bitmapData = NULL;

    CGBitmapInfo info = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little;
    
  context = CGBitmapContextCreate (bitmapData,
                                   pixelsWide,
                                   pixelsHigh,
                                   8,      // bits per component
                                   bitmapBytesPerRow,
                                   colorSpace,
                                   info);
    
  // Note: our use of premultiplied alpha means that we need to
  // do alpha blending using:
  //  GL_SRC_ALPHA, GL_ONE

  CGColorSpaceRelease(colorSpace);
  if (context== NULL)
    {
      free (bitmapData);// 5
      fprintf (stderr, "Context not created!");
      return NULL;
    }

#if GNUSTEP
#warning Opal bug: context should be cleared automatically

#if 0
  CGContextClearRect (context, CGRectInfinite);
#else
#warning Opal bug: CGContextClearRect() permanently whacks the context
  memset (CGBitmapContextGetData (context), 
          0, bitmapBytesPerRow * pixelsHigh);
#endif
#endif  
  return context;
}

@implementation CABackingStore
@synthesize contentsTexture=_contentsTexture;
@synthesize offscreenRenderTexture=_offscreenRenderTexture;
@synthesize refreshed = _refreshed;

+ (CABackingStore *) backingStoreWithWidth: (CGFloat)width
                                    height: (CGFloat)height
{
  return [[[self alloc] initWithWidth: width height: height] autorelease];
}

- (id) initWithWidth: (CGFloat) width
              height: (CGFloat) height
{
  self = [super init];
  if (!self)
    return nil;
  
  CGContextRef context = createCGBitmapContext(width, height);
  [self setContext: context];
  [self setOffscreenRenderTexture: nil]; /* set at a later time by layer */
  
  CGContextRelease(context);

  return self;
}
- (void) dealloc
{
  [_offscreenRenderTexture release];
  [_contentsTexture release];
  CGContextRelease (_context);
  
  [super dealloc];
}

- (CGContextRef)context
{
  return _context;
}

- (void)setContext: (CGContextRef)context
{
  if (context == _context)
    return;
  
  /* We must invalidate the texture data, in case
     we use client storage extension. */
  [_contentsTexture loadEmptyImageWithWidth: 0
                                     height: 0];
  
  /* Now replace data... */
  CGContextRetain(context);
  CGContextRelease(_context);
  _context = context;
  
  /* Refresh */
//  [self refresh];
    [self setNeedRefresh];
}

- (CGFloat) width
{
  return CGBitmapContextGetWidth(_context);
}
- (CGFloat) height
{
  return CGBitmapContextGetHeight(_context);
}

- (void) refresh
{
  if (!_context)
    return;
    
    if (!_contentsTexture || _contentsTexture.isInvalidated) {
        [self setContentsTexture: [CAGLTexture texture]];
    }
  
#if __APPLE__ && !TARGET_OS_IPHONE
  /* Since we retain contents in the CGContext, we can use the
     client storage extension to avoid a copy. */
  glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
#endif

  [_contentsTexture loadRGBATexImage: CGBitmapContextGetData(_context)
                               width: (GLuint)CGBitmapContextGetWidth(_context)
                              height: (GLuint)CGBitmapContextGetHeight(_context)];
                      
#if __APPLE__ && !TARGET_OS_IPHONE
  glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_FALSE);
#endif
    
    self.refreshed = YES;

}

- (void)refreshIfNeed
{
    if (self.needsRefresh) {
        [self refresh];
    }
}

- (void) setNeedRefresh
{
    self.refreshed = NO;
}

- (BOOL)needsRefresh
{
    return !self.isRefreshed || !_contentsTexture || _contentsTexture.isInvalidated;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[%@ <%p>: width:%.2f, height:%.2f]",NSStringFromClass([self class]),self, self.width,self.height];
}
@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
