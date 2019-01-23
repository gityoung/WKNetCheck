//
//  MDPing.m
//  MDPing
//
//  Created by moonmd.xie on 2018/4/20.
//

#import "MDPing.h"
#import "SimplePing.h"

@interface PingValue:NSObject
@property (nonatomic, assign) NSTimeInterval startPingTime;
@property (nonatomic, assign) NSTimeInterval backTime;
@end
@implementation PingValue
@end

@interface MDPing()<SimplePingDelegate>

@property (nonatomic, assign, readwrite) BOOL                   forceIPv4;
@property (nonatomic, assign, readwrite) BOOL                   forceIPv6;
@property (nonatomic, strong, readwrite, nullable) SimplePing * pinger;
@property (nonatomic, strong, readwrite, nullable) NSTimer *    sendTimer;

@property (nonatomic, copy) void(^callBack)(int pingValue,float lossRate);
@property (nonatomic, strong) NSMutableArray <PingValue *> *pingValus;
@end

@implementation MDPing{
    dispatch_queue_t _workQueue;
}
/**
 开启对ip点的丢包率和延迟检测
 
 @param hostName 检测点
 @param callBack 回调
 */
- (void)startWithHostName:(NSString *)hostName callBack:(void(^)(int pingValue,float lossRate))callBack{
    if (!_pingTimeLength) {
        _pingTimeLength = 1.f;
    }
    if (!_pingTimes) {
        _pingTimes = 10;
    }
    if (!_workQueue) {
        _workQueue = dispatch_queue_create("ping.workqueue", DISPATCH_QUEUE_CONCURRENT);
    }
    dispatch_async(_workQueue, ^{
        self.callBack = callBack;
        self.pingValus = @[].mutableCopy;
        
        assert(self.pinger == nil);
        
        self.pinger = [[SimplePing alloc] initWithHostName:hostName];
        assert(self.pinger != nil);
        
        if (self.forceIPv4 && ! self.forceIPv6) {
            self.pinger.addressStyle = SimplePingAddressStyleICMPv4;
        } else if (self.forceIPv6 && ! self.forceIPv4) {
            self.pinger.addressStyle = SimplePingAddressStyleICMPv6;
        }
        
        self.pinger.delegate = self;
        [self.pinger start];
        
        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (self.pinger != nil);
    });
}

- (void)dealloc {
    [self->_pinger stop];
    [self->_sendTimer invalidate];
}


/*! Sends a ping.
 *  \details Called to send a ping, both directly (as soon as the SimplePing object starts up)
 *      and via a timer (to continue sending pings periodically).
 */

- (void)sendPing {
    assert(self.pinger != nil);
    [self.pinger sendPingWithData:nil];
    
    PingValue *value = [PingValue new];
    value.startPingTime = [NSDate date].timeIntervalSince1970;
    [_pingValus addObject:value];
    
    if (_pingValus.count >= _pingTimes) {
        [self.sendTimer invalidate];
        self.sendTimer = nil;
        self.pinger = nil;
    }
}

- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address {
#pragma unused(pinger)
    assert(pinger == self.pinger);
    assert(address != nil);
    
    // Send the first ping straight away.
    
    [self sendPing];
    
    // And start a timer to send the subsequent pings.
    assert(self.sendTimer == nil);
    self.sendTimer = [NSTimer scheduledTimerWithTimeInterval:_pingTimeLength/_pingTimes target:self selector:@selector(sendPing) userInfo:nil repeats:YES];
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((_pingTimeLength+0.1) * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
        
        [self.sendTimer invalidate];
        self.sendTimer = nil;
        self.pinger = nil;
        
        if (self.callBack) {
            double x = 0;
            int backTimes = 0;
            for (PingValue *value  in self.pingValus) {
                
                if (value.backTime != 0) {
                    x += (value.backTime-value.startPingTime);
                    backTimes ++;
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                self.callBack(x*1000/backTimes, 1-(backTimes/(self.pingValus.count *1.f)));
            });
            
        }
    });
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error {
#pragma unused(pinger)
    assert(pinger == self.pinger);
    
    [self.sendTimer invalidate];
    self.sendTimer = nil;
    
    // No need to call -stop.  The pinger will stop itself in this case.
    // We do however want to nil out pinger so that the runloop stops.
    self.pinger = nil;
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
    NSLog(@"#%u sent", (unsigned int) sequenceNumber);
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error {
#pragma unused(pinger)
    assert(pinger == self.pinger);
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
    NSLog(@"#%u received, size=%zu", (unsigned int) sequenceNumber, (size_t) packet.length);
    if (sequenceNumber<_pingValus.count) {
        _pingValus[sequenceNumber].backTime = [NSDate date].timeIntervalSince1970;
    }
    
}

- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet {
 #pragma unused(pinger)
    assert(pinger == self.pinger);
    NSLog(@"unexpected packet, size=%zu", (size_t) packet.length);
}
@end
