//
//  CatchANR.m
//  Basic
//
//  Created by zhengmika on 2019/6/27.
//  Copyright © 2019 zhengmiaokai. All rights reserved.
//

#import "CatchANR.h"
#import <execinfo.h>

static int kTimeoutInterval = 400;  /// 单次定时器触发时间（毫秒）
static int kTimeoutCount = 5;       /// 定时器触发次数，卡顿阈值：timeoutInterval * timeoutCount

@interface CatchANR () {
    int _timeoutCount;
    CFRunLoopObserverRef _observer;
    dispatch_semaphore_t _semaphore;
    CFRunLoopActivity _activity;
}

@end

@implementation CatchANR

+ (instancetype)shareInstance {
    static CatchANR *instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    CatchANR* catchANR = (__bridge CatchANR*)info;
    catchANR->_activity = activity;
    
    dispatch_semaphore_t semaphore = catchANR->_semaphore;
    dispatch_semaphore_signal(semaphore);
}

- (void)startMonitoring {
    if (_observer) {
        return;
    }
    
    _semaphore = dispatch_semaphore_create(0);
    
    CFRunLoopObserverContext context = {0, (__bridge void *)self, NULL, NULL};
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                        kCFRunLoopAllActivities,
                                        YES,
                                        0,
                                        &runLoopObserverCallBack,
                                        &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (YES) {
            /// 间隔大于kTimeoutInterval，err!=0
            long err = dispatch_semaphore_wait(self->_semaphore, dispatch_time(DISPATCH_TIME_NOW, kTimeoutInterval * NSEC_PER_MSEC));
            if (err != 0) {
                if (!self->_observer) {
                    self->_timeoutCount = 0;
                    self->_semaphore = 0;
                    self->_activity = 0;
                    return;
                }
                
                if (self->_activity == kCFRunLoopBeforeSources || self->_activity == kCFRunLoopAfterWaiting) {
                    if (++self->_timeoutCount < kTimeoutCount) {
                        continue;
                    }
                    // 上报导致卡顿的堆栈信息
                    [self performSelectorOnMainThread:@selector(reportStackInfo) withObject:nil waitUntilDone:NO];
                }
            }
            self->_timeoutCount = 0;
        }
    });
}

- (void)stopMonitoring {
    if (!_observer) {
        return;
    }
    
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    CFRelease(_observer);
    _observer = NULL;
}

- (void)reportStackInfo {
    void *callstack[128];
    int frames = backtrace(callstack, 128);
    char **cbacktrace = backtrace_symbols(callstack, frames);
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    
    // 第一行为reportStackInfo的调用堆栈
    for (int i=1 ; i<frames; i++) {
        [backtrace addObject:[NSString stringWithUTF8String:cbacktrace[i]]];
    }
    free(cbacktrace);
    
    NSLog(@"Exception StackSymbols: %@\n", [backtrace description]);
}

@end
