//
//  FanPushManager.m
//  FanCellRobotSocket
//
//  Created by 向阳凡 on 2018/5/19.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import "FanPushManager.h"



@implementation FanPushManager

+(instancetype)defaultManager{
    static FanPushManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager=[[FanPushManager alloc]init];
    });
    return manager;
}

-(void)registerNotification{
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        //必须写代理，不然无法监听通知的接收与点击事件
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (!error && granted) {
                //用户点击允许
                NSLog(@"iOS10注册通知成功");
                // 可以通过 getNotificationSettingsWithCompletionHandler 获取权限设置
                //之前注册推送服务，用户点击了同意还是不同意，以及用户之后又做了怎样的更改我们都无从得知，现在 apple 开放了这个 API，我们可以直接获取到用户的设定信息了。注意UNNotificationSettings是只读对象哦，不能直接修改！
                [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
                    //                NSLog(@"========%@",settings);
                    if(settings.authorizationStatus!=UNAuthorizationStatusAuthorized){
                        //用户没有授权或拒绝权限
                    }
                }];
            }else{
                //用户点击不允许
                NSLog(@"iOS10注册通知失败");
                //提示用户是否打开或设备支持授权
            }
        }];
        
        
    } else {
        // Fallback on earlier versions
        if (@available(iOS 8.0, *)) {
            //iOS8+
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert) categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
            
        }
    }
    //iOS8+,包括iOS10+都是需要这个方法，才能获取
    [[UIApplication sharedApplication]registerForRemoteNotifications];
}
#pragma mark - PushKit  和 PKPushRegistryDelegate
-(void)registerPKPush{
    PKPushRegistry *pushRegistry=[[PKPushRegistry alloc]initWithQueue:dispatch_get_main_queue()];
    pushRegistry.delegate=self;
    pushRegistry.desiredPushTypes=[NSSet setWithObject:PKPushTypeVoIP];
}
-(void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)pushCredentials forType:(PKPushType)type{
    //获取token，这个token需要上传到服务器
    NSData *data=pushCredentials.token;
    NSString *token=[NSString stringWithFormat:@"%@",data];
    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"<>"];
    token = [token stringByTrimmingCharactersInSet:set];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"PushKit Token:%@",token);
    
    //MARK: 在这里补充自己的pushkit token上传到服务器的逻辑
}
//收到pushkit的通知时会调用这个方法，但是不会有UI上的显示
-(void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type{
    //iOS8.0-11.0
    [FanPushManager fan_sendLocalNotificationBody:@"iOS8 PushKit发送的推送！"];
    NSDictionary *dic=payload.dictionaryPayload[@"aps"];
    
    //MARK: 解析远程推送的消息，并做处理和跳转

}
//收到pushkit的通知时会调用这个方法，但是不会有UI上的显示
-(void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type withCompletionHandler:(void (^)(void))completion{
    //iOS11.0+
    [FanPushManager fan_sendLocalNotificationBody:@"iOS11 PushKit发送的推送！"];
    
}


#pragma mark -  正常的推送代理，iOS 10++, iOS8的代理直接在APPdelegate里面
//iOS10+在前台模式下接受消息,正常推送
-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler API_AVAILABLE(ios(10.0)){
    UNNotificationContent * content = notification.request.content;//通知消息体内容  title subtitle  body
    if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]
        ]) {
        //远程通知
        
    }else{
        //本地通知
        
    }
    //MARK:解析推送的消息，并做处理和跳转

    
    
    completionHandler(UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound|UNNotificationPresentationOptionAlert);
    //这里是有点问题 的，如果用户关闭通知，但是角标不会消失，
    [UIApplication sharedApplication].applicationIconBadgeNumber=0;
//    if([UIApplication sharedApplication].applicationIconBadgeNumber>0){
//        [UIApplication sharedApplication].applicationIconBadgeNumber--;
//    }
    
}
//iOS10+在后台模式下打开消息（3DTouch不会触发次方法）
-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(10.0)){
    UNNotificationContent * content = response.notification.request.content;//通知消息体内容  title subtitle  body
    if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        //打开远程通知
    }else{
        //打开本地通知
        
    }
    
    //MARK: 解析推送的消息，并做处理和跳转

    completionHandler(); // 系统要求执 这个 法
    [UIApplication sharedApplication].applicationIconBadgeNumber=0;
//    if([UIApplication sharedApplication].applicationIconBadgeNumber>0){
//        [UIApplication sharedApplication].applicationIconBadgeNumber--;
//    }

}

#pragma mark - 关闭通知
-(void)cancelAllPush{
    [UIApplication sharedApplication].applicationIconBadgeNumber=0;
    if (@available(iOS 10.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];
    }else{
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
    }
}

/**

#pragma mark - iOS8-iOS9的推送相关
//iOS8.0-10.0
-(void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings{
    //    [[UIApplication sharedApplication]registerForRemoteNotifications];
    NSLog(@"%s",__func__);
}
-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    //获取token，这个token需要上传到服务器
    NSString *token=[NSString stringWithFormat:@"%@",deviceToken];
    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"<>"];
    token = [token stringByTrimmingCharactersInSet:set];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"PushiOS10以下 Token:%@",token);
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
*/
#pragma mark - 发送本地通知
+(void)fan_sendLocalNotificationBody:(NSString *)body{
    [FanPushManager fan_sendLocalNotificationTitle:nil subtitle:nil body:body intervalTime:0.0f];
}
//几秒后发生本地通知
+(void)fan_sendLocalNotificationBody:(NSString *)body intervalTime:(NSTimeInterval)intervalTime{
    [FanPushManager fan_sendLocalNotificationTitle:nil subtitle:nil body:body intervalTime:intervalTime];
}
+(void)fan_sendLocalNotificationTitle:(NSString *)title body:(NSString *)body{
    [FanPushManager fan_sendLocalNotificationTitle:title subtitle:nil body:body intervalTime:0.0f];
}
+(void)fan_sendLocalNotificationTitle:(NSString *)title subtitle:(NSString *)subtitle body:(NSString *)body{
    [FanPushManager fan_sendLocalNotificationTitle:title subtitle:subtitle body:body intervalTime:0.0f];
}
+(void)fan_sendLocalNotificationTitle:(NSString *)title subtitle:(NSString *)subtitle body:(NSString *)body intervalTime:(NSTimeInterval)intervalTime{
    if (@available(iOS 10.0, *)) {
        // 设置触发条件 UNNotificationTrigger
        UNTimeIntervalNotificationTrigger *timeTrigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:(intervalTime?intervalTime:0.1) repeats:NO];
        
        // 创建通知内容 UNMutableNotificationContent, 注意不是 UNNotificationContent ,此对象为不可变对象。
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title =title;
        content.subtitle = subtitle;
        content.body = body;
        NSInteger badge=[UIApplication sharedApplication].applicationIconBadgeNumber;
        content.badge = @(badge+1);
        content.sound = [UNNotificationSound defaultSound];
//        content.userInfo = @{@"key1":@"value1",@"key2":@"value2"};//方便撤销时使用
        
        // 创建通知标示,是不是通知的标签啊
        NSString *requestIdentifier = @"Dely.X.time";
        
        // 创建通知请求 UNNotificationRequest 将触发条件和通知内容添加到请求中
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:requestIdentifier content:content trigger:timeTrigger];
        
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        // 将通知请求 add 到 UNUserNotificationCenter
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (!error) {
                NSLog(@"推送已添加成功 %@", requestIdentifier);
                //你自己的需求例如下面：
            }
        }];
        
    }else{
        NSDate *date = [NSDate dateWithTimeIntervalSinceNow:intervalTime];
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        //设置推送时间
        notification.fireDate = date;
        //设置时区
        notification.timeZone = [NSTimeZone localTimeZone];
        //设置重复间隔
        //        notification.repeatInterval = NSWeekCalendarUnit;
        //推送声音
        notification.soundName = UILocalNotificationDefaultSoundName;
        //    notification.soundName = @"Default";
        //内容
        notification.alertBody = body;
        notification.alertTitle=title;
        //显示在icon上的红色圈中的数子
        NSInteger badge=[UIApplication sharedApplication].applicationIconBadgeNumber;
        notification.applicationIconBadgeNumber = badge+1;
        //设置userinfo 方便在之后需要撤销的时候使用
//        NSDictionary *infoDic = [NSDictionary dictionaryWithObject:@"name" forKey:@"key"];
//        notification.userInfo = infoDic;
        
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        //    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    
}
@end
