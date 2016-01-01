//
//  TNDrawImageView.m
//  QuartzCoreDemo
//
//  Created by TaoZeyu on 15/12/29.
//  Copyright © 2015年 Shanghai TinyNetwork Inc. All rights reserved.
//

#import "TNDrawImageView.h"

@implementation TNDrawImageView
{
    UIImage *_image;
}

- (instancetype)initWithImage:(UIImage *)image
{
    if (self = [self initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)]) {
        _image = image;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, [[UIColor clearColor] CGColor]);
    CGContextFillRect(ctx, CGRectMake(0, 0, _image.size.width, _image.size.height));
    CGContextDrawImage(ctx, CGRectMake(0, 0, _image.size.width, _image.size.height), [_image CGImage]);
}

@end
