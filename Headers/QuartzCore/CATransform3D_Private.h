//
//  CATransform3D_Private.h
//  GSQuartzCore
//
//  Created by Chen Yonghui on 2/8/14.
//  Copyright (c) 2014 Ivan Vučica. All rights reserved.
//

#ifndef GSQuartzCore_CATransform3D_Private_h
#define GSQuartzCore_CATransform3D_Private_h

#import "QuartzCore/CATransform3D.h"

CATransform3D CATransform3DMakePerspective(float fovyRadians, float aspect, float nearZ, float farZ);
CATransform3D CATransform3DMakeFrustum(float left, float right,
                                                 float bottom, float top,
                                                 float nearZ, float farZ);
CATransform3D CATransform3DMultiply(CATransform3D matrixLeft, CATransform3D matrixRight);
CATransform3D CATransform3DMakeOrtho(float left, float right,
                                               float bottom, float top,
                                               float nearZ, float farZ);
float CADegreesToRadians(float degrees);



#endif
