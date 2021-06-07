//
//  NSObject+Additions.h
//  Basic
//
//  Created by zhengmiaokai on 16/5/12.
//  Copyright © 2016年 zhengmiaokai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Additions)

+ (void)swizzledClassMethodOriginalSelector:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector;

+ (void)swizzledInstanceMethodOriginalSelector:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector;

@end
