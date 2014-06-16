/* CALayer+FrameworkPrivate.h

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

#import "QuartzCore/CALayer.h"

#if TARGET_OS_IPHONE
#import <OpenGLES/ES2/gl.h>
#else
#import <GLES2/gl2.h>
#endif

typedef struct {
    GLfloat x;
    GLfloat y;
} _CALayerVertexPosition;

typedef struct {
    GLfloat	r;
	GLfloat	g;
	GLfloat	b;
	GLfloat a;
} _CALayerVertexColor;

typedef struct {
    GLfloat u;
    GLfloat v;
} _CALayerVertexTexcoord;

static inline _CALayerVertexPosition _CALayerVertexPositionMake(GLfloat x, GLfloat y) {
    _CALayerVertexPosition p; p.x = x;p.y = y; return p;
}

static inline _CALayerVertexColor _CALayerVertexColorMake(GLubyte r, GLubyte g, GLubyte b, GLubyte a) {
    _CALayerVertexColor c; c.r = r; c.g = g; c.b = b; c.a = a; return c;
}

static inline _CALayerVertexTexcoord _CALayerVertexTexcoordMake(GLfloat u, GLfloat v) {
    _CALayerVertexTexcoord p; p.u = u;p.v = v; return p;
}

typedef struct {
    //vertex
    _CALayerVertexPosition position;
    
    //color
    _CALayerVertexColor color;
    
    // texcoord
    _CALayerVertexTexcoord texcoord;
} _CALayerVertex;

typedef struct {
    _CALayerVertex bl;
    _CALayerVertex br;
    _CALayerVertex tl;
    _CALayerVertex tr;
} _CALayerQuad;

@interface CALayer (FrameworkPrivate)
/* sets value passed into -[CARenderer beginFrameAtTime:...]
   used as "time of object superior to root layer" (that is,
   CARenderer) */
+ (void) setCurrentFrameBeginTime: (CFTimeInterval)frameTime;

- (CALayer *) rootLayer;
- (NSArray *) allAncestorLayers;
- (CALayer *) nextAncestorOf: (CALayer *)layer;

- (BOOL)isPresentationLayer;

- (void) discardPresentationLayer;
//- (void)resetPresentationLayerIfNeeds;
@property (assign,getter = isDirty) BOOL dirty;
- (void)markDirty;

- (BOOL)hasAnimations;
- (CFTimeInterval) applyAnimationsAtTime: (CFTimeInterval)time;

- (CFTimeInterval) activeTime;
- (CFTimeInterval) localTime;

@property (retain) CABackingStore * backingStore;

/* Vertex */
@property (nonatomic, assign) _CALayerQuad quad;

- (void)drawOpenGLES;
@property (assign) GLuint vbo;
- (void)prepareQuad;
@end
