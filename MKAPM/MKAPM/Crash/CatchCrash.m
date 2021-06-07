//
//  CatchCrash.m
//  Test
//
//  Created by zhengmiaokai on 15/11/23.
//  Copyright © 2015年 zhengmiaokai. All rights reserved.
//

#import "CatchCrash.h"

static void uncaughtExceptionHandler(NSException *exception) {
    
    NSArray *stackArray = [exception callStackSymbols];
    
    NSString *reason = [exception reason];
    
    NSString *name = [exception name];
    
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception reason：%@\nException name：%@\nException stack：%@",name, reason, stackArray];
    
    NSLog(@"%@", exceptionInfo);
    
    NSMutableArray *tmpArr = [NSMutableArray arrayWithArray:stackArray];
    
    [tmpArr insertObject:reason atIndex:0];
    
    //保存到本地  --  当然你可以在下次启动的时候，上传这个log
    [exceptionInfo writeToFile:[NSString stringWithFormat:@"%@/Documents/error.log",NSHomeDirectory()]  atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@implementation CatchCrash

+ (void)setUncaughtExceptionHandler {
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
}

@end
