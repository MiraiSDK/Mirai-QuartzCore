//
//  CAExternalContentLayer.h
//  GSQuartzCore
//
//  Created by Chen Yonghui on 10/23/14.
//  Copyright (c) 2014 Ivan Vučica. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

typedef BOOL(^EAGLContentTextureUpdateCallback)(CATransform3D *t);

@interface CAExternalContentLayer : CALayer
@property (nonatomic, copy) EAGLContentTextureUpdateCallback updateCallback;
- (BOOL)updateTextureIfNeeds:(CATransform3D *)t;

@end
