//
//  MKURLSessionDelegate.m
//  Basic
//
//  Created by mikazheng on 2019/11/13.
//  Copyright © 2019 zhengmiaokai. All rights reserved.
//

#import "MKURLSessionDelegate.h"

NSString *const MKURLSessionTaskDidCompleteWithError = @"URLSession:task:didCompleteWithError:";
NSString *const MKURLSessionDataTaskDidReceiveData = @"URLSession:dataTask:didReceiveData:";
NSString *const MKURLSessionDataTaskDidReceiveResponse = @"URLSession:dataTask:didReceiveResponse:completionHandler:";

@implementation MKURLSessionDelegate

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([NSStringFromSelector(aSelector) isEqualToString:MKURLSessionTaskDidCompleteWithError] ||
        [NSStringFromSelector(aSelector) isEqualToString:MKURLSessionDataTaskDidReceiveData] ||
        [NSStringFromSelector(aSelector) isEqualToString:MKURLSessionDataTaskDidReceiveResponse]) {
        return YES;
    }
    return [self.target respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [super forwardInvocation:invocation];
    
    if ([NSStringFromSelector(invocation.selector) isEqualToString:MKURLSessionTaskDidCompleteWithError]) {
        __unsafe_unretained NSURLSessionTask *task;
        [invocation getArgument:&task atIndex:3];
        __unsafe_unretained NSError *error;
        [invocation getArgument:&error atIndex:4];
        if(task && error){
            // 实现hook操作
        }
    } else if ([NSStringFromSelector(invocation.selector) isEqualToString:MKURLSessionDataTaskDidReceiveData]) {
        __unsafe_unretained NSURLSessionDataTask *dataTask;
        [invocation getArgument:&dataTask atIndex:3];
        __unsafe_unretained NSData *data;
        [invocation getArgument:&data atIndex:4];
        if(dataTask && data){
            // 实现hook操作
        }
    } else if ([NSStringFromSelector(invocation.selector) isEqualToString:MKURLSessionDataTaskDidReceiveResponse]) {
        __unsafe_unretained NSURLSessionDataTask *dataTask;
        [invocation getArgument:&dataTask atIndex:3];
        __unsafe_unretained NSHTTPURLResponse *response;
        [invocation getArgument:&response atIndex:4];
        if(dataTask && response){
            // 实现hook操作
        }
    }
}

@end
