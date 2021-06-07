//
//  MonitorNetwork.h
//  Basic
//
//  Created by mikazheng on 2021/6/1.
//  Copyright © 2021 zhengmiaokai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MonitorNetwork : NSObject <NSURLSessionDataDelegate>

+ (void)startHook;

@end

NS_ASSUME_NONNULL_END
