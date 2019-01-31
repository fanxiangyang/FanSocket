//
//  FanUserModel.m
//  FanServerSocket
//
//  Created by 向阳凡 on 2018/5/14.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import "FanUserModel.h"

@implementation FanUserModel



-(instancetype)initWithSocket:(GCDAsyncSocket *)socket{
    self=[super init];
    if (self) {
        _userSocket=socket;
        _userHost=socket.connectedHost;
        _userPort=socket.connectedPort;
    }
    return self;
}
-(void)configWithSocket:(GCDAsyncSocket *)socket{
    _userSocket=socket;
    _userHost=socket.connectedHost;
    _userPort=socket.connectedPort;
}




@end
