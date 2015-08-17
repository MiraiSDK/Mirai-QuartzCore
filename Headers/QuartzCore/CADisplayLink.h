/* CADisplayLink.h
 *
 * Dummy implementation for ScrollView
 *
*/

#import <QuartzCore/CABase.h>
#import <Foundation/NSObject.h>

@class NSString, NSRunLoop;

@interface CADisplayLink : NSObject

+ (CADisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)sel;
- (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSString *)mode;
- (void)removeFromRunLoop:(NSRunLoop *)runloop forMode:(NSString *)mode;
- (void)invalidate;

// properties not implemented
@property(readonly, nonatomic) CFTimeInterval timestamp;
@property(readonly, nonatomic) CFTimeInterval duration;
@property(getter=isPaused, nonatomic) BOOL paused;
@property(nonatomic) NSInteger frameInterval;

+ (void)_endFrame;
@end