//
//  CATransformDecompose.m
//  GSQuartzCore
//
//  Created by Chen Yonghui on 10/5/14.
//  Copyright (c) 2014 Ivan Vučica. All rights reserved.
//

#import "CATransformDecompose.h"

/********************************/
/** Some helper math functions **/

static CATransform3D transpose(CATransform3D m)
{
    CATransform3D r;
    CGFloat *mF = (CGFloat *)&m;
    CGFloat *rF = (CGFloat *)&r;
    for(int i = 0; i < 16; i++)
    {
        int col = i % 4;
        int row = i / 4;
        int j = col * 4 + row;
        rF[j] = mF[i];
    }
    
    return r;
}
/** End helper math functions **/
/*******************************/

//
// http://nghiaho.com/?page_id=846 Decomposing and composing a 3×3 rotation matrix
//
void CATransform3DDecompose(CATransform3D ot, CAVector3D *outTranslation, CAVector3D *outScale, CAVector3D *outRotation)
{
    CATransform3D t = transpose(ot);
    
    /* translation */
    CGFloat tx = t.m14;
    CGFloat ty = t.m24;
    CGFloat tz = t.m34;
    
    /* scale */
#define GSQC_POW2(x) ((x)*(x))
    CGFloat scaleX = sqrt(GSQC_POW2(t.m11) + GSQC_POW2(t.m12) + GSQC_POW2(t.m13));
    CGFloat scaleY = sqrt(GSQC_POW2(t.m21) + GSQC_POW2(t.m22) + GSQC_POW2(t.m23));
    CGFloat scaleZ = sqrt(GSQC_POW2(t.m31) + GSQC_POW2(t.m32) + GSQC_POW2(t.m33));
#undef GSQC_POW2
    

    /* rotation */
    CATransform3D rotationT;
    rotationT.m11 = t.m11 / scaleX;
    rotationT.m12 = t.m12 / scaleX;
    rotationT.m13 = t.m13 / scaleX;
    rotationT.m14 = 0;
    
    rotationT.m21 = t.m21 / scaleY;
    rotationT.m22 = t.m22 / scaleY;
    rotationT.m23 = t.m23 / scaleY;
    rotationT.m24 = 0;
    
    rotationT.m31 = t.m31 / scaleZ;
    rotationT.m32 = t.m32 / scaleZ;
    rotationT.m33 = t.m33 / scaleZ;
    rotationT.m34 = 0;
    
    rotationT.m41 = 0;
    rotationT.m42 = 0;
    rotationT.m43 = 0;
    rotationT.m44 = 1;
    
    double ax,ay,az;
    ax = atan2(rotationT.m32, rotationT.m33);
    ay = atan2(-rotationT.m31, sqrt(rotationT.m32*rotationT.m32 + rotationT.m33*rotationT.m33));
    az = atan2(rotationT.m21, rotationT.m11);

    // output
    outTranslation->x = tx;
    outTranslation->y = ty;
    outTranslation->z = tz;
    
    outScale->x = scaleX;
    outScale->y = scaleY;
    outScale->z = scaleZ;
    
    outRotation->x = ax;
    outRotation->y = ay;
    outRotation->z = az;
}

CATransform3D CATransform3DCompose(CAVector3D translation, CAVector3D scale, CAVector3D rotation)
{
    CATransform3D rotationX = CATransform3DIdentity;
    CATransform3D rotationY = CATransform3DIdentity;
    CATransform3D rotationZ = CATransform3DIdentity;
    
    rotationX.m22 = cos(rotation.x);
    rotationX.m23 = -sin(rotation.x);
    rotationX.m32 = sin(rotation.x);
    rotationX.m33 = cos(rotation.x);

    rotationY.m11 = cos(rotation.y);
    rotationY.m13 = sin(rotation.y);
    rotationY.m31 = -sin(rotation.y);
    rotationY.m33 = cos(rotation.y);

    rotationZ.m11 = cos(rotation.z);
    rotationZ.m12 = -sin(rotation.z);
    rotationZ.m21 = sin(rotation.z);
    rotationZ.m22 = cos(rotation.z);
    
    CATransform3D rotationTransform = CATransform3DConcat(rotationZ, CATransform3DConcat(rotationY, rotationX));

    CATransform3D scaleTransform = CATransform3DMakeScale(scale.x, scale.y, scale.z);
    CATransform3D translationTransform = CATransform3DMakeTranslation(translation.x, translation.y, translation.z);
    translationTransform = transpose(translationTransform);
    
    CATransform3D transform = CATransform3DConcat(translationTransform, CATransform3DConcat(scaleTransform, rotationTransform));
    
    transform = transpose(transform);
    
    return transform;
}
