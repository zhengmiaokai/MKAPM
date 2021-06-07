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
    static CatchFPS *mgr = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        mgr = [[self alloc] init];
    });
    return mgr;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTick:)];
        [_displayLink setPaused:YES];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)startMonitoring{
    _displayLink.paused = NO;
}

- (void)pauseMonitoring {
    _displayLink.paused = YES;
}

- (void)removeMonitoring {
    [self pauseMonitoring];
    [_displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [_displayLink invalidate];
}

#pragma mark -- Event Handle

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
    [self removeMonitoring];
}

@end
