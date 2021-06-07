//
//  UIView+NTFrame.m
//  Basic
//
//  Created by zhengmiaokai on 15/3/20.
//
//

#import "UIView+Addition.h"

@implementation UIView (Frame)

//上边坐标
- (CGFloat)top {
    return self.frame.origin.y;
}

- (void)setTop:(CGFloat)aTop {
    CGRect frame = self.frame;
    frame.origin.y = aTop;
    self.frame = frame;
}

//左边坐标
- (CGFloat)left {
    return self.frame.origin.x;
}

- (void)setLeft:(CGFloat)aLeft {
    CGRect frame = self.frame;
    frame.origin.x = aLeft;
    self.frame = frame;
}

//下边坐标
- (CGFloat)bottom {
    return self.frame.origin.y + self.frame.size.height;
}
- (void)setBottom:(CGFloat)aBottom {
    CGRect frame = self.frame;
    frame.origin.y = aBottom - self.frame.size.height;
    self.frame = frame;
}

//右边坐标
- (CGFloat)right {
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setRight:(CGFloat)aRight {
    CGRect frame = self.frame;
    frame.origin.x = aRight - self.frame.size.width;
    self.frame = frame;
}

//中心位置
- (CGFloat)centerX {
    return self.center.x;
}

- (void)setCenterX:(CGFloat)aCenterX {
    CGPoint center = self.center;
    center.x = aCenterX;
    self.center = center;
}

- (CGFloat)centerY {
    return self.center.y;
}

- (void)setCenterY:(CGFloat)aCenterY {
    CGPoint center = self.center;
    center.y = aCenterY;
    self.center = center;
}

//宽度
- (CGFloat)width {
    return self.frame.size.width;
}

- (void)setWidth:(CGFloat)aWidth {
    CGRect frame = self.frame;
    frame.size.width = aWidth;
    self.frame = frame;
}

//高度
- (CGFloat)height {
    return self.frame.size.height;
}

- (void)setHeight:(CGFloat)aHeight {
    CGRect frame = self.frame;
    frame.size.height = aHeight;
    self.frame = frame;
}

@end
