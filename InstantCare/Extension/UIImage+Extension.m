//
//  UIImage+Extension.m
//  InstantCare
//
//  Created by 朱正晶 on 15/12/6.
//  Copyright © 2015年 omg. All rights reserved.
//

#import "UIImage+Extension.h"

@implementation UIImage (Extension)

+ (UIImage *)imageWithColor:(UIColor *)color
{
    CGFloat imageW = 100;
    CGFloat imageH = 100;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(imageW, imageH), NO, 0.0);
    
    [color set];
    UIRectFill(CGRectMake(0, 0, imageW, imageH));
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

@end
