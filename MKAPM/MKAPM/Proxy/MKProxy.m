//
//  MKProxy.m
//  Basic
//
//  Created by mikazheng on 2019/11/13.
//  Copyright © 2019 zhengmiaokai. All rights reserved.
//

#import "MKProxy.h"

@implementation MKProxy

- (instancetype)initWithTarget:(id)target {
    self.target = target;
    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [self.target respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    if (!self.target) {
        return [NSMethodSignature signatureWithObjCTypes:"v@"];
    }
    return [self.target methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}

@end
