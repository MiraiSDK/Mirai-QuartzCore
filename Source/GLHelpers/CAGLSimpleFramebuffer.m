/* CAGLFramebuffer.m

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

#import "CAGLSimpleFramebuffer.h"
#import "CAGLTexture.h"

@interface CAGLSimpleFramebuffer ()
@property (nonatomic, retain) CAGLTexture * texture;
@property (nonatomic, assign) GLuint framebufferID;
@end

static NSMutableArray * framebufferStack = nil;

@implementation CAGLSimpleFramebuffer
@synthesize texture=_texture;
@synthesize depthBufferEnabled=_depthBufferEnabled;
@synthesize framebufferID=_framebufferID;

- (id)initWithWidth: (CGFloat) width
             height: (CGFloat) height
{
  self = [super init];
  if (!self)
    return nil;

  glGenFramebuffers(1, &_framebufferID);
  
  /* Build a texture and assign it to the framebuffer */
  _texture = [CAGLTexture new];
 

  [_texture bind];
  /* Ogre3d sets these parameters to ensure functionality under nVidia cards */

#if __OPENGL_ES__
#else
  glTexParameteri([_texture textureTarget], GL_TEXTURE_MAX_LEVEL, 0);
#endif

  glTexParameteri([_texture textureTarget], GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri([_texture textureTarget], GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri([_texture textureTarget], GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri([_texture textureTarget], GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  [_texture loadEmptyImageWithWidth: width
                             height: height];
  
#if __OPENGL_ES__
    glBindFramebuffer(GL_FRAMEBUFFER, _framebufferID);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, [_texture textureTarget], [_texture textureID], 0);
#else
    glBindFramebuffer(GL_FRAMEBUFFER_EXT, _framebufferID);
    glFramebufferTexture2D(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, [_texture textureTarget], [_texture textureID], 0);
#endif

  return self;
}

- (void) dealloc
{
  if ([framebufferStack lastObject] == self)
    [self unbind];
  
  if ([framebufferStack containsObject: self])
    NSLog(@"Releasing a framebuffer that's still in framebuffer stack");
    
  /* clean up renderbuffer storage */
  if (_depthBufferEnabled)
    [self setDepthBufferEnabled: NO];
  
  /* delete framebuffer itself */
  glDeleteFramebuffers(1, &_framebufferID);
  
  /* release the texture */
  [_texture release];
  
  [super dealloc];
}

- (void) setDepthBufferEnabled: (BOOL)depthBufferEnabled
{
  if (_depthBufferEnabled == depthBufferEnabled)
    return;
  
  _depthBufferEnabled = depthBufferEnabled;
  [self bind];

  if (_depthBufferEnabled)
  {
    glGenRenderbuffers(1, &_depthRenderbufferID);
#if __OPENGL_ES__
      glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderbufferID);
      glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, [_texture width], [_texture height]);
      
      glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderbufferID);
#else
      glBindRenderbuffer(GL_RENDERBUFFER_EXT, _depthRenderbufferID);
      glRenderbufferStorage(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT24, [_texture width], [_texture height]);
      
      glFramebufferRenderbuffer(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, _depthRenderbufferID);
#endif

  }
  else
  {
#if __OPENGL_ES__
      glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, 0);
#else
      glFramebufferRenderbuffer(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, 0);
#endif
    
    glDeleteRenderbuffers(1, &_depthRenderbufferID);
  }
  
  [self unbind];
}

- (void) bind
{
  if (!framebufferStack)
    {
      framebufferStack = [NSMutableArray new];
    }
#if __OPENGL_ES__
    glBindFramebuffer(GL_FRAMEBUFFER, _framebufferID);
#else
    glBindFramebuffer(GL_FRAMEBUFFER_EXT, _framebufferID);
#endif

  [framebufferStack addObject: self];
}

- (void) unbind
{
  if ([framebufferStack lastObject] != self)
    {
      NSLog(@"Unbinding a framebuffer that is not on top of the stack");
    }
  [framebufferStack removeLastObject];
  
    if ([framebufferStack count] > 0)
#if __OPENGL_ES__
        glBindFramebuffer(GL_FRAMEBUFFER, [((CAGLSimpleFramebuffer*)[framebufferStack lastObject]) framebufferID]);
#else
        glBindFramebuffer(GL_FRAMEBUFFER_EXT, [((CAGLSimpleFramebuffer*)[framebufferStack lastObject]) framebufferID]);
#endif
  else
#if __OPENGL_ES__
      glBindFramebuffer(GL_FRAMEBUFFER, 0);
#else
      glBindFramebuffer(GL_FRAMEBUFFER_EXT, 0);
#endif

}

/*
  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, _framebufferID);
  glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, surface->texture, 0);
  if (depth)
    glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, surface->depth);

  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
  */



@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
