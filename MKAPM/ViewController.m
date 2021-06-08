//
//  ViewController.m
//  MKAPM
//
//  Created by mikazheng on 2021/6/7.
//

#import "ViewController.h"
#import "CatchFPS.h"
#import "CatchFPSView.h"
#import "MonitorNetwork.h"
#import "CatchCrash.h"
#import "CatchANR.h"

@interface ViewController ()

@property (nonatomic, strong) CatchFPSView* fpsView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    /// 网络监听
    [MonitorNetwork startHook];
    
    /// 卡顿监听
    [[CatchANR shareInstance] startListen];
    
    /// 闪退监听
    [CatchCrash setUncaughtExceptionHandler];
    
    /// FPS检测
    __weak typeof(self) weakSelf = self;
    [[CatchFPS shareInstance] setFPSBlock:^(float fps) {
        __strong typeof(weakSelf) strongSelf = self;
        strongSelf.fpsView.contextLab.text = [NSString stringWithFormat:@"%d FPS",(int)roundf(fps)];
    }];
    
    [[CatchFPS shareInstance] startMonitoring];
    
    [self createRequest];
}

- (void)createRequest {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSURLRequest* connectionReq = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://www.baidu.com"]];
        [NSURLConnection sendAsynchronousRequest:connectionReq queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {

        }];
        
        NSURLRequest* sessionReq = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://www.baidu.com"]];
        NSURLSessionDataTask* dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:sessionReq completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        }];
        [dataTask  resume];
    });
}

- (CatchFPSView *)fpsView {
    if (_fpsView == nil) {
        _fpsView = [[CatchFPSView alloc] initWithFrame:self.view.bounds];
        [_fpsView showInView:self.view];
    }
    return _fpsView;
}


@end
