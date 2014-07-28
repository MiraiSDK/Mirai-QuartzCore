//
//  CAMovieLayer.h
//  GSQuartzCore
//
//  Created by Chen Yonghui on 7/28/14.
//  Copyright (c) 2014 Ivan Vučica. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

typedef BOOL(^EAGLTextureUpdateCallback)(CATransform3D *t);

@interface CAMovieLayer : CALayer

@property (nonatomic, copy) EAGLTextureUpdateCallback updateCallback;
- (BOOL)updateTextureIfNeeds:(CATransform3D *)t;

@end
