//
//  FanUserModel.h
//  FanServerSocket
//
//  Created by 向阳凡 on 2018/5/14.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@interface FanUserModel : NSObject

@property(nonatomic,strong)GCDAsyncSocket *userSocket;

@property(nonatomic,copy)NSString *userId;
@property(nonatomic,copy)NSString *userName;
@property(nonatomic,copy)NSString *userHost;
@property(nonatomic,assign)NSInteger userPort;


-(instancetype)initWithSocket:(GCDAsyncSocket *)socket;
-(void)configWithSocket:(GCDAsyncSocket *)socket;

@end
