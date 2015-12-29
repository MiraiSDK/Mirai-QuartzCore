//
//  TNLayerMaskTestViewController.m
//  QuartzCoreDemo
//
//  Created by TaoZeyu on 15/10/30.
//  Copyright © 2015年 Shanghai TinyNetwork Inc. All rights reserved.
//

#import "TNLayerImageMaskTestViewController.h"

@implementation TNLayerImageMaskTestViewController

+ (NSString *)testName
{
    return @"CALayer UIImage mask";
}

+ (void)load
{
    [self regisiterTestClass:self];
}

- (UIImage *)generateImage
{
    return [UIImage imageNamed:@"umaru.jpg"];
}

- (UIView *)generateDemoView
{
    UIImage *image = [self demoImage];
    UIImageView *demoView = [[UIImageView alloc] initWithImage:image];
    [demoView setFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    return demoView;
}

- (UIView *)generateMaskView
{
    UIImage *image = [self demoImage];
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5] CGColor]);
    CGContextFillRect(context, rect);
    CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:1 green:1 blue:0 alpha:1] CGColor]);
    CGContextFillRect(context, CGRectMake(rect.size.width/4, rect.size.height/4,
                                          rect.size.width/2, rect.size.height/2));
    UIImage *maskImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIView *maskView = [[UIImageView alloc] initWithImage:maskImage];
    [maskView setFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    return maskView;
}

@end
