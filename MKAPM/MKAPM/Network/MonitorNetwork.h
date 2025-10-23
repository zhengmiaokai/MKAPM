//
//  MonitorNetwork.h
//  Basic
//
//  Created by zhengmiaokai on 2021/6/1.
//  Copyright © 2021 zhengmiaokai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MonitorNetwork : NSObject <NSURLSessionDataDelegate>

+ (void)startMonitoring;

@end
