//
//  TNBasicLayerMaskTestViewController.m
//  QuartzCoreDemo
//
//  Created by TaoZeyu on 15/12/29.
//  Copyright © 2015年 Shanghai TinyNetwork Inc. All rights reserved.
//

#import "TNBasicLayerMaskTestViewController.h"

@implementation TNBasicLayerMaskTestViewController

{
    CALayer *_demoLayer;
    CALayer *_maskLayer;
    UIView *_maskView;
    UIImage *_image;
}

- (UIView *)generateDemoView
{
    return nil; // To be override.
}

- (UIView *)generateMaskView
{
    return nil; // To be override.
}

- (UIImage *)generateImage
{
    return nil; // To be override.
}

- (UIImage *)demoImage
{
    if (!_image) {
        _image = [self generateImage];
    }
    return _image;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *demoView = [self generateDemoView];
    [demoView setFrame:CGRectMake(5, 220, demoView.bounds.size.width, demoView.bounds.size.height)];
    
    _maskView = [self generateMaskView];
    [_maskView setFrame:CGRectMake(0, 0, demoView.bounds.size.width, demoView.bounds.size.height)];
    
    _demoLayer = demoView.layer;
    _maskLayer = _maskView.layer;
    _demoLayer.mask = _maskLayer;
    
    UIButton *moveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [moveButton setFrame:CGRectMake(10, demoView.bounds.size.height + 250, 200, 100)];
    [moveButton setTitle:@"MOVE" forState:UIControlStateNormal];
    [moveButton addTarget:self action:@selector(_onClickMoveButton:)
         forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [resetButton setFrame:CGRectMake(250, demoView.bounds.size.height + 250, 200, 100)];
    [resetButton setTitle:@"RESET" forState:UIControlStateNormal];
    [resetButton addTarget:self action:@selector(_onClickResetButton:)
          forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:demoView];
    [self.view addSubview:moveButton];
    [self.view addSubview:resetButton];
    
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
