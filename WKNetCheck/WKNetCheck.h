//
//  WKNetCheck.h
//  LY_NetCheck
//
//  Created by young on 2019/1/17.
//  Copyright © 2019 youngforwork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKNetCheck : NSObject

+ (NSString *)getCarrierName;

+ (NSString *)getWifiName;
+ (NSString *)getWifiStrength;

+ (NSString *)getIPAddress;
+ (NSString *)getReallyIPAddress;

+ (void)getPing:(void(^)(NSString *info))callBack;
@end

NS_ASSUME_NONNULL_END
