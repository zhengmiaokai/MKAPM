//
//  CatchANR.m
//  Basic
//
//  Created by zhengmiaokai on 2019/6/27.
//  Copyright © 2019 zhengmiaokai. All rights reserved.
//

#import "CatchANR.h"
#import <execinfo.h>
#import <CrashReporter/CrashReporter.h>

static int kTimeoutInterval = 400;  // 单次定时器触发时间（毫秒）
static int kTimeoutCount = 5;       // 定时器触发次数，卡顿阈值：timeoutInterval * timeoutCount

@interface CatchANR () {
    CFRunLoopObserverRef _observer;
    dispatch_semaphore_t _semaphore;
    CFRunLoopActivity _activity;
    int _timeoutCount;
}

@end

@implementation CatchANR

+ (instancetype)shareInstance {
    static CatchANR *instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
        instance->_semaphore = dispatch_semaphore_create(0);
    });
    return instance;
}

static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    CatchANR* instance = (__bridge CatchANR*)info;
    instance->_activity = activity;
    
    dispatch_semaphore_t semaphore = instance->_semaphore;
    dispatch_semaphore_signal(semaphore);
}

- (void)startMonitoring {
    if (_observer) {
        return;
    }
    
    CFRunLoopObserverContext context = {0, (__bridge void *)self, NULL, NULL};
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                        kCFRunLoopAllActivities,
                                        YES,
                                        0,
                                        &runLoopObserverCallBack,
                                        &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (self->_observer != NULL) {
            // 间隔大于kTimeoutInterval，err!=0
            long err = dispatch_semaphore_wait(self->_semaphore, dispatch_time(DISPATCH_TIME_NOW, kTimeoutInterval * NSEC_PER_MSEC));
            if (err != 0) {
                if (self->_activity == kCFRunLoopBeforeSources || self->_activity == kCFRunLoopAfterWaiting) { // BeforeSources-即将处理事件 | AfterWaiting-从休眠中唤醒
                    if (++self->_timeoutCount < kTimeoutCount) {
                        continue;
                    }
                    
                    // 上报堆栈信息
                    [self reportStackInfo];
                }
            }
            self->_timeoutCount = 0;
        }
    });
}

- (void)stopMonitoring {
    _activity = 0;
    _timeoutCount = 0;
    
    if (_observer) {
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
        CFRelease(_observer);
        _observer = NULL;
    }
}

- (void)reportStackInfo {
    PLCrashReporterConfig *config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeMach // 完整线程上下文
                                                                       symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll]; // 在Release环境下无效
    PLCrashReporter *crashReporter = [[PLCrashReporter alloc] initWithConfiguration:config];
    
    NSData *data = [crashReporter generateLiveReport];
    PLCrashReport *crashReport = [[PLCrashReport alloc] initWithData:data error:NULL];
    NSString *stackInfo = [PLCrashReportTextFormatter stringValueForCrashReport:crashReport
                                                              withTextFormat:PLCrashReportTextFormatiOS];
    
    NSLog(@"%@", stackInfo);
}

@end
