//
//  CatchCrash.m
//  Basic
//
//  Created by zhengmiaokai on 15/11/23.
//  Copyright © 2015年 zhengmiaokai. All rights reserved.
//

#import "CatchCrash.h"
#import <CrashReporter/CrashReporter.h>

static NSUncaughtExceptionHandler *previousUncaughtExceptionHandler = NULL;

@implementation CatchCrash

+ (void)startMonitoring {
    [self setUncaughtExceptionHandler];
    [self setSignalExceptionHandler];
}

+ (void)stopMonitoring {
    [self resetUncaughtExceptionHandler];
    [self resetSignalExceptionHanlder];
}

+ (void)setUncaughtExceptionHandler {
    previousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
    
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
}

+ (void)resetUncaughtExceptionHandler {
    NSSetUncaughtExceptionHandler(previousUncaughtExceptionHandler);
}

+ (void)setSignalExceptionHandler {
    signal(SIGSEGV, signalExceptionHandler);
    signal(SIGFPE, signalExceptionHandler);
    signal(SIGBUS, signalExceptionHandler);
    signal(SIGTRAP, signalExceptionHandler);
    signal(SIGABRT, signalExceptionHandler);
    signal(SIGILL, signalExceptionHandler);
    signal(SIGPIPE, signalExceptionHandler);
    signal(SIGSYS, signalExceptionHandler);
}

+ (void)resetSignalExceptionHanlder {
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGTRAP, SIG_DFL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    signal(SIGSYS, SIG_DFL);
}

static void uncaughtExceptionHandler(NSException *exception) {
    NSArray *stackSymbols = [exception callStackSymbols];
    NSString *name = [exception name];
    NSString *reason = [exception reason];
    NSString *exceptionInfo = [NSString stringWithFormat:@"Uncaught Exception Name: %@\nReason: %@\nStackSymbols: %@", name, reason, stackSymbols];
    
    // 保存到本地 - 在下次启动的时候，上传这个log
    NSString *filePath = [NSString stringWithFormat:@"%@/Documents/uncaught-exception.log", NSHomeDirectory()];
    [exceptionInfo writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // 调用之前崩溃的回调函数
    if (previousUncaughtExceptionHandler) {
        previousUncaughtExceptionHandler(exception);
    }
    
    // 杀掉程序，防止同时抛出的SIGABRT被SignalException捕获
    kill(getpid(), SIGKILL);
}

static void signalExceptionHandler(int signal) {
    PLCrashReporterConfig *config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeMach // 完整线程上下文
                                                                       symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll]; // 在Release环境下无效
    PLCrashReporter *crashReporter = [[PLCrashReporter alloc] initWithConfiguration:config];
    
    NSData *data = [crashReporter generateLiveReport];
    PLCrashReport *crashReport = [[PLCrashReport alloc] initWithData:data error:NULL];
    NSString *exceptionInfo = [PLCrashReportTextFormatter stringValueForCrashReport:crashReport withTextFormat:PLCrashReportTextFormatiOS];
    
    //保存到本地 - 在下次启动的时候，上传这个log
    NSString *filePath = [NSString stringWithFormat:@"%@/Documents/signal-exception.log", NSHomeDirectory()];
    [exceptionInfo writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // 杀掉程序，防止同时抛出的SIGABRT被SignalException捕获
    kill(getpid(), SIGKILL);
}

@end
