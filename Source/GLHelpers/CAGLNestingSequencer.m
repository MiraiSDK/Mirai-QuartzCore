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
    NSArray *_params;
}
@end

@implementation _CAGLNestingSequencerNode

- (void)dealloc
{
    [_target release];
    [_params release];
    [super dealloc];
}

@end

@implementation CAGLNestingSequencer
{
    NSMutableArray *_nodeQueue;
}

- (void)invokeTarget:(id)target method:(SEL)method
{
    [self invokeTarget:target method:method params:nil];
}

- (void)invokeTarget:(id)target method:(SEL)method params:(NSArray *)params
{
    if (_nodeQueue) {
        _CAGLNestingSequencerNode *node = [[_CAGLNestingSequencerNode alloc] init];
        node->_target = [target retain];
        node->_params = [params retain];
        node->_method = method;
        [_nodeQueue addObject:node];
        [node release];
    } else {
        _nodeQueue = [[NSMutableArray alloc] init];
        [self _callTarget:target method:method params:params];
        
        while (_nodeQueue.count > 0) {
            _CAGLNestingSequencerNode *node = [_nodeQueue lastObject];
            [self _callTarget:node->_target method:node->_method params:node->_params];
            [_nodeQueue removeObject:node];
        }
        [_nodeQueue release];
        _nodeQueue = nil;
    }
}

- (void)_callTarget:(id)target method:(SEL)method params:(NSArray *)params
{
    NSLog(@"[%@ %@]", NSStringFromClass([target class]), NSStringFromSelector(method));
    if (params == nil || params.count == 0) {
        [target performSelector:method];
    } else if (params.count == 1) {
        [target performSelector:method withObject:params[0]];
    } else if (params.count == 2) {
        [target performSelector:method withObject:params[0] withObject:params[1]];
    } else {
        NSLog(@"Not Support, Please Add By Your Self If Need.");
    }
    NSLog(@"[Finish call]");
}

@end
