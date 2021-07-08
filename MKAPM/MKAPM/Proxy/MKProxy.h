//
//  MKProxy.h
//  Basic
//
//  Created by mikazheng on 2019/11/13.
//  Copyright © 2019 zhengmiaokai. All rights reserved.
//

/****** Proxy基类，可以实现delegate的AOP（面向切面编程）<如果target实现了respondsToSelector方法，子类实现respondsToSelector时需要注意方法兼容> ******/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKProxy : NSProxy

@property (nonatomic, weak) id target;

- (instancetype)initWithTarget:(id)target;

@end

NS_ASSUME_NONNULL_END
