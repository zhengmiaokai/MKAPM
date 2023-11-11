# MKAPM

## 网络监听、卡顿/闪退收集，FPS检测

#### 简单的功能实现，后续迭代完善

```objective-c
/// 网络监听
[MonitorNetwork startMonitoring];
    
/// 卡顿监听
[[CatchANR shareInstance] startMonitoring];
    
/// 闪退监听
[CatchCrash startMonitoring];
    
/// FPS检测
__weak typeof(self) weakSelf = self;
[[CatchFPS shareInstance] setFPSBlock:^(float fps) {
    __strong typeof(weakSelf) strongSelf = self;
    strongSelf.fpsView.contextLab.text = [NSString stringWithFormat:@"%d FPS",(int)roundf(fps)];
}];
    
[[CatchFPS shareInstance] startMonitoring];
```

#### IOS性能优化 - 分析&应用：https://blog.csdn.net/z119901214/article/details/120403321
