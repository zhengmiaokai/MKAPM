//
//  CatchANR.h
//  Basic
//
//  Created by zhengmika on 2019/6/27.
//  Copyright © 2019 zhengmiaokai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CatchANR : NSObject

+ (instancetype)shareInstance;

- (void)startMonitoring;

- (void)stopMonitoring;

@end
