//
//  CatchCrash.m
//  Test
//
//  Created by zhengmiaokai on 15/11/23.
//  Copyright © 2015年 zhengmiaokai. All rights reserved.
//

#import "CatchCrash.h"

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
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception Name: %@\nException Reason: %@\nException StackSymbols: %@", name, reason, stackSymbols];
    
    //保存到本地  --  当然你可以在下次启动的时候，上传这个log
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
    NSMutableString *exceptionInfo = [[NSMutableString alloc] init];
    [exceptionInfo appendString:@"Signal Exception:\n"];
    [exceptionInfo appendString:[NSString stringWithFormat:@"Signal %@ was raised.\n", signalName(signal)]];
    [exceptionInfo appendString:@"Call Stack:\n"];
    
    // 因为注册了信号崩溃回调方法，系统会来调用，将记录在调用堆栈上，因此第一行日志需要过滤掉
    for (NSUInteger index = 1; index < NSThread.callStackSymbols.count; index++) {
        NSString *str = [NSThread.callStackSymbols objectAtIndex:index];
        [exceptionInfo appendString:[str stringByAppendingString:@"\n"]];
    }
    
    [exceptionInfo appendString:@"threadInfo:\n"];
    [exceptionInfo appendString:[[NSThread currentThread] description]];
    
    //保存到本地  --  当然你可以在下次启动的时候，上传这个log
    NSString *filePath = [NSString stringWithFormat:@"%@/Documents/signal-exception.log", NSHomeDirectory()];
    [exceptionInfo writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // 杀掉程序，防止同时抛出的SIGABRT被SignalException捕获
    kill(getpid(), SIGKILL);
}

static NSString *signalName(int signal) {
    NSString *signalName;
    switch (signal) {
        case SIGSEGV:
            signalName = @"SIGSEGV";
            break;
        case SIGFPE:
            signalName = @"SIGFPE";
            break;
        case SIGBUS:
            signalName = @"SIGBUS";
            break;
        case SIGTRAP:
            signalName = @"SIGTRAP";
            break;
        case SIGABRT:
            signalName = @"SIGABRT";
            break;
        case SIGILL:
            signalName = @"SIGILL";
            break;
        case SIGPIPE:
            signalName = @"SIGPIPE";
            break;
        case SIGSYS:
            signalName = @"SIGSYS";
            break;
        default:
            break;
    }
    return signalName;
}

@end
