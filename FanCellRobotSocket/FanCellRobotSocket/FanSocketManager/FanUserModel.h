//
//  FanUserModel.h
//  FanCellRobotSocket
//
//  Created by 向阳凡 on 2018/5/14.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FanUserModel : NSObject



@property(nonatomic,copy)NSString *userId;
@property(nonatomic,copy)NSString *userName;

+(instancetype)shareManager;


@end
