//
//  CatchFPSView.m
//  Basic
//
//  Created by zhengmika on 2019/6/27.
//  Copyright © 2019 zhengmiaokai. All rights reserved.
//

#import "CatchFPSView.h"
#import "UIColor+Addition.h"
#import "UIView+Addition.h"

#define kStatusBarHeight [UIApplication sharedApplication].statusBarFrame.size.height
#define kScreenWidth  [UIScreen mainScreen].bounds.size.width
#define kScreenHeight  [UIScreen mainScreen].bounds.size.height

@implementation CatchFPSView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *contextLab = [[UILabel alloc] initWithFrame:CGRectMake((self.width - 80)/2, kStatusBarHeight, 80, 36)];
        contextLab.textAlignment = NSTextAlignmentCenter;
        contextLab.layer.cornerRadius = 6;
        contextLab.layer.masksToBounds = YES;
        contextLab.textColor = [UIColor whiteColor];
        contextLab.backgroundColor = [UIColor colorWithHexString:@"#50c2d0"];
        contextLab.font = [UIFont systemFontOfSize:20];
        contextLab.alpha = 0.7;
        [self addSubview:contextLab];
        self.contextLab = contextLab;
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        _contextLab.userInteractionEnabled = YES;
        [_contextLab addGestureRecognizer:pan];
    }
    return self;
}

- (void)showInView:(UIView *)view {
    [view addSubview:self];
}

- (void)closeFPSView {
    [self removeFromSuperview];
}

- (void)handleGesture:(UIPanGestureRecognizer *)panGesture {
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan:
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint  translation = [panGesture translationInView:_contextLab];
            
            _contextLab.center = CGPointMake(_contextLab.center.x + translation.x,
                                           _contextLab.center.y + translation.y);
            [panGesture setTranslation:CGPointZero inView:_contextLab];
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            CGFloat top = _contextLab.top;
            CGFloat left = _contextLab.left;
            if (top < 0) top = 0;
            if (top > (kScreenHeight - _contextLab.height)) top = (kScreenHeight - _contextLab.height);
            if (left < 0) left = 0;
            if (left > (kScreenWidth - _contextLab.width)) left = (kScreenWidth - _contextLab.width);
            
            [UIView animateWithDuration:0.25 animations:^{
                self->_contextLab.top = top;
                self->_contextLab.left = left;
            }];
        }
            break;
        default:
            break;
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *result = [super hitTest:point withEvent:event];
    if (result == self) {
        return nil;
    }
    return result;
}

@end
