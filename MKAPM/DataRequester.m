//
//  DataRequester.m
//  MKAPM
//
//  Created by lexin on 2025/4/15.
//

#import "DataRequester.h"

@interface DataRequester () <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession* URLSession;

@end

@implementation DataRequester

- (void)dataRequest {
    NSURLRequest* connectionReq = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://baijiahao.baidu.com/s?id=1829361353399113900&wfr=spider&for=pc"]];
    [NSURLConnection sendAsynchronousRequest:connectionReq queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {

    }];
    
    NSURLRequest* sessionReq = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://baijiahao.baidu.com/s?id=1829361353399113900&wfr=spider&for=pc"]];
    NSURLSessionDataTask* dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:sessionReq completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    
    }];
    [dataTask  resume];
    
    NSURLRequest* reqeust1 = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://baijiahao.baidu.com/s?id=1829344375106908908&wfr=spider&for=pc"]];
    self.URLSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    NSURLSessionDataTask *task1 = [self.URLSession dataTaskWithRequest:reqeust1];
    [task1 resume];
    
    NSURLRequest* reqeust2 = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://baijiahao.baidu.com/s?id=1829434495933803181"]];
    self.URLSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    NSURLSessionDataTask *task2 = [self.URLSession dataTaskWithRequest:reqeust2];
    [task2 resume];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics {
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    completionHandler(request);
}

@end
