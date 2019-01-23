//
//  MDPing.h
//  MDPing
//
//  Created by moonmd.xie on 2018/4/20.
//

#import <Foundation/Foundation.h>

@interface MDPing : NSObject

/** ping多长时间，默认1s */
@property (nonatomic) CGFloat pingTimeLength;

/** ping多少次，默认10 */
@property (nonatomic) NSInteger pingTimes;
/**
 开启对ip点的丢包率和延迟检测
 
 @param hostName 检测点
 @param callBack 回调
 */
- (void)startWithHostName:(NSString *)hostName callBack:(void(^)(int pingValue,float lossRate))callBack;
@end
