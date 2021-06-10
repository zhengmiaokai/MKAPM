//
//  CatchANR.m
//  Basic
//
//  Created by zhengmika on 2019/6/27.
//  Copyright © 2019 zhengmiaokai. All rights reserved.
//

#import "CatchANR.h"
#import <libkern/OSAtomic.h>
#import <execinfo.h>
#import <CrashReporter/CrashReporter.h>

static int kTimeoutInterval = 400;  /// 单次定时器触发时间（毫秒）
static int kTimeoutCount = 5;       /// 定时器触发次数，总时间为timeout * timeoutCount

@interface CatchANR () {
    int _timeoutCount;
    CFRunLoopObserverRef _observer;
    
    @public
    dispatch_semaphore_t _semaphore;
    CFRunLoopActivity _activity;
}

@end

@implementation CatchANR

+ (instancetype)shareInstance {
    static CatchANR *mgr = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        mgr = [[self alloc] init];
    });
    return mgr;
}

static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    CatchANR* catchANR = (__bridge CatchANR*)info;
    catchANR->_activity = activity;
    
    dispatch_semaphore_t semaphore = catchANR->_semaphore;
    dispatch_semaphore_signal(semaphore);
}

- (void)endListen {
    if (!_observer) {
        return;
    }
    
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    CFRelease(_observer);
    _observer = NULL;
}

- (void)startListen {
    if (_observer) {
        return;
    }
    
    _semaphore = dispatch_semaphore_create(0);
    
    CFRunLoopObserverContext context = {0,(__bridge void*)self,NULL,NULL};
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                        kCFRunLoopAllActivities,
                                        YES,
                                        0,
                                        &runLoopObserverCallBack,
                                        &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (YES) {
            /// 如果间隔大于kTimeoutInterval，st!=0
            long st = dispatch_semaphore_wait(self->_semaphore, dispatch_time(DISPATCH_TIME_NOW, kTimeoutInterval * NSEC_PER_MSEC));
            if (st != 0) {
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
                    [self crashReporter];
                    /* [self logStack]; */
                }
            }
            self->_timeoutCount = 0;
        }
    });
}

- (void)crashReporter {
    PLCrashReporterConfig *config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeBSD symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll];
    PLCrashReporter *crashReporter = [[PLCrashReporter alloc] initWithConfiguration:config];
    
    NSData *data = [crashReporter generateLiveReport];
    PLCrashReport *reporter = [[PLCrashReport alloc] initWithData:data error:NULL];
    NSString *report = [PLCrashReportTextFormatter stringValueForCrashReport:reporter withTextFormat:PLCrashReportTextFormatiOS];
    NSLog(@"[self crashReporter]:%@\n", report);
}

- (void)logStack {
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    int i;
    NSMutableArray* backtrace = [NSMutableArray arrayWithCapacity:frames];
    for ( i = 0 ; i < frames ; i++ ){
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    NSLog(@"[self logStack]:%@\n", [backtrace description]);
}

@end
