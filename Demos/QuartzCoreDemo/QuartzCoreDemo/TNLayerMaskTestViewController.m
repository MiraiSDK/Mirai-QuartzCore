//
//  TNLayerMaskTestViewController.m
//  QuartzCoreDemo
//
//  Created by TaoZeyu on 15/10/30.
//  Copyright © 2015年 Shanghai TinyNetwork Inc. All rights reserved.
//

#import "TNLayerMaskTestViewController.h"

@implementation TNLayerMaskTestViewController
{
    CALayer *_demoLayer;
    CALayer *_maskLayer;
}
+ (NSString *)testName
{
    return @"CALayer mask";
}

+ (void)load
{
    [self regisiterTestClass:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *image = [UIImage imageNamed:@"umaru.jpg"];
    UIImageView *demoView = [[UIImageView alloc] initWithImage:image];
    [demoView setFrame:CGRectMake(5, 220, image.size.width, image.size.height)];
    [self.view addSubview:demoView];
    
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5] CGColor]);
    CGContextFillRect(context, rect);
    CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:1 green:1 blue:0 alpha:1] CGColor]);
    CGContextFillEllipseInRect(context, rect);
    UIImage *maskImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *maskView = [[UIImageView alloc] initWithImage:maskImage];
    [maskView setFrame:CGRectMake(0, 0, demoView.bounds.size.width, demoView.bounds.size.height)];
    
    _demoLayer = demoView.layer;
    _maskLayer = maskView.layer;
    
    _demoLayer.mask = _maskLayer;
    
    UIButton *moveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.view addSubview:moveButton];
    [moveButton setFrame:CGRectMake(10, image.size.height + 250, 200, 100)];
    [moveButton setTitle:@"MOVE" forState:UIControlStateNormal];
    [moveButton addTarget:self action:@selector(_onClickMoveButton:)
     forControlEvents:UIControlEventTouchUpInside];
    
    
    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.view addSubview:resetButton];
    [resetButton setFrame:CGRectMake(250, image.size.height + 250, 200, 100)];
    [resetButton setTitle:@"RESET" forState:UIControlStateNormal];
    [resetButton addTarget:self action:@selector(_onClickResetButton:)
     forControlEvents:UIControlEventTouchUpInside];
}

- (void)_onClickMoveButton:(id)sender
{
    _maskLayer.frame = CGRectMake(50, 50, _maskLayer.bounds.size.width, _maskLayer.bounds.size.height);
}

- (void)_onClickResetButton:(id)sender
{
    _maskLayer.frame = CGRectMake(0, 0, _maskLayer.bounds.size.width, _maskLayer.bounds.size.height);
}

@end
