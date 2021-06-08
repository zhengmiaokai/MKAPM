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
NSString *const MKURLSessionDataTaskDidFinishCollectingMetrics = @"URLSession:task:didFinishCollectingMetrics:";

@implementation MKURLSessionDelegate

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([NSStringFromSelector(aSelector) isEqualToString:MKURLSessionTaskDidCompleteWithError] ||
        [NSStringFromSelector(aSelector) isEqualToString:MKURLSessionDataTaskDidReceiveData] ||
        [NSStringFromSelector(aSelector) isEqualToString:MKURLSessionDataTaskDidReceiveResponse] ||
        [NSStringFromSelector(aSelector) isEqualToString:MKURLSessionDataTaskDidFinishCollectingMetrics]) {
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
            /// 数据收集
        }
    } else if ([NSStringFromSelector(invocation.selector) isEqualToString:MKURLSessionDataTaskDidReceiveData]) {
        __unsafe_unretained NSURLSessionDataTask *dataTask;
        [invocation getArgument:&dataTask atIndex:3];
        __unsafe_unretained NSData *data;
        [invocation getArgument:&data atIndex:4];
        if(dataTask && data){
            /// 数据收集
        }
    } else if ([NSStringFromSelector(invocation.selector) isEqualToString:MKURLSessionDataTaskDidReceiveResponse]) {
        __unsafe_unretained NSURLSessionDataTask *dataTask;
        [invocation getArgument:&dataTask atIndex:3];
        __unsafe_unretained NSHTTPURLResponse *response;
        [invocation getArgument:&response atIndex:4];
        if(dataTask && response){
            /// 数据收集
        }
    } else if ([NSStringFromSelector(invocation.selector) isEqualToString:MKURLSessionDataTaskDidFinishCollectingMetrics]) {
        __unsafe_unretained NSURLSessionTask *task;
        [invocation getArgument:&task atIndex:3];
        __unsafe_unretained NSURLSessionTaskMetrics *taskMetrics;
        [invocation getArgument:&taskMetrics atIndex:4];
        if(task && taskMetrics){
            /// 数据收集
            NSURLSessionTaskTransactionMetrics* transactionMetrics = taskMetrics.transactionMetrics.firstObject;
            if (transactionMetrics.response) {
                /* fetch -> domainLookup -> request -> response
                 
                 transactionMetrics.request
                 transactionMetrics.response
                 
                 transactionMetrics.fetchStartDate           1623139146.473654
                 transactionMetrics.domainLookupStartDate    1623139146.475172
                 transactionMetrics.domainLookupEndDate      1623139146.476172
                 transactionMetrics.requestStartDate         1623139146.546698
                 transactionMetrics.requestEndDate           1623139146.546901
                 transactionMetrics.responseStartDate        1623139146.557371
                 transactionMetrics.responseEndDate          1623139146.557828
                 
                 transactionMetrics.countOfRequestHeaderBytesSent        请求头大小
                 transactionMetrics.countOfRequestBodyBytesSent          请求体大小
                 transactionMetrics.countOfResponseHeaderBytesReceived   响应头大小
                 transactionMetrics.countOfResponseBodyBytesReceived     响应体大小
                 
                 transactionMetrics.localAddress    本地IP
                 transactionMetrics.localPort       本地端口
                 transactionMetrics.remoteAddress   远程IP
                 transactionMetrics.remotePort      远程端口
                */
            }
        }
    }
}

@end
