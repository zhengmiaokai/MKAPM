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

typedef void (*SignalExceptionHandler)(int signal, siginfo_t *info, void *context);

static SignalExceptionHandler previousSEGVSignalHandler = NULL;
static SignalExceptionHandler previousFPESignalHandler  = NULL;
static SignalExceptionHandler previousBUSSignalHandler  = NULL;
static SignalExceptionHandler previousTRAPSignalHandler = NULL;
static SignalExceptionHandler previousABRTSignalHandler = NULL;
static SignalExceptionHandler previousILLSignalHandler  = NULL;
static SignalExceptionHandler previousPIPESignalHandler = NULL;
static SignalExceptionHandler previousSYSSignalHandler  = NULL;

@implementation CatchCrash

+ (void)startMonitoring {
    setUncaughtExceptionHandler();
    setSignalExceptionHandler();
    
    /* 使用PLCrashReporter采集（Uncaught & Signal）
     initializeCrashReporter();
     */
}

+ (void)stopMonitoring {
    resetUncaughtExceptionHandler();
    resetSignalExceptionHanlder();
}

#pragma mark - Uncaught & Signal -
static void setUncaughtExceptionHandler(void) {
    previousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
    
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
}

static void resetUncaughtExceptionHandler(void) {
    NSSetUncaughtExceptionHandler(previousUncaughtExceptionHandler);
}

static void setSignalExceptionHandler(void) {
    if (debuggerShouldExit()) return; // 采集signal异常需要断开调试
    
    backupPreviousSignalHandlers();
    
    signalRegister(SIGSEGV, signalExceptionHandler);
    signalRegister(SIGFPE, signalExceptionHandler);
    signalRegister(SIGBUS, signalExceptionHandler);
    signalRegister(SIGTRAP, signalExceptionHandler);
    signalRegister(SIGABRT, signalExceptionHandler);
    signalRegister(SIGILL, signalExceptionHandler);
    signalRegister(SIGPIPE, signalExceptionHandler);
    signalRegister(SIGSYS, signalExceptionHandler);
}

static void resetSignalExceptionHanlder(void) {
    if (previousSEGVSignalHandler) {
        signalRegister(SIGSEGV, previousSEGVSignalHandler);
    } else {
        signal(SIGSEGV, SIG_DFL);
    }
    
    if (previousFPESignalHandler) {
        signalRegister(SIGFPE, previousFPESignalHandler);
    } else {
        signal(SIGFPE, SIG_DFL);
    }
    
    if (previousBUSSignalHandler) {
        signalRegister(SIGBUS, previousBUSSignalHandler);
    } else {
        signal(SIGBUS, SIG_DFL);
    }
    
    if (previousTRAPSignalHandler) {
        signalRegister(SIGTRAP, previousTRAPSignalHandler);
    } else {
        signal(SIGTRAP, SIG_DFL);
    }
    
    if (previousABRTSignalHandler) {
        signalRegister(SIGABRT, previousABRTSignalHandler);
    } else {
        signal(SIGABRT, SIG_DFL);
    }
    
    if (previousILLSignalHandler) {
        signalRegister(SIGILL, previousILLSignalHandler);
    } else {
        signal(SIGILL, SIG_DFL);
    }
    
    if (previousPIPESignalHandler) {
        signalRegister(SIGPIPE, previousPIPESignalHandler);
    } else {
        signal(SIGPIPE, SIG_DFL);
    }
    
    if (previousSYSSignalHandler) {
        signalRegister(SIGSYS, previousSYSSignalHandler);
    } else {
        signal(SIGSYS, SIG_DFL);
    }
}

static void backupPreviousSignalHandlers(void) {
    struct sigaction old_action_segv;
    sigaction(SIGSEGV, NULL, &old_action_segv);
    if (old_action_segv.sa_sigaction) {
        previousSEGVSignalHandler = old_action_segv.sa_sigaction;
    }
    
    struct sigaction old_action_fpe;
    sigaction(SIGFPE, NULL, &old_action_fpe);
    if (old_action_fpe.sa_sigaction) {
        previousFPESignalHandler = old_action_fpe.sa_sigaction;
    }
    
    struct sigaction old_action_bus;
    sigaction(SIGBUS, NULL, &old_action_bus);
    if (old_action_bus.sa_sigaction) {
        previousBUSSignalHandler = old_action_bus.sa_sigaction;
    }
    
    struct sigaction old_action_trap;
    sigaction(SIGTRAP, NULL, &old_action_trap);
    if (old_action_trap.sa_sigaction) {
        previousTRAPSignalHandler = old_action_trap.sa_sigaction;
    }
    
    struct sigaction old_action_abrt;
    sigaction(SIGABRT, NULL, &old_action_abrt);
    if (old_action_abrt.sa_sigaction) {
        previousABRTSignalHandler = old_action_abrt.sa_sigaction;
    }
    
    struct sigaction old_action_ill;
    sigaction(SIGILL, NULL, &old_action_ill);
    if (old_action_ill.sa_sigaction) {
        previousILLSignalHandler = old_action_ill.sa_sigaction;
    }
    
    struct sigaction old_action_pipe;
    sigaction(SIGPIPE, NULL, &old_action_pipe);
    if (old_action_pipe.sa_sigaction) {
        previousPIPESignalHandler = old_action_pipe.sa_sigaction;
    }
    
    struct sigaction old_action_sys;
    sigaction(SIGSYS, NULL, &old_action_sys);
    if (old_action_sys.sa_sigaction) {
        previousSYSSignalHandler = old_action_sys.sa_sigaction;
    }
}

static void signalRegister(int signal, SignalExceptionHandler signalHandler) {
    struct sigaction action;
    action.sa_sigaction = signalHandler;
    action.sa_flags = SA_NODEFER | SA_SIGINFO;
    sigemptyset(&action.sa_mask);
    sigaction(signal, &action, NULL);
}

static void uncaughtExceptionHandler(NSException *exception) {
    /* 使用PLCrashReporter获取异常信息
     PLCrashReporterConfig *config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeMach // 完整线程上下文
                                                                       symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll]; // Release使用None
     PLCrashReporter *crashReporter = [[PLCrashReporter alloc] initWithConfiguration:config];
    
     NSData *data = [crashReporter generateLiveReportWithException:exception error:nil];
     PLCrashReport *crashReport = [[PLCrashReport alloc] initWithData:data error:nil];
     NSString *exceptionInfo = [PLCrashReportTextFormatter stringValueForCrashReport:crashReport withTextFormat:PLCrashReportTextFormatiOS];
     */
    
    // 获取异常信息
    NSArray *stackSymbols = [exception callStackSymbols];
    NSString *name = [exception name];
    NSString *reason = [exception reason];
    NSString *exceptionInfo = [NSString stringWithFormat:@"Application Specific Information:\n*** Terminating app due to uncaught exception '%@', reason: '%@'\n\nLast Exception Backtrace:\n%@", name, reason, [stackSymbols componentsJoinedByString:@"\n"]];
    
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

static void signalExceptionHandler(int signal, siginfo_t* info, void* context) {
    // 使用PLCrashReporter获取异常信息
    PLCrashReporterConfig *config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeMach // 完整线程上下文
                                                                       symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll]; // Release使用None
    PLCrashReporter *crashReporter = [[PLCrashReporter alloc] initWithConfiguration:config];
    
    NSData *data = [crashReporter generateLiveReport];
    PLCrashReport *crashReport = [[PLCrashReport alloc] initWithData:data error:nil];
    NSString *exceptionInfo = [PLCrashReportTextFormatter stringValueForCrashReport:crashReport withTextFormat:PLCrashReportTextFormatiOS];
    
    // 先保存到本地，等下次启动再上传日志
    NSString *filePath = [NSString stringWithFormat:@"%@/Documents/signal-exception.log", NSHomeDirectory()];
    [exceptionInfo writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // 调用之前崩溃的回调函数
    previousSignalHandler(signal, info, context);
    
    // 杀掉程序，防止同时抛出的SIGABRT被SignalException捕获
    kill(getpid(), SIGKILL);
}

static void previousSignalHandler(int signal, siginfo_t *info, void *context) {
    SignalExceptionHandler previousSignalHandler = NULL;
    switch (signal) {
        case SIGSEGV:
            previousSignalHandler = previousSEGVSignalHandler;
            break;
        case SIGFPE:
            previousSignalHandler = previousFPESignalHandler;
            break;
        case SIGBUS:
            previousSignalHandler = previousBUSSignalHandler;
            break;
        case SIGTRAP:
            previousSignalHandler = previousTRAPSignalHandler;
            break;
        case SIGABRT:
            previousSignalHandler = previousABRTSignalHandler;
            break;
        case SIGILL:
            previousSignalHandler = previousILLSignalHandler;
            break;
        case SIGPIPE:
            previousSignalHandler = previousPIPESignalHandler;
            break;
        case SIGSYS:
            previousSignalHandler = previousSYSSignalHandler;
            break;
        default:
            break;
    }
    
    if (previousSignalHandler) {
        previousSignalHandler(signal, info, context);
    }
}

#pragma mark - PLCrashReporter -
static void initializeCrashReporter(void) {
    if (debuggerShouldExit()) return; // 采集signal异常需要断开调试
    
    PLCrashReporterConfig *config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeMach // 完整线程上下文
                                                                       symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll // Release使用None
                                                      shouldRegisterUncaughtExceptionHandler:YES];
    PLCrashReporter *crashReporter = [[PLCrashReporter alloc] initWithConfiguration:config];
    
    // 是否有待处理的崩溃报告
    if ([crashReporter hasPendingCrashReport]) {
        handlePendingCrashReport(crashReporter);
    }
    
    PLCrashReporterCallbacks callbacks = {
        .version = 0,
        .context = (void *) 0xABABABAB,
        .handleSignal = crashReporterHandler
    };
    [crashReporter setCrashCallbacks:&callbacks];
    
    // 启用崩溃采集
    [crashReporter enableCrashReporter];
}

static void handlePendingCrashReport(PLCrashReporter *crashReporter) {
    NSData *data = [crashReporter loadPendingCrashReportDataAndReturnError:nil];
    PLCrashReport *crashReport = [[PLCrashReport alloc] initWithData:data error:nil];
    NSString *exceptionInfo = [PLCrashReportTextFormatter stringValueForCrashReport:crashReport withTextFormat:PLCrashReportTextFormatiOS];
    
    // 处理崩溃报告（本地储存 | 日志上传）
    NSString *filePath = [NSString stringWithFormat:@"%@/Documents/crashReport-exception.log", NSHomeDirectory()];
    [exceptionInfo writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // 清除已处理的崩溃报告
    [crashReporter purgePendingCrashReport];
}

static void crashReporterHandler (siginfo_t *info, ucontext_t *uap, void *context) {
    NSLog(@"crashReporterHandler: signo-%d, uap-%p, context-%p", info->si_signo, uap, context);
}

static bool debuggerShouldExit(void) {
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
