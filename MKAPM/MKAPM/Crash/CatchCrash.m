//
//  CatchCrash.m
//  Basic
//
//  Created by zhengmiaokai on 15/11/23.
//  Copyright © 2015年 zhengmiaokai. All rights reserved.
//

#import "CatchCrash.h"
#import <sys/sysctl.h>
#import <CrashReporter/CrashReporter.h>

static NSUncaughtExceptionHandler *previousUncaughtExceptionHandler = NULL;

@implementation CatchCrash

+ (void)startMonitoring {
    [self setUncaughtExceptionHandler];
    [self setSignalExceptionHandler];
    
    /* 使用PLCrashReporter采集（Uncaught & Signal）
     [self initializeCrashReporter];
     */
}

+ (void)stopMonitoring {
    [self resetUncaughtExceptionHandler];
    [self resetSignalExceptionHanlder];
}

#pragma mark - Uncaught & Signal -
+ (void)setUncaughtExceptionHandler {
    previousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
    
    NSSetUncaughtExceptionHandler(&uncaught_exception_handler);
}

+ (void)resetUncaughtExceptionHandler {
    NSSetUncaughtExceptionHandler(previousUncaughtExceptionHandler);
}

+ (void)setSignalExceptionHandler {
    if (debugger_should_exit()) return; // 采集signal异常需要断开调试
    
    signal(SIGSEGV, signal_exception_handler);
    signal(SIGFPE, signal_exception_handler);
    signal(SIGBUS, signal_exception_handler);
    signal(SIGTRAP, signal_exception_handler);
    signal(SIGABRT, signal_exception_handler);
    signal(SIGILL, signal_exception_handler);
    signal(SIGPIPE, signal_exception_handler);
    signal(SIGSYS, signal_exception_handler);
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

static void uncaught_exception_handler(NSException *exception) {
    NSArray *stackSymbols = [exception callStackSymbols];
    NSString *name = [exception name];
    NSString *reason = [exception reason];
    NSString *exceptionInfo = [NSString stringWithFormat:@"Uncaught Exception Name: %@\nReason: %@\nStackSymbols: %@", name, reason, stackSymbols];
    
    // 先保存到本地，等下次启动再上传日志
    NSString *filePath = [NSString stringWithFormat:@"%@/Documents/uncaught-exception.log", NSHomeDirectory()];
    [exceptionInfo writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // 调用之前崩溃的回调函数
    if (previousUncaughtExceptionHandler) {
        previousUncaughtExceptionHandler(exception);
    }
    
    // 杀掉程序，防止同时抛出的SIGABRT被SignalException捕获
    kill(getpid(), SIGKILL);
}

static void signal_exception_handler(int signal) {
    PLCrashReporterConfig *config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeMach // 完整线程上下文
                                                                       symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll]; // 在Release环境下无效
    PLCrashReporter *crashReporter = [[PLCrashReporter alloc] initWithConfiguration:config];
    
    NSData *data = [crashReporter generateLiveReport];
    PLCrashReport *crashReport = [[PLCrashReport alloc] initWithData:data error:nil];
    NSString *exceptionInfo = [PLCrashReportTextFormatter stringValueForCrashReport:crashReport withTextFormat:PLCrashReportTextFormatiOS];
    
    // 先保存到本地，等下次启动再上传日志
    NSString *filePath = [NSString stringWithFormat:@"%@/Documents/signal-exception.log", NSHomeDirectory()];
    [exceptionInfo writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // 杀掉程序，防止同时抛出的SIGABRT被SignalException捕获
    kill(getpid(), SIGKILL);
}

#pragma mark - PLCrashReporter -
+ (void)initializeCrashReporter {
    if (debugger_should_exit()) return; // 采集signal异常需要断开调试
    
    PLCrashReporterConfig *config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeMach // 完整线程上下文
                                                                       symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll]; // 在Release环境下无效
    PLCrashReporter *crashReporter = [[PLCrashReporter alloc] initWithConfiguration:config];
    
    // 是否有待处理的崩溃报告
    if ([crashReporter hasPendingCrashReport]) {
        [self handlePendingCrashReport:crashReporter];
    }
    
    PLCrashReporterCallbacks callbacks = {
        .version = 0,
        .context = (void *) 0xABABABAB,
        .handleSignal = crash_reporter_handler
    };
    [crashReporter setCrashCallbacks:&callbacks];
    
    // 启用崩溃采集
    [crashReporter enableCrashReporter];
}

+ (void)handlePendingCrashReport:(PLCrashReporter *)crashReporter {
    NSData *data = [crashReporter loadPendingCrashReportDataAndReturnError:nil];
    PLCrashReport *crashReport = [[PLCrashReport alloc] initWithData:data error:nil];
    NSString *exceptionInfo = [PLCrashReportTextFormatter stringValueForCrashReport:crashReport withTextFormat:PLCrashReportTextFormatiOS];
    
    // 处理崩溃报告（本地储存 | 日志上传）
    NSString *filePath = [NSString stringWithFormat:@"%@/Documents/crashReport-exception.log", NSHomeDirectory()];
    [exceptionInfo writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // 清除已处理的崩溃报告
    [crashReporter purgePendingCrashReport];
}

static void crash_reporter_handler (siginfo_t *info, ucontext_t *uap, void *context) {
    NSLog(@"crash_reporter_handler: signo-%d, uap-%p, context-%p", info->si_signo, uap, context);
}

static bool debugger_should_exit(void) {
    struct kinfo_proc info;
    size_t info_size = sizeof(info);
    int name[4];
    
    name[0] = CTL_KERN;
    name[1] = KERN_PROC;
    name[2] = KERN_PROC_PID;
    name[3] = getpid();
    
    if (sysctl(name, 4, &info, &info_size, NULL, 0) == -1) {
        return false;
    }

    if ((info.kp_proc.p_flag & P_TRACED) != 0) {
        return true;
    }
    
    return false;
}

@end
