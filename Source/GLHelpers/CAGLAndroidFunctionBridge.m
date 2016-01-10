//
//  CAGLAndroidBridge.m
//  GSQuartzCore
//
//  Created by TaoZeyu on 15/11/4.
//  Copyright © 2015年 Ivan Vučica. All rights reserved.
//

#import "CAGLAndroidFunctionBridge.h"
#import <TNJavaHelper/TNJavaHelper.h>
#import "jni.h"

@interface CAGLAndroidFunctionBridge : NSObject
@property (nonatomic, readonly) JNIEnv *env;
@property (nonatomic, readonly) jclass GLES;
@property (nonatomic, readonly) jmethodID methodID;
@end

@implementation CAGLAndroidFunctionBridge
{
    jmethodID _methodId;
}
static JNIEnv *_env;
static jclass _GLES;

+ (void) initialize
{
    _env = [[NSClassFromString(@"TNJavaHelper") sharedHelper] env];
    _GLES = (*_env)->FindClass(_env, "android/opengl/GLES10");
}

- (instancetype) initWithName:(const char *)name sig:(const char *)sig
{
    if (self = [super init]) {
        _methodId = (*_env)->GetStaticMethodID(_env, _GLES, name, sig);
        if (_methodId == NULL) {
            NSLog(@"can't get method %s%s", name, sig);
            return nil;
        }
    }
    return self;
}

+ (void) keepBrigeWith:(CAGLAndroidFunctionBridge **)bridge name:(const char *)name sig:(const char *)sig
{
    if (!(*bridge)) {
        *bridge = [[CAGLAndroidFunctionBridge alloc] initWithName:name sig:sig];
    }
}

- (JNIEnv *) env
{
    return _env;
}

- (jclass) GLES
{
    return _GLES;
}

- (jmethodID) methodID
{
    return _methodId;
}

@end

void glClientActiveTexture(int texture)
{
    static CAGLAndroidFunctionBridge *bridge;
    [CAGLAndroidFunctionBridge keepBrigeWith:&bridge
                                        name:"glClientActiveTexture" sig:"(I)V"];
    (*bridge.env)->CallStaticVoidMethod(bridge.env, bridge.GLES, bridge.methodID, texture);
}

void glTexEnvx(int target, int pname, int param)
{
    static CAGLAndroidFunctionBridge *bridge;
    [CAGLAndroidFunctionBridge keepBrigeWith:&bridge
                                        name:"glTexEnvx" sig:"(III)V"];
    (*bridge.env)->CallStaticVoidMethod(bridge.env, bridge.GLES, bridge.methodID, target, pname, param);
}