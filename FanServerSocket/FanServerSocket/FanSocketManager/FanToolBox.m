//
//  FanToolBox.m
//  Brain
//
//  Created by 向阳凡 on 2018/6/5.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import "FanToolBox.h"
//获取WiFi
#import <SystemConfiguration/CaptiveNetwork.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

@implementation FanToolBox

#pragma mark - 文件操作

+(NSString *)fan_cachePath{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = ([paths count] > 0) ? [paths objectAtIndex:0] : [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] ;
    return cachePath;
}
+(NSString *)fan_documentPath{
    //    return [self fan_cachePath];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *cachePath = ([paths count] > 0) ? [paths objectAtIndex:0] : [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] ;
    return cachePath;
}
+(BOOL)fan_createDirectoryAtPath:(NSString *)filePath{
    NSString *filePathCopy=[filePath copy];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    NSError *error=nil;
    if (![fileManager fileExistsAtPath:filePathCopy isDirectory:&isDir])
    {
        
        if ([filePathCopy pathExtension].length>0) {
            filePathCopy=[filePathCopy stringByDeletingLastPathComponent];
        }
        [fileManager createDirectoryAtPath:filePathCopy withIntermediateDirectories:YES attributes:nil error:&error];
    }
    if (error) {
        return NO;
    }
    return YES;
}
+(BOOL)fan_copyAtFilePath:(NSString *)srcFilePath toFilePath:(NSString *)toFilePath{
    [FanToolBox fan_createDirectoryAtPath:toFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:srcFilePath isDirectory:nil]) {
        BOOL isDir=NO;
        if ([fileManager fileExistsAtPath:toFilePath isDirectory:&isDir]) {
            if (isDir==NO) {
                [fileManager removeItemAtPath:toFilePath error:nil];
                [fileManager copyItemAtPath:srcFilePath toPath:toFilePath error:nil];
            }
        }else{
            [fileManager copyItemAtPath:srcFilePath toPath:toFilePath error:nil];
        }
    }
    if ([fileManager fileExistsAtPath:toFilePath isDirectory:nil]) {
        return YES;
    }else{
        return NO;
    }
}
//文件夹copy
+(void)fan_copyAtDirPath:(NSString *)srcDirPath toDirPath:(NSString *)toDirPath isRemoveOld:(BOOL)isRemoveOld{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //当前srcDirPath目录下全路径（包含文件夹）  ***/**.png
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:srcDirPath];
    for (NSString *fileStr in enumerator) {
        NSString *fileAllPath=[[toDirPath stringByAppendingPathComponent:fileStr] stringByDeletingLastPathComponent];
        BOOL isDir;
        if (![fileManager fileExistsAtPath:fileAllPath isDirectory:&isDir])
        {
            [fileManager createDirectoryAtPath:fileAllPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        if (isRemoveOld) {
            //只移除文件，不移除路径
            if (!isDir) {
                [fileManager removeItemAtPath:[toDirPath stringByAppendingPathComponent:fileStr] error:nil];
            }
        }
        [fileManager copyItemAtPath:[srcDirPath stringByAppendingPathComponent:fileStr] toPath:[toDirPath stringByAppendingPathComponent:fileStr] error:nil];
    }
}
/**删除目录下所有文件*/
+ (BOOL)fan_deleteFilesAtPath:(NSString *)filePath
{
    NSFileManager* manager = [NSFileManager defaultManager];
    
    if (![manager fileExistsAtPath:filePath]){
        return YES;
    }
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:filePath] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil)
    {
        NSString* fileAbsolutePath = [filePath stringByAppendingPathComponent:fileName];
        NSError *error;
        [manager removeItemAtPath:fileAbsolutePath error:&error];
    }
    
    return YES;
}
+ (BOOL)fan_deleteFile:(NSString *)filePath{
    NSFileManager* manager = [NSFileManager defaultManager];
    NSError *error;
    BOOL isDir=NO;
    if ([manager fileExistsAtPath:filePath isDirectory:&isDir]) {
        if (isDir) {
//            NSLog(@"删除路径");
        }else{
            [manager removeItemAtPath:filePath error:&error];
        }
    }
    if (error) {
        return NO;
    }
    return YES;
}
/**
 *  请求文件（夹）路径的所有文件大小
 *
 *  @param path 文件（夹）路径
 *
 *  @return 返回大小，字节
 */
+ (unsigned long long)fan_fileSizeFromPath:(NSString *)path
{
    if (path==nil) {
        //        //如果文件路径不存在，取到应用缓存路径Caches(同级别的有Cookies）
        //        NSString *caches=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)firstObject];
        //        //        path=[caches stringByAppendingPathComponent:@"default"];
        //        path=caches;
        return 0;
    }
    // 文件管理者
    NSFileManager *mgr = [NSFileManager defaultManager];
    // 是否为文件夹
    BOOL isDirectory = NO;
    // 这个路径是否存在
    BOOL exists = [mgr fileExistsAtPath:path isDirectory:&isDirectory];
    // 路径不存在
    if (exists == NO) return 0;
    
    if (isDirectory) { // 文件夹
        // 总大小
        NSInteger size = 0;
        // 获得文件夹中的所有内容
        NSDirectoryEnumerator *enumerator = [mgr enumeratorAtPath:path];
        for (NSString *subpath in enumerator) {
            // 获得全路径
            NSString *fullSubpath = [path stringByAppendingPathComponent:subpath];
            // 获得文件属性
            size += [mgr attributesOfItemAtPath:fullSubpath error:nil].fileSize;
        }
        return size;
    } else { // 文件
        return [mgr attributesOfItemAtPath:path error:nil].fileSize;
    }
}
#pragma mark - 其他

+(NSString *)fan_wifiInfo_ssid{
    NSString *ssid;

    #if TARGET_OS_IOS
        NSArray *ifs=(__bridge_transfer id)CNCopySupportedInterfaces();
        id info = nil;
        for (NSString *ifnam in ifs) {
            info=(__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
            //        NSLog(@"22222:%@=>%@",ifnam,info);
            if(info){
                ssid=info[@"SSID"];
                break;
            }
            if(info&&[info count]){
                break;
            }
        }
    #endif
   
    return ssid;
}
//必须在有网的情况下才能获取手机的IP地址
+ (NSString *)fan_IPAdress {
    NSString *address = @"0.0.0.0";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0) { // 0 表示获取成功
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in  *)temp_addr->ifa_addr)->sin_addr)];
                    
                    //                    //广播地址--10.22.70.255
                    //                    NSLog(@"广播地址--%@",[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_dstaddr)->sin_addr)]);
                    //                    //本机地址--10.22.70.111
                    //                    NSLog(@"本机地址--%@",[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]);
                    //                    //子网掩码地址--255.255.255.0
                    //                    NSLog(@"子网掩码地址--%@",[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)]);
                    //                    //端口地址--en0
                    //                    NSLog(@"端口地址--%@",[NSString stringWithUTF8String:temp_addr->ifa_name]);
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    return address;
}

+ (BOOL)fan_isOpenWiFi{
    NSCountedSet * cset = [NSCountedSet new];
    struct ifaddrs *interfaces;
    if( ! getifaddrs(&interfaces) ) {
        for( struct ifaddrs *interface = interfaces; interface; interface = interface->ifa_next) {
            if ( (interface->ifa_flags & IFF_UP) == IFF_UP ) {
                [cset addObject:[NSString stringWithUTF8String:interface->ifa_name]];
            }
        }
    }
    return [cset countForObject:@"awdl0"] > 1 ? YES : NO;
}
@end
