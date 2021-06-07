//
//  UIDevice+Addition.h
//  Basic
//
//  Created by zhengmiaokai on 2018/9/13.
//  Copyright © 2018年 zhengmiaokai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (Addition)

/* 电量 */
+ (NSString *)batteryPercent;

/* 设备CPU使用占比 */
+ (NSString *)usedCPUPercent;

/* 可用内存占比 */
+ (NSString *)freeMemoryPercent;

/* 系统版本 */
+ (CGFloat)systemVersion;

/* 手机型号 */
+ (NSString *)machinePhoneName;

/* 设备名 */
+ (NSString *)deviceName;

/* UUID-唯一标识 */
+ (NSString *)UUID;

/* 获取IDFA */
+ (NSString *)IDFA;

/* 获取IDFV-唯一标识 */
+ (NSString *)IDFV;

/* 获取mac地址 */
+ (NSString *)macAddress;

/* 获取wifi-IPV4地址 */
+ (NSString *)wifiIPV4;

/* 获取运营商-IPv4地址 */
+ (NSString *)carrierIPv4;

/* 获取IPv4地址 */
+ (NSString *)IPv4;

/* 获取IPv6地址 */
+ (NSString *)IPv6;

/* 获取SSID */
+ (NSString *)SSID;

@end
