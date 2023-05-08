//
//  CatchFPS.m
//  Basic
//
//  Created by zhengmika on 2019/6/27.
//  Copyright © 2019 zhengmiaokai. All rights reserved.
//

#import "CatchFPS.h"

@interface CatchFPS ()

@property (nonatomic, strong)  CADisplayLink *displayLink;

/// 每秒刷新的次数
@property (nonatomic, assign)  int timeCount;

/// 统计每秒FPS的开始时间
@property (nonatomic, assign)  NSTimeInterval beginTime;

@end

@implementation CatchFPS

+ (instancetype)shareInstance {
    static CatchFPS *instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)startMonitoring {
    if (!_displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTick:)];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)stopMonitoring {
    if (_displayLink) {
        [_displayLink invalidate];
        self.displayLink = nil;
    }
}

#pragma mark - Event Handle -
- (void)displayLinkTick:(CADisplayLink *)link {
    if (_beginTime == 0) {
        self.beginTime = link.timestamp;
        return;
    }
    
    self.timeCount++;
    
    NSTimeInterval interval = link.timestamp - _beginTime;
    if (interval < 1) { //每秒
        return;
    }

    float fps = _timeCount / interval;
    if (_FPSBlock != nil) {
        _FPSBlock(fps);
    }
    
    self.beginTime = link.timestamp;
    self.timeCount = 0;
}

- (void)dealloc {
    [self stopMonitoring];
}

@end
