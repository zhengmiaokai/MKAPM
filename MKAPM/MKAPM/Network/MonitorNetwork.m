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
#import "MKURLSessionDelegate.h"
#import "MKURLConnectionDelegate.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface NSURLSession (MonitorNetwork)

+ (NSURLSession *)swizzled_sessionWithConfiguration:(NSURLSessionConfiguration *)configuration delegate:(nullable id <NSURLSessionDelegate>)delegate delegateQueue:(nullable NSOperationQueue *)queue;

@end

@implementation NSURLSession (MonitorNetwork)

+ (NSURLSession *)swizzled_sessionWithConfiguration:(NSURLSessionConfiguration *)configuration delegate:(nullable id <NSURLSessionDelegate>)delegate delegateQueue:(nullable NSOperationQueue *)queue {
    MKURLSessionDelegate* proxy = [[MKURLSessionDelegate alloc] initWithTarget:delegate];
    objc_setAssociatedObject(delegate ,@"MKURLSessionDelegate" ,proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [self swizzled_sessionWithConfiguration:configuration delegate:(id <NSURLSessionDelegate>)proxy delegateQueue:queue];
}

@end

@interface NSURLConnection (MonitorNetwork)

- (nullable instancetype)swizzled_initWithRequest:(NSURLRequest *)request delegate:(nullable id)delegate startImmediately:(BOOL)startImmediately;

@end

@implementation NSURLConnection (MonitorNetwork)

- (nullable instancetype)swizzled_initWithRequest:(NSURLRequest *)request delegate:(nullable id)delegate startImmediately:(BOOL)startImmediately {
    MKURLSessionDelegate* proxy = [[MKURLSessionDelegate alloc] initWithTarget:delegate];
    objc_setAssociatedObject(delegate ,@"MKURLConnectionDelegate" ,proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [self swizzled_initWithRequest:request delegate:(id)proxy startImmediately:startImmediately];
}

@end

@implementation MonitorNetwork

+ (void)startHook {
    [NSURLSession swizzledClassMethodOriginalSelector:@selector(sessionWithConfiguration:delegate:delegateQueue:) swizzledSelector:@selector(swizzled_sessionWithConfiguration:delegate:delegateQueue:)];
    
    [NSURLConnection swizzledInstanceMethodOriginalSelector:@selector(initWithRequest:delegate:startImmediately:) swizzledSelector:@selector(swizzled_initWithRequest:delegate:startImmediately:)];
    
    /* Proxy的方式只实现了Delegate的监听，实例方法的调用需要单独Hook */
    [self swizzledURLSessionAsynchronousTask];
    
    /* Proxy的方式只实现了Delegate的监听，类方法sendAsync与sendSync需要单独Hook（NSURLConnection官方已经弃用） */
    [self swizzledURLConnectionSendAsynchronous];
    [self swizzledURLConnectionSendSynchronous];
    
    /* Proxy的方式也可以通过Hook具体类的URLSessionDelegate方法实现监听（["ClassA", "ClassB"]）
    [self swizzledURLSessionDidReceiveResponseIntoClass:NSClassFromString(@"DownloadTaskQueue")];
    [self swizzledURLSessionDidReceiveDataIntoClass:NSClassFromString(@"DownloadTaskQueue")];
    [self swizzledURLSessionDidCompleteWithErrorIntoClass:NSClassFromString(@"DownloadTaskQueue")];
    
    [self swizzledURLSessionDidReceiveResponseIntoClass:NSClassFromString(@"AFURLSessionManager")];
    [self swizzledURLSessionDidReceiveDataIntoClass:NSClassFromString(@"AFURLSessionManager")];
    [self swizzledURLSessionDidCompleteWithErrorIntoClass:NSClassFromString(@"AFURLSessionManager")];
    */
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
                /// 开始异步请求
                
                MKURLSessionAsyncCompletion completionWrapper = ^(id dataOrFilePath, NSURLResponse *response, NSError *error) {
                    /// 结束异步请求
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

#pragma mark - URLConnection类方法的监听 -
+ (void)swizzledURLConnectionSendAsynchronous {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = objc_getMetaClass(class_getName([NSURLConnection class]));
        SEL selector = @selector(sendAsynchronousRequest:queue:completionHandler:);
        SEL swizzledSelector = [MKHookUtil swizzledSelectorForSelector:selector];
        
        typedef void (^NSURLConnectionAsyncCompletion)(NSURLResponse* response, NSData* data, NSError* connectionError);
        
        void (^asyncSwizzleBlock)(Class, NSURLRequest *, NSOperationQueue *, NSURLConnectionAsyncCompletion) = ^(Class slf, NSURLRequest *request, NSOperationQueue *queue, NSURLConnectionAsyncCompletion completion) {
            /// 开始异步请求
            
            NSURLConnectionAsyncCompletion completionWrapper = ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                /// 结束异步请求
                if (completion) {
                    completion(response, data, connectionError);
                }
            };
            /// 调用原IMP
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
            /// 开始同步请求
            NSData *data = ((id(*)(id, SEL, id, NSURLResponse **, NSError **))objc_msgSend)(slf, swizzledSelector, request, response, error);
            /// 结束同步请求
            return data;
        };
        
        [MKHookUtil replaceImplementationOfKnownSelector:selector swizzledSelector:swizzledSelector cls:class implementationBlock:syncSwizzleBlock];
    });
}

#pragma mark - 具体类的URLSessionDelegate方法监听 -
+ (void)swizzledURLSessionDidReceiveResponseIntoClass:(Class)cls {
    
    if (!cls) {
        return;
    }
    
    SEL selector = @selector(URLSession:dataTask:didReceiveResponse:completionHandler:);
    SEL swizzledSelector = [MKHookUtil swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionDataDelegate);
    if (!protocol) {
        protocol = @protocol(NSURLSessionDelegate);
    }
    
    struct objc_method_description methodDescription =  protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionDidReceiveResponseBlock)(id <NSURLSessionDataDelegate> t_self, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response, void(^completionHandler)(NSURLSessionResponseDisposition));
    
    NSURLSessionDidReceiveResponseBlock undefinedBlock = ^(id <NSURLSessionDataDelegate> t_self, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response, void(^completionHandler)(NSURLSessionResponseDisposition)) {
        /// 回调处理
        
        /// do something
    };
    
    NSURLSessionDidReceiveResponseBlock implementationBlock = ^(id <NSURLSessionDataDelegate> t_self, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response, void(^completionHandler)(NSURLSessionResponseDisposition)) {
        /// 调用原IMP
        ((void(*)(id, SEL, ...))objc_msgSend)(t_self, swizzledSelector, session, dataTask, response, completionHandler);
        
        /// do something
    };
    
    [MKHookUtil replaceImplementationOfSelector:selector swizzledSelector:swizzledSelector cls:cls methodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)swizzledURLSessionDidReceiveDataIntoClass:(Class)cls {
    
    if (!cls) {
        return;
    }
    
    SEL selector = @selector(URLSession:dataTask:didReceiveData:);
    SEL swizzledSelector = [MKHookUtil swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionDataDelegate);
    if (!protocol) {
        protocol = @protocol(NSURLSessionDelegate);
    }
    
    struct objc_method_description methodDescription =  protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionDidReceiveResponseBlock)(id <NSURLSessionDataDelegate> t_self, NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data);
    
    NSURLSessionDidReceiveResponseBlock undefinedBlock = ^(id <NSURLSessionDataDelegate> t_self, NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data) {
        /// 回调处理
        
        /// do something
    };
    
    NSURLSessionDidReceiveResponseBlock implementationBlock = ^(id <NSURLSessionDataDelegate> t_self, NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data) {
        /// 调用原IMP
        ((void(*)(id, SEL, ...))objc_msgSend)(t_self, swizzledSelector, session, dataTask, data);
        
        /// do something
    };
    
    [MKHookUtil replaceImplementationOfSelector:selector swizzledSelector:swizzledSelector cls:cls methodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}


+ (void)swizzledURLSessionDidCompleteWithErrorIntoClass:(Class)cls {
    
    if (!cls) {
        return;
    }
    
    SEL selector = @selector(URLSession:task:didCompleteWithError:);
    SEL swizzledSelector = [MKHookUtil swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionTaskDelegate);
    if (!protocol) {
        protocol = @protocol(NSURLSessionDelegate);
    }
    
    struct objc_method_description methodDescription =  protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionDidReceiveResponseBlock)(id <NSURLSessionDataDelegate> t_self, NSURLSession *session, NSURLSessionTask *task, NSError *error);
    
    NSURLSessionDidReceiveResponseBlock undefinedBlock = ^(id <NSURLSessionDataDelegate> t_self, NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        /// 回调处理
        
        /// do something
    };
    
    NSURLSessionDidReceiveResponseBlock implementationBlock = ^(id <NSURLSessionDataDelegate> t_self, NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        /// 调用原IMP
        ((void(*)(id, SEL, ...))objc_msgSend)(t_self, swizzledSelector, session, task, error);
        
        /// do something
    };
    
    [MKHookUtil replaceImplementationOfSelector:selector swizzledSelector:swizzledSelector cls:cls methodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

@end
