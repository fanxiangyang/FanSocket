//
//  AppDelegate.m
//  FanCellRobotSocket
//
//  Created by 向阳凡 on 2018/5/9.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import "AppDelegate.h"
#import "FanPushManager.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
//    
    [[FanPushManager defaultManager]registerNotification];//如果只想用传统推送就直接注册一个
    [[FanPushManager defaultManager]registerPKPush];//pushKit框架使用
    
//    [[UIApplication sharedApplication]registerForRemoteNotifications];

    return YES;
}

#pragma mark - iOS8-iOS9的推送相关
//iOS8.0-10.0
-(void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings{
    [[UIApplication sharedApplication]registerForRemoteNotifications];
    NSLog(@"%s",__func__);
}
-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    //获取token，这个token需要上传到服务器
    NSString *token=[NSString stringWithFormat:@"%@",deviceToken];
    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"<>"];
    token = [token stringByTrimmingCharactersInSet:set];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"Push Token:%@",token);
    //MARK: 上传token到服务器
}
//iOS7-iOS9之后，接收远程推送支持的方法，在前台接收，或者后台点击进入，会走此方法
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // Required, iOS 7 Support
    completionHandler(UIBackgroundFetchResultNewData);
    //原生推送(前台后台都进入该方法)
    [UIApplication sharedApplication].applicationIconBadgeNumber=0;
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    //接收了本地通知iOS11不设置userNotificationCenter会走也会执行这个方法
        NSLog(@"888888");
    
}



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
//    BOOL backgroundAccepted = [[UIApplication sharedApplication] setKeepAliveTimeout:600 handler:^{ [self backgroundHandler]; }];
//    if (backgroundAccepted)
//    {
//        NSLog(@"VOIP backgrounding accepted");
//    }
}
-(void)backgroundHandler{
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
