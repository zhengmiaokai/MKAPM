//
//  UIDevice+Addition.m
//  Basic
//
//  Created by zhengmiaokai on 2018/9/13.
//  Copyright © 2018年 zhengmiaokai. All rights reserved.
//

#import "UIDevice+Addition.h"
#import <sys/utsname.h>
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <AdSupport/AdSupport.h>
#import <mach/mach.h>
#import <assert.h>

/* 获取系统CPU使用率 */
static float getUsedCPUPercent() {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;

    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }

    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;

    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;

    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0;

    basic_info = (task_basic_info_t)tinfo;

    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0) {
        stat_thread += thread_count;
    }

    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;

    for (j = 0; j < thread_count; j++) {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        basic_info_th = (thread_basic_info_t)thinfo;

        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->user_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
    }

    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    return tot_cpu;
}

/* 获取系统已使用内存 */
static vm_size_t getUsedMemory() {
    task_basic_info_data_t info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    
    if (kerr == KERN_SUCCESS) {
        return info.resident_size;
    } else {
        return 0;
    }
}

/* 获取系统可用内存 */
static vm_size_t getFreeMemory() {
    mach_port_t host = mach_host_self();
    mach_msg_type_number_t size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vmstat;
    
    host_page_size(host, &pagesize);
    host_statistics(host, HOST_VM_INFO, (host_info_t) &vmstat, &size);
    
    return vmstat.free_count * pagesize;
}

static NSString * const  IOS_CELLULAR = @"pdp_ip0";
static NSString * const  IOS_WIFI     = @"en0";
static NSString * const  IP_ADDR_IPv4 = @"ipv4";
static NSString * const  IP_ADDR_IPv6 = @"ipv6";

@implementation UIDevice (Addition)

#pragma mark -- 设备可用电量占比
+ (NSString *)batteryPercent {
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    float deviceLevel = [UIDevice currentDevice].batteryLevel;
    NSString *result = [NSString stringWithFormat:@"%.2f",deviceLevel];
    return result;
}

#pragma mark -- 设备CPU使用占比
+ (NSString *)usedCPUPercent {
    float _usedCPUPercent = getUsedCPUPercent();
    NSString *result = [NSString stringWithFormat:@"%.2f",_usedCPUPercent];
    return result;
}

#pragma mark -- 设备可用内存占比
+ (NSString *)freeMemoryPercent {
    float _freeMemory = getFreeMemory();
    float _usedMemory = getUsedMemory();
    NSString *result = [NSString stringWithFormat:@"%.2f",_freeMemory / (_freeMemory + _usedMemory)];
    return result;
}

#pragma mark -- 系统版本
+ (CGFloat)systemVersion {
    CGFloat version = [[[UIDevice currentDevice] systemVersion] floatValue];
    return version;
}

#pragma mark -- 手机型号
+ (NSString *)machinePhoneName {
    static dispatch_once_t one;
    static NSString *phone_name;
    dispatch_once(&one, ^{
        NSString *deviceName = [self deviceName];
        if (!deviceName) return;
        NSDictionary *keyValue = @{@"iPhone7,1" : @"iPhone 6 Plus",
                                   @"iPhone7,2" : @"iPhone 6",
                                   @"iPhone8,1" : @"iPhone 6s",
                                   @"iPhone8,2" : @"iPhone 6s Plus",
                                   @"iPhone8,4" : @"iPhone SE",
                                   @"iPhone9,1" : @"iPhone 7",
                                   @"iPhone9,3" : @"iPhone 7",
                                   @"iPhone9,2" : @"iPhone 7 Plus",
                                   @"iPhone9,4" : @"iPhone 7 Plus",
                                   @"iPhone10,1": @"iPhone 8",
                                   @"iPhone10,4": @"iPhone 8",
                                   @"iPhone10,2": @"iPhone 8 Plus",
                                   @"iPhone10,5": @"iPhone 8 Plus",
                                   @"iPhone10,3": @"iPhone X",
                                   @"iPhone10,6": @"iPhone X",
                                   @"iPhone11,8" : @"iPhone XR",
                                   @"iPhone11,2" : @"iPhone XS",
                                   @"iPhone11,4" : @"iPhone XS Max",
                                   @"iPhone11,6" : @"iPhone XS Max",
                                   @"iPhone12,1" : @"iPhone 11",
                                   @"iPhone12,3" : @"iPhone 11 Pro",
                                   @"iPhone12,5" : @"iPhone 11 Pro Max",
                                   @"iPhone12,8" : @"iPhone SE (2nd generation)",
                                   @"iPhone13,1" : @"iPhone 12 mini",
                                   @"iPhone13,2" : @"iPhone 12",
                                   @"iPhone13,3" : @"iPhone 12 Pro",
                                   @"iPhone13,4" : @"iPhone 12 Pro Max",
                                   @"iPhone14,4" : @"iPhone 13 mini",
                                   @"iPhone14,5" : @"iPhone 13",
                                   @"iPhone14,2" : @"iPhone 13 Pro",
                                   @"iPhone14,3" : @"iPhone 13 Pro Max",
                                   @"iPhone14,6" : @"iPhone SE (3rd generation)",
                                   @"iPhone14,7" : @"iPhone 14",
                                   @"iPhone14,8" : @"iPhone 14 Plus",
                                   @"iPhone15,2" : @"iPhone 14 Pro",
                                   @"iPhone15,3" : @"iPhone 14 Pro Max",
                                   @"iPhone15,4" : @"iPhone 15",
                                   @"iPhone15,5" : @"iPhone 15 Plus",
                                   @"iPhone16,1" : @"iPhone 15 Pro",
                                   @"iPhone16,2" : @"iPhone 15 Pro Max",
                                   @"iPhone17,3" : @"iPhone 16",
                                   @"iPhone17,4" : @"iPhone 16 Plus",
                                   @"iPhone17,1" : @"iPhone 16 Pro",
                                   @"iPhone17,2" : @"iPhone 16 Pro Max",
                                   @"iPhone17,5" : @"iPhone 16e",
                                   
                                   @"i386" : @"Simulator x86",
                                   @"x86_64" : @"Simulator x64",
                                   };
        phone_name = deviceName ? [keyValue objectForKey:deviceName] : @"";  // Apple Models：https://theapplewiki.com/wiki/Models
    });
    return phone_name;
}

#pragma mark -- 设备名
+ (NSString *)deviceName {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* machineName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return machineName;
}

#pragma mark -- UUID-唯一标识
+ (NSString *)UUID {
    /* NSUUID [[NSUUID UUID] UUIDString] */
    
    /* CFUUIDRef */
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    
    NSString *nonce = (__bridge NSString *) string;
    NSString *result = [NSString stringWithFormat:@"%@", nonce];
    CFRelease(string);
    return result;
}

#pragma mark 获取IDFA
+ (NSString *)IDFA {
    NSString *adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    return adId;
}

#pragma mark 获取IDFV-唯一标识
+ (NSString *)IDFV {
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        NSString* UUIDString = [[UIDevice currentDevice].identifierForVendor UUIDString];
        return UUIDString;
    }
    return @"";
}

#pragma mark 获取mac地址
+ (NSString *)macAddress {
    int mib[6]  = {0};
    size_t len  = 0;
    char *buf   = NULL;
    unsigned char *ptr      = NULL;
    struct if_msghdr *ifm   = NULL;
    struct sockaddr_dl *sdl = NULL;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error:if_nametoindex error\n");
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error:sysctl, take 1\n");
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }
#if 0
    if (sysctl(mib, 6, buf, &len, NULL, 0) &len, 0)
#else
        if (sysctl(mib, 6, buf, &len, NULL, 0))
#endif
        {
            printf("Error: sysCtl, take 2");
            NSLog(@"sysctl len = %lu\r\n ",len);
        }
    NSLog(@"sysctl len = %lu\r\n ",len);
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *outString = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x",
                           *ptr, *(ptr + 1), *(ptr + 2), *(ptr + 3), *(ptr + 4), *(ptr +5)];
    free(buf);
    return [outString uppercaseString];
}

#pragma mark 局域网 IP4
+ (NSString *)wifiIPV4 {
    NSString *WiFiKey = [NSString stringWithFormat:@"%@/%@", IOS_WIFI, IP_ADDR_IPv4];
    NSDictionary* IPAdressInfo = [self getIPAddressInfo];
    return IPAdressInfo[WiFiKey]?:@"";
}

#pragma mark 公网 IP4
+ (NSString *)carrierIPv4 {
    NSString *CellKey = [NSString stringWithFormat:@"%@/%@", IOS_CELLULAR, IP_ADDR_IPv4];
    NSDictionary* IPAdressInfo = [self getIPAddressInfo];
    return IPAdressInfo[CellKey]?:@"";
}

#pragma mark  IP4
+ (NSString *)IPv4 {
    return [self wifiIPV4]?:[self carrierIPv4];
}

#pragma mark  IP6
+ (NSString *)IPv6 {
    NSString *key = [NSString stringWithFormat:@"%@/%@", IOS_WIFI, IP_ADDR_IPv6];
    NSDictionary* IPAdressInfo = [self getIPAddressInfo];
    return IPAdressInfo[key] ?: @"";
}

#pragma mark - 获取wifi name -
+ (NSString *)SSID {
    NSString *SSID = @"";
    NSDictionary *wifiInfo = [self wifiInfo];
    if (wifiInfo) {
        SSID = wifiInfo[@"SSID"];
    }
    return SSID;
}

#pragma mark 获取wifi相关信息
+ (NSDictionary *)wifiInfo {
    NSDictionary *wifiInfo;
    CFArrayRef WiFiArray = CNCopySupportedInterfaces();
    if (WiFiArray != nil) {
        CFDictionaryRef wifiInfoRef = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(WiFiArray, 0));
        if (wifiInfoRef != nil) {
            wifiInfo = (NSDictionary*)CFBridgingRelease(wifiInfoRef);
        }
        CFRelease(WiFiArray);
    }
    return wifiInfo;
}

#pragma mark 获取IP地址相关信息
+ (NSDictionary *)getIPAddressInfo {
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

@end
