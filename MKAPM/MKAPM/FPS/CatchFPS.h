//
//  CatchFPS.h
//  Basic
//
//  Created by zhengmika on 2019/6/27.
//  Copyright © 2019 zhengmiaokai. All rights reserved.
//
#import <UIKit/UIKit.h>

typedef void(^CatchFPSBlock)(float fps);

@interface CatchFPS : NSObject

@property (nonatomic, copy) CatchFPSBlock FPSBlock;

+ (instancetype)shareInstance;

- (void)startMonitoring;

- (void)pauseMonitoring;

- (void)removeMonitoring;

@end
