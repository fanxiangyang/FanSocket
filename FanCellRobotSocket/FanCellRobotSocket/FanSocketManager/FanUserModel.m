//
//  FanUserModel.m
//  FanCellRobotSocket
//
//  Created by 向阳凡 on 2018/5/14.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import "FanUserModel.h"

@implementation FanUserModel

+(instancetype)shareManager{
    static FanUserModel *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager=[[FanUserModel alloc]init];
    });
    return manager;
}


-(instancetype)init{
    self=[super init];
    if (self) {
        
    }
    return self;
}
@end
