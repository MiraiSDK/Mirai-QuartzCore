//
//  ViewController.m
//  QuartzCoreDemo-iOS
//
//  Created by Chen Yonghui on 6/12/14.
//  Copyright (c) 2014 Shanghai TinyNetwork Inc. All rights reserved.
//

#import "ViewController.h"

#import "QuartzCore/AppleSupport.h"
#import "QuartzCore/QuartzCore.h"

@interface ViewController ()
@property (strong, nonatomic) EAGLContext *context;
@property (nonatomic, strong) CARenderer *renderer;
@property (nonatomic, strong) CALayer *rootLayer;
@property (nonatomic, strong) NSMutableArray *images;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _images = [NSMutableArray array];
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

    CGRect bounds = CGRectZero;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        bounds.size = CGSizeMake(768, 1024);
    } else {
        bounds.size = CGSizeMake(320, 568);
    }
    
    [self buildLayer];
    
    self.renderer = [CARenderer rendererWithEAGLContext:self.context options:nil];
    self.renderer.layer = _rootLayer;
    self.renderer.bounds = bounds;// self.view.bounds;// CGRectMake(0, 0, 320, 320);
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handle_panGesture:)];
    [self.view addGestureRecognizer:pan];
//    [self setupGL];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handle_tapGesture:)];
    [self.view addGestureRecognizer:tap];
    
}

- (void)buildLayer
{
    self.rootLayer = [CALayer layer];
    
    CGRect bounds = CGRectZero;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        bounds.size = CGSizeMake(768, 1024);
    } else {
        bounds.size = CGSizeMake(320, 568);
    }
    
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);
    CGFloat cellHeight = 40;

    _rootLayer.frame = CGRectMake(0, 0, width, height);
    _rootLayer.backgroundColor = [UIColor redColor].CGColor;
    
    for (int i = 0; i < 20; i++) {
        CALayer *subLayer = [CALayer layer];
        subLayer.frame = CGRectMake(0, i * cellHeight, width, cellHeight);
        CGFloat c = (i % 16) / 16.0;
        subLayer.backgroundColor = [UIColor colorWithHue:c saturation:c brightness:1 alpha:1].CGColor;
        
        CALayer *textLayer = [CALayer layer];
        textLayer.frame = subLayer.bounds;
        UIImage *image = [self cellTextContentsAtRow:i size:subLayer.bounds.size];
        [self.images addObject:image];
        textLayer.contents = (__bridge id)(image.CGImage);
        [subLayer addSublayer:textLayer];
        
        [_rootLayer addSublayer:subLayer];
    }
}

- (UIImage *)cellTextContentsAtRow:(NSInteger)idx size:(CGSize)size
{
    CGRect rect = CGRectZero;
    rect.size = size;
    
    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    [[UIColor whiteColor] setFill];
    CGContextFillRect(ctx, rect);
    
    NSString *str = [NSString stringWithFormat:@"Row %d",idx];
//    CGContextFillEllipseInRect(ctx, rect);
    [str drawAtPoint:CGPointZero withAttributes:nil];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

- (void)handle_tapGesture:(UITapGestureRecognizer *)ges
{
    CGRect bounds = _rootLayer.bounds;
    bounds.origin = CGPointZero;
    _rootLayer.bounds = bounds;
}

- (void)handle_panGesture:(UIPanGestureRecognizer *)ges
{
    CGRect bounds = _rootLayer.bounds;

    static CGPoint beginPoint;
    
    switch (ges.state) {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateBegan:{
            beginPoint = bounds.origin;
        } break;
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateEnded: {
            
        } break;
        case UIGestureRecognizerStateCancelled:
            break;
        case UIGestureRecognizerStateFailed:
            break;
            
        default:
            break;
    }
    
    CGPoint trans = [ges translationInView:self.view];
//    bounds.origin.x = beginPoint.x - trans.x;
    bounds.origin.y = beginPoint.y - trans.y;
    
//    trans.x = -trans.x;
//    trans.y = -trans.y;
    
//    b.origin = trans;
    _rootLayer.bounds = bounds;
}

- (void)dealloc
{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
//    [self loadShaders];
    
//    self.effect = [[GLKBaseEffect alloc] init];
//    self.effect.light0.enabled = GL_TRUE;
//    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
//    
//    glEnable(GL_DEPTH_TEST);
//    
//    glGenVertexArraysOES(1, &_vertexArray);
//    glBindVertexArrayOES(_vertexArray);
//    
//    glGenBuffers(1, &_vertexBuffer);
//    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
//    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
//    
//    glEnableVertexAttribArray(GLKVertexAttribPosition);
//    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
//    glEnableVertexAttribArray(GLKVertexAttribNormal);
//    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
//    
//    glBindVertexArrayOES(0);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
//    glDeleteBuffers(1, &_vertexBuffer);
//    glDeleteVertexArraysOES(1, &_vertexArray);
//    
//    self.effect = nil;
//    
//    if (_program) {
//        glDeleteProgram(_program);
//        _program = 0;
//    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
//    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
//    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
//    
//    self.effect.transform.projectionMatrix = projectionMatrix;
//    
//    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
//    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
//    
//    // Compute the model view matrix for the object rendered with GLKit
//    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
//    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
//    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
//    
//    self.effect.transform.modelviewMatrix = modelViewMatrix;
//    
//    // Compute the model view matrix for the object rendered with ES2
//    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
//    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
//    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
//    
//    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
//    
//    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
//    
//    _rotation += self.timeSinceLastUpdate * 0.5f;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [_renderer addUpdateRect:_renderer.layer.bounds];
    [_renderer beginFrameAtTime:CACurrentMediaTime() timeStamp:NULL];
    [_renderer render];
    [_renderer endFrame];
    
//    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
//    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//    
//    glBindVertexArrayOES(_vertexArray);
//    
//    // Render the object with GLKit
//    [self.effect prepareToDraw];
//    
//    glDrawArrays(GL_TRIANGLES, 0, 36);
//    
//    // Render the object again with ES2
//    glUseProgram(_program);
//    
//    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
//    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
//    
//    glDrawArrays(GL_TRIANGLES, 0, 36);
}

@end
