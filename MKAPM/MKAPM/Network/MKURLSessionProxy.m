//
//  MKURLSessionProxy.m
//  Basic
//
//  Created by mikazheng on 2019/11/13.
//  Copyright © 2019 zhengmiaokai. All rights reserved.
//

#import "MKURLSessionProxy.h"

NSString *const MKURLSessionDataTaskDidReceiveResponse = @"URLSession:dataTask:didReceiveResponse:completionHandler:";
NSString *const MKURLSessionDataTaskDidReceiveData = @"URLSession:dataTask:didReceiveData:";
NSString *const MKURLSessionTaskDidCompleteWithError = @"URLSession:task:didCompleteWithError:";
NSString *const MKURLSessionDataTaskDidFinishCollectingMetrics = @"URLSession:task:didFinishCollectingMetrics:";
NSString *const MKURLSessionDataTaskWillPerformHTTPRedirection = @"URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:";

@implementation MKURLSessionProxy

- (void)forwardInvocation:(NSInvocation *)invocation {
    [super forwardInvocation:invocation];
    
    if ([NSStringFromSelector(invocation.selector) isEqualToString:MKURLSessionTaskDidCompleteWithError]) {
        __unsafe_unretained NSURLSessionTask *task;
        [invocation getArgument:&task atIndex:3];
        __unsafe_unretained NSError *error;
        [invocation getArgument:&error atIndex:4];
        if(task){
            // 数据收集
            NSLog(@"MKURLSessionTaskDidCompleteWithError: %@", task.currentRequest.URL);
        }
    } else if ([NSStringFromSelector(invocation.selector) isEqualToString:MKURLSessionDataTaskDidReceiveData]) {
        __unsafe_unretained NSURLSessionDataTask *dataTask;
        [invocation getArgument:&dataTask atIndex:3];
        __unsafe_unretained NSData *data;
        [invocation getArgument:&data atIndex:4];
        if(dataTask && data){
            // 数据收集
            NSLog(@"MKURLSessionDataTaskDidReceiveData: %@", dataTask.currentRequest.URL);
        }
    } else if ([NSStringFromSelector(invocation.selector) isEqualToString:MKURLSessionDataTaskDidReceiveResponse]) {
        __unsafe_unretained NSURLSessionDataTask *dataTask;
        [invocation getArgument:&dataTask atIndex:3];
        __unsafe_unretained NSHTTPURLResponse *response;
        [invocation getArgument:&response atIndex:4];
    
        if(dataTask && response){
            // 数据收集
            NSLog(@"MKURLSessionDataTaskDidReceiveResponse: %@", dataTask.currentRequest.URL);
        }
    } else if ([NSStringFromSelector(invocation.selector) isEqualToString:MKURLSessionDataTaskDidFinishCollectingMetrics]) {
        __unsafe_unretained NSURLSessionTask *task;
        [invocation getArgument:&task atIndex:3];
        __unsafe_unretained NSURLSessionTaskMetrics *taskMetrics;
        [invocation getArgument:&taskMetrics atIndex:4];
        if(task && taskMetrics){
            // 数据收集
            NSLog(@"MKURLSessionDataTaskDidFinishCollectingMetrics: %@", task.currentRequest.URL);
            
            for (int i = 0; i < taskMetrics.transactionMetrics.count; ++i) {
                NSURLSessionTaskTransactionMetrics *metrics = taskMetrics.transactionMetrics[i];
                
                if (metrics.resourceFetchType == NSURLSessionTaskMetricsResourceFetchTypeLocalCache) continue;
                
                NSDate* startDate = metrics.fetchStartDate;
                long dnsTime = [metrics.domainLookupEndDate timeIntervalSinceDate:metrics.domainLookupStartDate] * 1000;
                long ipConnectTime = [metrics.connectEndDate timeIntervalSinceDate:metrics.connectStartDate] * 1000;
                long sslTime = [metrics.secureConnectionEndDate timeIntervalSinceDate:metrics.secureConnectionStartDate] * 1000;
                long totalTime = [metrics.responseEndDate timeIntervalSinceDate:metrics.fetchStartDate] * 1000;
                long firstPackageTime = [metrics.responseStartDate timeIntervalSinceDate:metrics.requestStartDate] * 1000;
                long wholePackageTime = [metrics.responseEndDate timeIntervalSinceDate:metrics.requestStartDate] * 1000;

                NSLog(@"开始时间：%@，总耗时：%ldms，首包耗时：%ldms，完整包耗时：%ldms，DNS解析耗时：%ldms，IP直连耗时：%ldms，SSL连接耗时：%ldms\n", startDate, totalTime, firstPackageTime, wholePackageTime, dnsTime, ipConnectTime, sslTime);

                /* 流程：fetch -> domainLookup（DNS解析） -> connect（IP直连） -> secureConnection（SSL连接） -> request -> response

                 metrics.countOfRequestHeaderBytesSent        请求头大小
                 metrics.countOfRequestBodyBytesSent          请求体大小
                 metrics.countOfResponseHeaderBytesReceived   响应头大小
                 metrics.countOfResponseBodyBytesReceived     响应体大小

                 metrics.localAddress    本地IP
                 metrics.localPort       本地端口
                 metrics.remoteAddress   远程IP
                 metrics.remotePort      远程端口
                */
            }
        }
    } else if ([NSStringFromSelector(invocation.selector) isEqualToString:MKURLSessionDataTaskWillPerformHTTPRedirection]) {
        __unsafe_unretained NSURLSessionDataTask *dataTask;
        [invocation getArgument:&dataTask atIndex:3];
        __unsafe_unretained NSHTTPURLResponse *response;
        [invocation getArgument:&response atIndex:4];
        
        if(dataTask && response){
            // 数据收集
            NSLog(@"MKURLSessionDataTaskWillPerformHTTPRedirection: %@", dataTask.currentRequest.URL);
        }
    }
}

@end
