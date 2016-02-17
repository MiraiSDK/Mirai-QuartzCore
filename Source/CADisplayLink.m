/* CADisplayLink.m

*/

#import "CADisplayLink.h"

@interface CADisplayLink ()
@property (nonatomic, strong) id target;
@property (nonatomic, assign) SEL sel;

@property (nonatomic, strong) NSTimer *timer;
@end

@implementation CADisplayLink
@synthesize target = _target;
@synthesize sel = _sel;
@synthesize timestamp = _timestamp;
@synthesize duration = _duration;
@synthesize paused = _paused;
@synthesize frameInterval = _frameInterval;
@synthesize timer = _timer;

+ (BOOL)hasInstalledLinks
{
    return [self installedLinks].count > 0;
}

+ (void)_endFrame
{
    if ([self hasInstalledLinks]) {
        [(NSObject *)self performSelectorOnMainThread:@selector(performLinks) withObject:nil waitUntilDone:YES];
    }
}

+ (void)performLinks
{
    NSArray *links = [[self installedLinks] copy];
    for (CADisplayLink *link in links) {
        [link.target performSelector:link.sel withObject:link];
    }
    [links release];
}

+ (NSMutableArray *)installedLinks
{
    @synchronized(self) {
        static NSMutableArray *_links = nil;
        if (!_links) {
            _links = [[NSMutableArray alloc] init];
        }
        
        return _links;

    }
}

+ (void)installDisplayLink:(CADisplayLink *)link runloop:(NSRunLoop *)runloop mode:(NSString *)mode
{
    [[self installedLinks] addObject:link];
}

+ (void)uninstallDisplayLink:(CADisplayLink *)link runloop:(NSRunLoop *)runloop mode:(NSString *)mode
{
    [[self installedLinks] removeObject:link];
}


#pragma mark -

- (void)dealloc
{
    [_timer invalidate];
    [_timer release];
    
    [_target release];
    
    [super dealloc];
}

+ (CADisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)sel
{
    CADisplayLink *d = [[self alloc] initWithTarget:target selector:sel];
    
    return [d autorelease];
}

- (instancetype)initWithTarget:(id)target selector:(SEL)sel
{
    self = [super init];
    if (self) {
        _target = [target retain];
        _sel = sel;
    }
    return self;
}

- (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSString *)mode
{
    [[self class] installDisplayLink:self runloop:runloop mode:mode];
    return;
    
    [self cleanTimer];
    _timer = [[NSTimer alloc] initWithFireDate:nil
                                              interval:0
                                                target:self
                                              selector:@selector(fire)
                                              userInfo:nil
                                               repeats:YES];
    
    [runloop addTimer:_timer forMode:mode];
}

- (void)fire
{
    //if display wait notify
    // call target
}

- (void)cleanTimer
{
    if (_timer) {
        [_timer invalidate];
        [_timer release];
        _timer = nil;
    }
}

- (void)removeFromRunLoop:(NSRunLoop *)runloop forMode:(NSString *)mode
{
    [[self class] uninstallDisplayLink:self runloop:runloop mode:mode];
    return;
    
    [self cleanTimer];
}

- (void)invalidate
{
    [_timer invalidate];
}


@end
