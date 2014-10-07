//
//  CATransformDecompose.h
//  GSQuartzCore
//
//  Created by Chen Yonghui on 10/5/14.
//  Copyright (c) 2014 Ivan Vučica. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
    CGFloat x;
    CGFloat y;
    CGFloat z;
} CAVector3D;

void CATransform3DDecompose(CATransform3D t, CAVector3D *outTranslation, CAVector3D *outScale, CAVector3D *outRotation);
CATransform3D CATransform3DCompose(CAVector3D translation, CAVector3D scale, CAVector3D rotation);
