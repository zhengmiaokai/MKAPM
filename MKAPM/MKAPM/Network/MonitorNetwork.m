//
//  MonitorNetwork.m
//  Basic
//
//  Created by mikazheng on 2021/6/1.
//  Copyright © 2021 zhengmiaokai. All rights reserved.
//

#import "MonitorNetwork.h"
#import "MKHookUtil.h"
#import "NSObject+Additions.h"
#import "MKURLSessionProxy.h"
#import "MKURLConnectionProxy.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface NSURLSession (MonitorNetwork)

+ (NSURLSession *)swizzled_sessionWithConfiguration:(NSURLSessionConfiguration *)configuration delegate:(nullable id <NSURLSessionDelegate>)delegate delegateQueue:(nullable NSOperationQueue *)queue;

@end

@implementation NSURLSession (MonitorNetwork)

+ (NSURLSession *)swizzled_sessionWithConfiguration:(NSURLSessionConfiguration *)configuration delegate:(nullable id <NSURLSessionDelegate>)delegate delegateQueue:(nullable NSOperationQueue *)queue {
    if (delegate) {
        MKURLSessionProxy* proxy = [[MKURLSessionProxy alloc] initWithTarget:delegate];
        objc_setAssociatedObject(delegate ,@"MKURLSessionProxy" ,proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return [self swizzled_sessionWithConfiguration:configuration delegate:(id <NSURLSessionDelegate>)proxy delegateQueue:queue];
    } else {
        return [self swizzled_sessionWithConfiguration:configuration delegate:nil delegateQueue:queue];
    }
}

@end

@interface NSURLConnection (MonitorNetwork)

- (nullable instancetype)swizzled_initWithRequest:(NSURLRequest *)request delegate:(nullable id)delegate startImmediately:(BOOL)startImmediately;

@end

@implementation NSURLConnection (MonitorNetwork)

- (nullable instancetype)swizzled_initWithRequest:(NSURLRequest *)request delegate:(nullable id)delegate startImmediately:(BOOL)startImmediately {
    if (delegate) {
        MKURLSessionProxy* proxy = [[MKURLSessionProxy alloc] initWithTarget:delegate];
        objc_setAssociatedObject(delegate ,@"MKURLSessionProxy" ,proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return [self swizzled_initWithRequest:request delegate:(id)proxy startImmediately:startImmediately];
    } else {
        return [self swizzled_initWithRequest:request delegate:nil startImmediately:startImmediately];
    }
}

@end

@implementation MonitorNetwork

+ (void)startMonitoring {
    /* 使用Proxy实现NSURLSessionDelegate方法切面
     [NSURLSession swizzledClassMethodOriginalSelector:@selector(sessionWithConfiguration:delegate:delegateQueue:) swizzledSelector:@selector(swizzled_sessionWithConfiguration:delegate:delegateQueue:)];
     [NSURLConnection swizzledInstanceMethodOriginalSelector:@selector(initWithRequest:delegate:startImmediately:) swizzledSelector:@selector(swizzled_initWithRequest:delegate:startImmediately:)];
     */
    
    /* Hook具体类的NSURLSessionDelegate方法 */
    [self swizzledURLSessionIntoClass:NSClassFromString(@"DataRequester")];
    [self swizzledURLSessionIntoClass:NSClassFromString(@"AFURLSessionManager")];
     
    
    /* Hook NSURLSession的实例方法 */
    [self swizzledURLSessionAsynchronousTask];
    [self swizzledURLSessionTaskResume];
    
    /* Hook NSURLConnection的类方法（NSURLConnection官方已经弃用） */
    [self swizzledURLConnectionSendAsynchronous];
    [self swizzledURLConnectionSendSynchronous];
}

#pragma mark - URLSession实例方法的监听 -
+ (void)swizzledURLSessionAsynchronousTask {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [NSURLSession class];
        
        const SEL selectors[] = {
            @selector(dataTaskWithURL:completionHandler:),
            @selector(dataTaskWithRequest:completionHandler:),
            @selector(downloadTaskWithURL:completionHandler:),
            @selector(downloadTaskWithRequest:completionHandler:),
            @selector(downloadTaskWithResumeData:completionHandler:)
        };
        
        typedef void (^MKURLSessionAsyncCompletion)(id dataOrFilePath, NSURLResponse *response, NSError *error);
        
        const int totalNum = sizeof(selectors) / sizeof(SEL);
        
        for (int index = 0; index < totalNum; index++) {
            SEL selector = selectors[index];
            SEL swizzledSelector = [MKHookUtil swizzledSelectorForSelector:selector];
            
            NSURLSessionTask *(^asynchronousTaskSwizzleBlock)(Class, id, MKURLSessionAsyncCompletion) = ^NSURLSessionTask *(Class slf, id argument, MKURLSessionAsyncCompletion completion) {
                // recording data start
                
                MKURLSessionAsyncCompletion completionWrapper = ^(id dataOrFilePath, NSURLResponse *response, NSError *error) {
                    // recording data end
                    
                    if (completion) {
                        completion(dataOrFilePath, response, error);
                    }
                };
                
                NSURLSessionTask *task = ((id(*)(id, SEL, id, id))objc_msgSend)(slf, swizzledSelector, argument, completionWrapper);
                return task;
            };
            [MKHookUtil replaceImplementationOfKnownSelector:selector swizzledSelector:swizzledSelector cls:class implementationBlock:asynchronousTaskSwizzleBlock];
        }
    });
}

+ (void)swizzledURLSessionTaskResume {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [NSURLSessionTask class];
        SEL selector = @selector(resume);
        SEL swizzledSelector = [MKHookUtil swizzledSelectorForSelector:selector];
        
        void (^swizzleBlock)(NSURLSessionTask *) = ^(NSURLSessionTask *slf) {
            // recording data
            
            ((void(*)(id, SEL))objc_msgSend)(slf, swizzledSelector);
        };
        
        [MKHookUtil replaceImplementationOfKnownSelector:selector swizzledSelector:swizzledSelector cls:class implementationBlock:swizzleBlock];
    });
}

#pragma mark - URLConnection类方法的监听 -
+ (void)swizzledURLConnectionSendAsynchronous {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = objc_getMetaClass(class_getName([NSURLConnection class]));
        SEL selector = @selector(sendAsynchronousRequest:queue:completionHandler:);
        SEL swizzledSelector = [MKHookUtil swizzledSelectorForSelector:selector];
        
        typedef void (^NSURLConnectionAsyncCompletion)(NSURLResponse* response, NSData* data, NSError* connectionError);
        
        void (^asyncSwizzleBlock)(Class, NSURLRequest *, NSOperationQueue *, NSURLConnectionAsyncCompletion) = ^(Class slf, NSURLRequest *request, NSOperationQueue *queue, NSURLConnectionAsyncCompletion completion) {
            // recording data start
            
            NSURLConnectionAsyncCompletion completionWrapper = ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                // recording data end
                
                if (completion) {
                    completion(response, data, connectionError);
                }
            };
            ((void(*)(id, SEL, id, id, id))objc_msgSend)(slf, swizzledSelector, request, queue, completionWrapper);
        };
        
        [MKHookUtil replaceImplementationOfKnownSelector:selector swizzledSelector:swizzledSelector cls:class implementationBlock:asyncSwizzleBlock];
    });
}

+ (void)swizzledURLConnectionSendSynchronous {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = objc_getMetaClass(class_getName([NSURLConnection class]));
        SEL selector = @selector(sendSynchronousRequest:returningResponse:error:);
        SEL swizzledSelector = [MKHookUtil swizzledSelectorForSelector:selector];
        
        NSData *(^syncSwizzleBlock)(Class, NSURLRequest *, NSURLResponse **, NSError **) = ^NSData *(Class slf, NSURLRequest *request, NSURLResponse **response, NSError **error) {
            // recording data start
            
            NSData *data = ((id(*)(id, SEL, id, NSURLResponse **, NSError **))objc_msgSend)(slf, swizzledSelector, request, response, error);
            // recording data end
            
            return data;
        };
        
        [MKHookUtil replaceImplementationOfKnownSelector:selector swizzledSelector:swizzledSelector cls:class implementationBlock:syncSwizzleBlock];
    });
}

#pragma mark - 具体类的URLSessionDelegate方法监听 -
+ (void)swizzledURLSessionIntoClass:(Class)cls {
    if (cls) {
        [self swizzledURLSessionDidReceiveDataIntoClass:cls];
        [self swizzledURLSessionDidReceiveResponseIntoClass:cls];
        [self swizzledURLSessionDidCompleteWithErrorIntoClass:cls];
        [self swizzledURLSessionWillPerformHTTPRedirectionIntoClass:cls];
        [self swizzledURLSessionDidFinishCollectingMetricsIntoClass:cls];
    }
}

+ (void)swizzledURLSessionDidReceiveResponseIntoClass:(Class)cls {
    SEL selector = @selector(URLSession:dataTask:didReceiveResponse:completionHandler:);
    SEL swizzledSelector = [MKHookUtil swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionDataDelegate);
    if (!protocol) {
        protocol = @protocol(NSURLSessionDelegate);
    }
    
    struct objc_method_description methodDescription =  protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionDidReceiveResponseBlock)(id <NSURLSessionDataDelegate> t_self, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response, void(^completionHandler)(NSURLSessionResponseDisposition));
    
    NSURLSessionDidReceiveResponseBlock undefinedBlock = ^(id <NSURLSessionDataDelegate> t_self, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response, void(^completionHandler)(NSURLSessionResponseDisposition)) {
        // recording data
        
        if (completionHandler) {
            completionHandler(NSURLSessionResponseAllow);
        }
    };
    
    NSURLSessionDidReceiveResponseBlock implementationBlock = ^(id <NSURLSessionDataDelegate> t_self, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response, void(^completionHandler)(NSURLSessionResponseDisposition)) {
        // recording data
        NSLog(@"MKURLSessionDataTaskDidReceiveResponse: %@", dataTask.currentRequest.URL);
        
        ((void(*)(id, SEL, ...))objc_msgSend)(t_self, swizzledSelector, session, dataTask, response, completionHandler);
    };
    
    [MKHookUtil replaceImplementationOfSelector:selector swizzledSelector:swizzledSelector cls:cls methodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)swizzledURLSessionDidReceiveDataIntoClass:(Class)cls {
    SEL selector = @selector(URLSession:dataTask:didReceiveData:);
    SEL swizzledSelector = [MKHookUtil swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionDataDelegate);
    if (!protocol) {
        protocol = @protocol(NSURLSessionDelegate);
    }
    
    struct objc_method_description methodDescription =  protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionDidReceiveDataBlock)(id <NSURLSessionDataDelegate> t_self, NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data);
    
    NSURLSessionDidReceiveDataBlock undefinedBlock = ^(id <NSURLSessionDataDelegate> t_self, NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data) {
        // recording data
    };
    
    NSURLSessionDidReceiveDataBlock implementationBlock = ^(id <NSURLSessionDataDelegate> t_self, NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data) {
        // recording data
        NSLog(@"MKURLSessionDataTaskDidReceiveData: %@", dataTask.currentRequest.URL);
        
        ((void(*)(id, SEL, ...))objc_msgSend)(t_self, swizzledSelector, session, dataTask, data);
    };
    
    [MKHookUtil replaceImplementationOfSelector:selector swizzledSelector:swizzledSelector cls:cls methodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)swizzledURLSessionDidCompleteWithErrorIntoClass:(Class)cls {
    SEL selector = @selector(URLSession:task:didCompleteWithError:);
    SEL swizzledSelector = [MKHookUtil swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionTaskDelegate);
    if (!protocol) {
        protocol = @protocol(NSURLSessionDelegate);
    }
    
    struct objc_method_description methodDescription =  protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionDidCompleteWithErrorBlock)(id <NSURLSessionDataDelegate> t_self, NSURLSession *session, NSURLSessionTask *task, NSError *error);
    
    NSURLSessionDidCompleteWithErrorBlock undefinedBlock = ^(id <NSURLSessionDataDelegate> t_self, NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        // recording data
    };
    
    NSURLSessionDidCompleteWithErrorBlock implementationBlock = ^(id <NSURLSessionDataDelegate> t_self, NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        // recording data
        NSLog(@"MKURLSessionTaskDidCompleteWithError: %@", task.currentRequest.URL);
        
        ((void(*)(id, SEL, ...))objc_msgSend)(t_self, swizzledSelector, session, task, error);
    };
    
    [MKHookUtil replaceImplementationOfSelector:selector swizzledSelector:swizzledSelector cls:cls methodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)swizzledURLSessionWillPerformHTTPRedirectionIntoClass:(Class)cls {
    SEL selector = @selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:);
    SEL swizzledSelector = [MKHookUtil swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionTaskDelegate);
    if (!protocol) {
        protocol = @protocol(NSURLSessionDelegate);
    }
    
    struct objc_method_description methodDescription =  protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionWillPerformHTTPRedirectionBlock)(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSHTTPURLResponse *response, NSURLRequest *newRequest, void(^completionHandler)(NSURLRequest *));
    
    NSURLSessionWillPerformHTTPRedirectionBlock undefinedBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSHTTPURLResponse *response, NSURLRequest *newRequest, void(^completionHandler)(NSURLRequest *)) {
        // recording data
        NSLog(@"MKURLSessionDataTaskWillPerformHTTPRedirection: %@", task.currentRequest.URL);
        
        if (completionHandler) {
            completionHandler(newRequest);
        }
    };
    
    NSURLSessionWillPerformHTTPRedirectionBlock implementationBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSHTTPURLResponse *response, NSURLRequest *newRequest, void(^completionHandler)(NSURLRequest *)) {
        // recording data
        
        ((void(*)(id, SEL, ...))objc_msgSend)(slf, swizzledSelector, session, task, response, newRequest, completionHandler);
    };
    
    [MKHookUtil replaceImplementationOfSelector:selector swizzledSelector:swizzledSelector cls:cls methodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)swizzledURLSessionDidFinishCollectingMetricsIntoClass:(Class)cls {
    SEL selector = @selector(URLSession:task:didFinishCollectingMetrics:);
    SEL swizzledSelector = [MKHookUtil swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionTaskDelegate);
    if (!protocol) {
        protocol = @protocol(NSURLSessionDelegate);
    }
    
    struct objc_method_description methodDescription =  protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionTaskDidFinishCollectingMetricsBlock)(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics);
    
    NSURLSessionTaskDidFinishCollectingMetricsBlock undefinedBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) {
        // recording data
    };
    
    NSURLSessionTaskDidFinishCollectingMetricsBlock implementationBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSURLSessionTaskMetrics *taskMetrics) {
        // recording data
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
        
        ((void(*)(id, SEL, ...))objc_msgSend)(slf, swizzledSelector, session, task, taskMetrics);
    };
    
    [MKHookUtil replaceImplementationOfSelector:selector swizzledSelector:swizzledSelector cls:cls methodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

@end
