//
//  MKURLSessionDelegate.h
//  Basic
//
//  Created by mikazheng on 2019/11/13.
//  Copyright © 2019 zhengmiaokai. All rights reserved.
//

/****** AOP替换NSURLSession的delegate，实现协议方法的替换 ******/

#import "MKProxy.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKURLSessionDelegate : MKProxy

@end

NS_ASSUME_NONNULL_END
