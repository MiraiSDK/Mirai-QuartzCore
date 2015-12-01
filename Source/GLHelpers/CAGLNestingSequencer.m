//
//  CAGLNestingSequencer.m
//  GSQuartzCore
//
//  Created by TaoZeyu on 15/11/30.
//  Copyright © 2015年 Ivan Vučica. All rights reserved.
//

#import "CAGLNestingSequencer.h"

@interface _CAGLNestingSequencerNode : NSObject
{
@public
    id _target;
    SEL _method;
}
@end

@implementation _CAGLNestingSequencerNode

- (void)dealloc
{
    [_target release];
    [super dealloc];
}

@end

@implementation CAGLNestingSequencer
{
    NSMutableArray *_nodeQueue;
}

- (instancetype)invokeTarget:(id)target method:(SEL)method
{
    if (_nodeQueue) {
        NSLog(@" ");
        NSLog(@"-->");
        _CAGLNestingSequencerNode *node = [[_CAGLNestingSequencerNode alloc] init];
        node->_target = [target retain];
        node->_method = method;
        [_nodeQueue addObject:node];
        [node release];
    } else {
        NSLog(@" ");
        NSLog(@">>>");
        _nodeQueue = [[NSMutableArray alloc] init];
        [target performSelector:method];
        
        while (_nodeQueue.count > 0) {
            _CAGLNestingSequencerNode *node = [_nodeQueue lastObject];
            [node->_target performSelector:node->_method];
            [_nodeQueue removeObject:node];
        }
        [_nodeQueue release];
        _nodeQueue = nil;
        NSLog(@"<<<");
        NSLog(@" ");
    }
}

@end
