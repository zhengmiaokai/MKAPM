//
//  CatchFPSView.h
//  Basic
//
//  Created by zhengmiaokai on 2019/6/27.
//  Copyright © 2019 zhengmiaokai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CatchFPSView : UIView

@property (nonatomic, strong) UILabel * contextLab;

- (void)showInView:(UIView *)view;

- (void)closeFPSView;

@end
