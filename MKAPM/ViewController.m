//
//  ViewController.m
//  MKAPM
//
//  Created by zhengmiaokai on 2021/6/7.
//

#import "ViewController.h"
#import "CatchFPS.h"
#import "CatchFPSView.h"
#import "MonitorNetwork.h"
#import "CatchCrash.h"
#import "CatchANR.h"
#import "DataRequester.h"

@interface ViewController ()

@property (nonatomic, strong) CatchFPSView *fpsView;

@property (nonatomic, strong) DataRequester *requester;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 网络监听
    [MonitorNetwork startMonitoring];
    
    // 卡顿监听
    [[CatchANR shareInstance] startMonitoring];
    
    // 闪退监听
    [CatchCrash startMonitoring];
    
    /* 模拟Uncaught异常
     [@[] objectAtIndex:0];
     */
    
    /* 模拟野指针-signal异常（需要断开调试才能进入handler）
     char* string = NULL;
     char a = *(string+0);
     */
    
    /* 模拟卡顿异常
     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
         sleep(3);
     });
     */
    
    // FPS检测
    __weak typeof(self) weakSelf = self;
    [[CatchFPS shareInstance] setFPSBlock:^(float fps) {
        __strong typeof(weakSelf) strongSelf = self;
        strongSelf.fpsView.contextLab.text = [NSString stringWithFormat:@"%d FPS",(int)roundf(fps)];
    }];
    
    [[CatchFPS shareInstance] startMonitoring];
    
    self.requester = [[DataRequester alloc] init];
    [self.requester dataRequest];
}

- (CatchFPSView *)fpsView {
    if (_fpsView == nil) {
        _fpsView = [[CatchFPSView alloc] initWithFrame:self.view.bounds];
        [_fpsView showInView:self.view];
    }
    return _fpsView;
}

@end
