//
//  MKHookUtil.h
//  Basic
//
//  Created by zhengmiaokai on 16/9/10.
//  Copyright © 2016年 zhengmiaokai. All rights reserved.
//  hook工具类

#import <Foundation/Foundation.h>

@interface MKHookUtil : NSObject

+ (void)swizzledInstanceImplementationOfClass:(Class)cls
                    originalSelector:(SEL)originalSelector
                    swizzledSelector:(SEL)swizzledSelector;

+ (void)swizzledClassImplementationOfClass:(Class)cls
                    originalSelector:(SEL)originalSelector
                    swizzledSelector:(SEL)swizzledSelector;

+ (SEL)swizzledSelectorForSelector:(SEL)selector;

+ (void)replaceImplementationOfKnownSelector:(SEL)selector
                            swizzledSelector:(SEL)swizzledSelector
                                         cls:(Class)cls
                         implementationBlock:(id)implementationBlock;

+ (void)replaceImplementationOfSelector:(SEL)selector
                               swizzledSelector:(SEL)swizzledSelector
                                            cls:(Class)cls
                              methodDescription:(struct objc_method_description)methodDescription
                            implementationBlock:(id)implementationBlock
                                 undefinedBlock:(id)undefinedBlock;

@end
