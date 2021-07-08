//
//  MKURLConnectionDataDelegate.m
//  Basic
//
//  Created by mikazheng on 2021/6/1.
//  Copyright © 2021 zhengmiaokai. All rights reserved.
//

#import "MKURLConnectionDelegate.h"

NSString *const MKURLConnectionDidCompleteWithError = @"connection:didFailWithError:";
NSString *const MKURLConnectionkDidReceiveData = @"connection:didReceiveData:";
NSString *const MKURLConnectionkDidReceiveResponse = @"connection:didReceiveResponse:";

@implementation MKURLConnectionDelegate

- (void)forwardInvocation:(NSInvocation *)invocation {
    [super forwardInvocation:invocation];
    
    if ([NSStringFromSelector(invocation.selector) isEqualToString:MKURLConnectionDidCompleteWithError]) {
        __unsafe_unretained NSURLConnection *conection;
        [invocation getArgument:&conection atIndex:2];
        __unsafe_unretained NSError *error;
        [invocation getArgument:&error atIndex:3];
        if(conection && error){
            /// 数据收集
        }
    } else if ([NSStringFromSelector(invocation.selector) isEqualToString:MKURLConnectionkDidReceiveData]) {
        __unsafe_unretained NSURLConnection *conection;
        [invocation getArgument:&conection atIndex:2];
        __unsafe_unretained NSData *data;
        [invocation getArgument:&data atIndex:3];
        if(conection && data){
            /// 数据收集
        }
    } else if ([NSStringFromSelector(invocation.selector) isEqualToString:MKURLConnectionkDidReceiveResponse]) {
        __unsafe_unretained NSURLConnection *conection;
        [invocation getArgument:&conection atIndex:2];
        __unsafe_unretained NSURLResponse *response;
        [invocation getArgument:&response atIndex:3];
        if(conection && response){
            /// 数据收集
        }
    }
}

@end
