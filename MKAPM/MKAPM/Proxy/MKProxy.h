//
//  MKProxy.h
//  Basic
//
//  Created by zhengmiaokai on 2019/11/13.
//  Copyright © 2019 zhengmiaokai. All rights reserved.
//

/** Proxy基类：delegate的切面编程、代理对象的弱引用 <如果target实现了respondsToSelector方法，子类重写respondsToSelector需要注意兼容性> **/

#import <Foundation/Foundation.h>

@interface MKProxy : NSProxy

@property (nonatomic, weak) id target;

- (instancetype)initWithTarget:(id)target;

@end
