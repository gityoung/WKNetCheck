//
//  WKNetCheck.m
//  LY_NetCheck
//
//  Created by young on 2019/1/17.
//  Copyright © 2019 youngforwork. All rights reserved.
//

#import "WKNetCheck.h"
//运营商 wifi
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
//ip
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <net/if.h>
//ping
#import "MDPing.h"
#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IOS_VPN         @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"




@implementation WKNetCheck
+(NSString *)getCarrierName
{
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    
    CTCarrier *carrier = [info subscriberCellularProvider];
    
    //当前手机所属运营商名称
    
    NSString *mobile;
    
    //先判断有没有SIM卡，如果没有则不获取本机运营商
    
    if (!carrier.isoCountryCode) {
        
        NSLog(@"没有SIM卡");
        
        mobile = @"无运营商";
        
    }else{
        
        mobile = [carrier carrierName];
        
    }
    return mobile;
}
+ (NSString *)getWifiName
{
    NSString *wifiName = nil;
    
    CFArrayRef wifiInterfaces = CNCopySupportedInterfaces();
    if (!wifiInterfaces) {
        return nil;
    }
    
    NSArray *interfaces = (__bridge NSArray *)wifiInterfaces;
    
    for (NSString *interfaceName in interfaces) {
        CFDictionaryRef dictRef = CNCopyCurrentNetworkInfo((__bridge CFStringRef)(interfaceName));
        
        if (dictRef) {
            NSDictionary *networkInfo = (__bridge NSDictionary *)dictRef;
            
            wifiName = [networkInfo objectForKey:(__bridge NSString *)kCNNetworkInfoKeySSID];
            
            //            [networkInfo objectForKey:(__bridge NSString *)kCNNetworkInfoKeyBSSID];
            
            CFRelease(dictRef);
        }
    }
    
    CFRelease(wifiInterfaces);
    return wifiName;
}
+ (NSString *)getWifiStrength{
    NSArray *children;
    UIApplication *application = [UIApplication sharedApplication];
    if ([[application valueForKeyPath:@"_statusBar"] isKindOfClass:NSClassFromString(@"UIStatusBar_Modern")]) {
        children = [[[[application valueForKeyPath:@"_statusBar"] valueForKeyPath:@"_statusBar"] valueForKeyPath:@"foregroundView"] subviews];
    } else {
        children = [[[application valueForKeyPath:@"_statusBar"] valueForKeyPath:@"foregroundView"] subviews];
    }
    
    
    
    NSString *dataNetworkItemView = nil;
    NSString *signalStrength = @"";
    
    for (UIView * subview in children) {
        if([subview isKindOfClass:NSClassFromString(@"UIStatusBarDataNetworkItemView")]) {
            dataNetworkItemView = subview;
            
            
            signalStrength = [NSString stringWithFormat:@"%@",[dataNetworkItemView valueForKey:@"_wifiStrengthRaw"]];
            break;
        }
    }
    
    
    double strenth = (signalStrength.doubleValue+90.0)/60.0;
    if (strenth>1) {
        strenth = 1.00;
    }

    return [NSString stringWithFormat:@"%f%%",strenth*100];
}

#pragma mark - 获取设备当前网络IP地址
+ (NSString *)getIPAddress
{
    NSDictionary *addresses = [self getIPAddresses];
    NSString *address;
    NSString *string1 = addresses[@"en2/ipv4"];
    NSString *string2 = addresses[@"en0/ipv4"];
    if (string2) {
        address = string2;
    }
    if (string1) {
        address = string1;
    }
    return address ? address : @"0.0.0.0";
}
+ (NSDictionary *)getIPAddresses
{
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

+(NSString *)getReallyIPAddress
{
    NSError *error;
    NSURL *ipURL = [NSURL URLWithString:@"http://pv.sohu.com/cityjson?ie=utf-8"];
    
    NSMutableString *ip = [NSMutableString stringWithContentsOfURL:ipURL encoding:NSUTF8StringEncoding error:&error];
    //判断返回字符串是否为所需数据
    if ([ip hasPrefix:@"var returnCitySN = "]) {
        //对字符串进行处理，然后进行json解析
        //删除字符串多余字符串
        NSRange range = NSMakeRange(0, 19);
        [ip deleteCharactersInRange:range];
        NSString * nowIp =[ip substringToIndex:ip.length-1];
        //将字符串转换成二进制进行Json解析
        NSData * data = [nowIp dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary * dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        NSLog(@"%@",dict);
        return dict[@"cip"] ? dict[@"cip"] : @"";
    }

    return nil;
  
}

#pragma mark - mark

+ (void)getPing:(void(^)(NSString *info))callBack{
    
    MDPing  *ping = [[MDPing alloc] init];
    ping.pingTimes = 5;
    [ping startWithHostName:@"www.baidu.com"
                   callBack:^(int pingValue, float lossRate) {
                   
                       NSString *msg = [NSString         stringWithFormat:@"Ping为:%d ms\n丢包率为%.1f%%",pingValue,lossRate*100];
                       callBack(msg);
                   }];

}

@end
