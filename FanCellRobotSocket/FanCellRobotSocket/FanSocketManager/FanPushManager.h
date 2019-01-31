//
//  FanPushManager.h
//  FanCellRobotSocket
//
//  Created by 向阳凡 on 2018/5/19.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif

#import <PushKit/PushKit.h>


@interface FanPushManager : NSObject<PKPushRegistryDelegate,UNUserNotificationCenterDelegate>


+(instancetype)defaultManager;
-(void)registerNotification;//push传统推送
-(void)registerPKPush;//pushKit  VoIP
///关闭通知栏和Icon角标
-(void)cancelAllPush;


#pragma mark - 发送本地通知
+(void)fan_sendLocalNotificationBody:(NSString *)body;
//几秒后发生本地通知
+(void)fan_sendLocalNotificationBody:(NSString *)body intervalTime:(NSTimeInterval)intervalTime;
+(void)fan_sendLocalNotificationTitle:(NSString *)title body:(NSString *)body;
+(void)fan_sendLocalNotificationTitle:(NSString *)title subtitle:(NSString *)subtitle body:(NSString *)body;
+(void)fan_sendLocalNotificationTitle:(NSString *)title subtitle:(NSString *)subtitle body:(NSString *)body intervalTime:(NSTimeInterval)intervalTime;

@end
