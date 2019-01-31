//
//  FanFileHandle.h
//  FanVideoEcode
//
//  Created by 向阳凡 on 2018/5/26.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import <Foundation/Foundation.h>

///主要保存录制的音频和视频文件
@interface FanFileHandle : NSObject
#pragma mark -  视频音频录制，文件保存本地

@property (nonatomic, strong)NSFileHandle * videoFileHandle;//视频文件，用来录制到本地句柄操作
@property (nonatomic, strong)NSFileHandle * audioFileHandle;//语言文件，用来录制到本地语言句柄操作
@property (nonatomic, strong)NSString * videoFilePath;//录制视频的路径
@property (nonatomic, strong)NSString * audioFilePath;//录制音频的路径
/**
 初始化需要写入文件的路径
 
 @param videoFileName 视频文件名（可以包含子路径）  Fan/1.h264
 @param audioFileName 音频文件名（可以包含子路径）  Fan/2.aac
 */
-(void)fan_createFileHandle:(NSString*)videoFileName audioFileName:(NSString *)audioFileName;
/**
 初始化需要写入文件的路径
 
 @param videoFileName 视频文件名（可以包含子路径）  Fan/1.h264
 @param audioFileName 音频文件名（可以包含子路径）  Fan/2.aac
 @param isAllPath 是否是全路径文件名（包含路径）
 */
-(void)fan_createFileHandle:(NSString*)videoFileName audioFileName:(NSString *)audioFileName isAllPath:(BOOL)isAllPath;


//写入数据
-(void)fan_writeVideoData:(NSData *)data;
-(void)fan_writeAudioData:(NSData *)data;
-(void)fan_writeVideoData:(NSData *)videoData audioData:(NSData *)audioData;
//停止写入
-(void)fan_stopWriteData;

//初始化一个handle，用文件名，我们给的默认缓存路径  Library/Caches
+(NSFileHandle *)fan_initFileHandleWithFileName:(NSString*)fileName;
//初始化一个全路径的Handle，用户自己控制文件路径
+(NSFileHandle *)fan_initFileHandleWithFileAllName:(NSString*)fileAllName;
@end
