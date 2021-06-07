//
//  UIColor+Addition.h
//  Basic
//
//  Created by zhengmiaokai on 2018/6/21.
//  Copyright © 2018年 zhengmiaokai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Addition)

/** 生成color
 *  hexString #FFFFFF
 **/
+ (UIColor *)colorWithHexString:(NSString *)hexString;

/** 生成color
 *  hexString #FFFFFF
 *  alpha 透明度
 **/
+ (UIColor *)colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha;

/** 生成color
 *  R、G、B
 **/
+ (UIColor *)colorWithR:(CGFloat)red
                      g:(CGFloat)green
                      b:(CGFloat)blue;

/** 生成color
 *  R、G、B、A
 **/
+ (UIColor *)colorWithR:(CGFloat)red
                      g:(CGFloat)green
                      b:(CGFloat)blue
                  alpha:(CGFloat)alpha;

/** 获取hexString #FFFFFF
 **/
- (NSString *)hexString;

/** 获取RGBA数组 @[NSNumber]
 **/
- (NSArray *)rgbaFromColor;

@end
