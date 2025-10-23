//
//  MKHookUtil.m
//  Basic
//
//  Created by zhengmiaokai on 16/9/10.
//  Copyright © 2016年 zhengmiaokai. All rights reserved.
//

#import "MKHookUtil.h"
#import <objc/runtime.h>

@implementation MKHookUtil

+ (void)swizzledInstanceImplementationOfClass:(Class)cls
                    originalSelector:(SEL)originalSelector
                    swizzledSelector:(SEL)swizzledSelector {
    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(cls, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(cls, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (void)swizzledClassImplementationOfClass:(Class)cls
                    originalSelector:(SEL)originalSelector
                    swizzledSelector:(SEL)swizzledSelector {
    
    Class isaCls = objc_getMetaClass(class_getName(cls));
    
    /* MetaClass元类的class_getInstanceMethod与class_getClassMethod函数返回结果相同 */
    Method originalMethod = class_getInstanceMethod(isaCls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(isaCls, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(isaCls, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(isaCls, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (SEL)swizzledSelectorForSelector:(SEL)selector {
    
    if (!selector) {
        return nil;
    }
    SEL swizzleSelector = NSSelectorFromString([NSString stringWithFormat:@"mk_swizzled_%@", NSStringFromSelector(selector)]);
    
    return swizzleSelector;
}

+ (void)replaceImplementationOfKnownSelector:(SEL)selector
                            swizzledSelector:(SEL)swizzledSelector
                                         cls:(Class)cls
                         implementationBlock:(id)implementationBlock  {
    
    if (!selector || !cls || !implementationBlock || !swizzledSelector) {
        return;
    }
    
    Method originalMethod = class_getInstanceMethod(cls, selector);
    if (!originalMethod) {
        return;
    }
    
    IMP implementation = imp_implementationWithBlock(implementationBlock);
    class_addMethod(cls, swizzledSelector, implementation, method_getTypeEncoding(originalMethod));
    Method newMethod = class_getInstanceMethod(cls, swizzledSelector);
    method_exchangeImplementations(originalMethod, newMethod);
}

+ (void)replaceImplementationOfSelector:(SEL)selector
                               swizzledSelector:(SEL)swizzledSelector
                                            cls:(Class)cls
                              methodDescription:(struct objc_method_description)methodDescription
                            implementationBlock:(id)implementationBlock
                                 undefinedBlock:(id)undefinedBlock {
    
    if (!selector || !swizzledSelector || !cls || !implementationBlock || !undefinedBlock) {
        return;
    }
    
    if ([self p_instanceRespondsButDoesNotImplementSelector:selector class:cls]) {
        return;
    }
    
    IMP implementation = imp_implementationWithBlock((id)([cls instancesRespondToSelector:selector] ? implementationBlock : undefinedBlock));
    
    Method oldMethod = class_getInstanceMethod(cls, selector);
    if (oldMethod) {
        class_addMethod(cls, swizzledSelector, implementation, methodDescription.types);
        
        Method newMethod = class_getInstanceMethod(cls, swizzledSelector);
        
        method_exchangeImplementations(oldMethod, newMethod);
    } else {
        class_addMethod(cls, selector, implementation, methodDescription.types);
    }
}

+ (BOOL)p_instanceRespondsButDoesNotImplementSelector:(SEL)selector class:(Class)cls{
    
    if (!selector || !cls) {
        return NO;
    }
    
    if ([cls instancesRespondToSelector:selector]) {
        unsigned int numMethods = 0;
        Method *methods = class_copyMethodList(cls, &numMethods);
        
        BOOL implementsSelector = NO;
        for (int index = 0; index < numMethods; index++) {
            SEL methodSelector = method_getName(methods[index]);
            if (selector == methodSelector) {
                implementsSelector = YES;
                break;
            }
        }
        free(methods);
        
        if (!implementsSelector) {
            return YES;
        }
    }
    return NO;
}

@end
