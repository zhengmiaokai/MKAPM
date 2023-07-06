//
//  CatchCrash.m
//  Test
//
//  Created by zhengmiaokai on 15/11/23.
//  Copyright © 2015年 zhengmiaokai. All rights reserved.
//

#import "CatchCrash.h"

static void uncaughtExceptionHandler(NSException *exception) {
    NSArray *stackSymbols = [exception callStackSymbols];
    NSString *name = [exception name];
    NSString *reason = [exception reason];
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception Name: %@\nException Reason: %@\nException StackSymbols: %@", name, reason, stackSymbols];
    
    //保存到本地  --  当然你可以在下次启动的时候，上传这个log
    [exceptionInfo writeToFile:[NSString stringWithFormat:@"%@/Documents/error.log", NSHomeDirectory()] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@implementation CatchCrash

+ (void)setUncaughtExceptionHandler {
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
}

@end
