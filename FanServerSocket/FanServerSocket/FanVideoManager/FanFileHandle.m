//
//  FanFileHandle.m
//  FanVideoEcode
//
//  Created by 向阳凡 on 2018/5/26.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import "FanFileHandle.h"

@implementation FanFileHandle
#pragma mark - 编码后是否写入本地文件
/**
 初始化需要写入文件的路径

 @param videoFileName 视频文件名（可以包含子路径）  Fan/1.h264
 @param audioFileName 音频文件名（可以包含子路径）  Fan/2.aac
 */
-(void)fan_createFileHandle:(NSString*)videoFileName audioFileName:(NSString *)audioFileName{
    [self fan_createFileHandle:videoFileName audioFileName:audioFileName isAllPath:NO];
}
/**
 初始化需要写入文件的路径
 
 @param videoFileName 视频文件名（可以包含子路径）  Fan/1.h264
 @param audioFileName 音频文件名（可以包含子路径）  Fan/2.aac
 @param isAllPath 是否是全路径文件名（包含路径）
 */
-(void)fan_createFileHandle:(NSString*)videoFileName audioFileName:(NSString *)audioFileName isAllPath:(BOOL)isAllPath{
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if(videoFileName){
        // 视频编码保存的路径
        
        NSString *filePath = isAllPath?videoFileName:[[[self class] fan_cachePath] stringByAppendingPathComponent:videoFileName];
        _videoFilePath=filePath;
        //判断路径存在吗，不存在，创建
        BOOL isDir;
        if (![fileManager fileExistsAtPath:[filePath stringByDeletingLastPathComponent] isDirectory:&isDir])
        {
            [fileManager createDirectoryAtPath:[filePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        }
        //移除旧文件
        if([fileManager fileExistsAtPath:filePath isDirectory:nil]){
            [fileManager removeItemAtPath:filePath error:nil]; // 移除旧文件
        }
        [fileManager createFileAtPath:filePath contents:nil attributes:nil]; // 创建新文件
        _videoFileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];  // 管理写进文件
    }
    if (audioFileName) {
        //音频编码保存的路径
        NSString *audioFile = isAllPath?audioFileName:[[[self class] fan_cachePath] stringByAppendingPathComponent:audioFileName];
        _audioFilePath=audioFile;
        BOOL isDir;
        if (![fileManager fileExistsAtPath:[audioFile stringByDeletingLastPathComponent] isDirectory:&isDir])
        {
            [fileManager createDirectoryAtPath:[audioFile stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        }
        //移除旧文件
        if([fileManager fileExistsAtPath:audioFile isDirectory:nil]){
            [fileManager removeItemAtPath:audioFile error:nil]; // 移除旧文件
        }
        [fileManager createFileAtPath:audioFile contents:nil attributes:nil];
        _audioFileHandle = [NSFileHandle fileHandleForWritingAtPath:audioFile];
    }
}
-(void)fan_stopWriteData{
    if(_videoFileHandle){
        [_videoFileHandle closeFile];
    }
    if (_audioFileHandle) {
        [_audioFileHandle closeFile];
    }
}
-(void)fan_writeVideoData:(NSData *)data{
    if (_videoFileHandle != NULL) {
        [_videoFileHandle writeData:data];
    }
}
-(void)fan_writeAudioData:(NSData *)data{
    if (_audioFileHandle != NULL) {
        [_audioFileHandle writeData:data];
    }
}

-(void)fan_writeVideoData:(NSData *)videoData audioData:(NSData *)audioData{
    if (_videoFileHandle != NULL) {
        [_videoFileHandle writeData:videoData];
    }
    
    if (_audioFileHandle != NULL) {
        [_audioFileHandle writeData:audioData];
    }

}

//记得文件不能和别的正在记录的重名
+(NSFileHandle *)fan_initFileHandleWithFileName:(NSString*)fileName{
    NSFileHandle *fileHandle;
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if(fileName){
        // 视频编码保存的路径
        NSString *filePath = [[[self class] fan_cachePath] stringByAppendingPathComponent:fileName];
        //判断路径存在吗，不存在，创建
        BOOL isDir;
        if (![fileManager fileExistsAtPath:[filePath stringByDeletingLastPathComponent] isDirectory:&isDir])
        {
            [fileManager createDirectoryAtPath:[filePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        }
        //移除旧文件
        if([fileManager fileExistsAtPath:filePath isDirectory:nil]){
            [fileManager removeItemAtPath:filePath error:nil]; // 移除旧文件
        }
        [fileManager createFileAtPath:filePath contents:nil attributes:nil]; // 创建新文件
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];  // 管理写进文件
    }
    return fileHandle;
}
+(NSFileHandle *)fan_initFileHandleWithFileAllName:(NSString*)fileAllName{
    NSFileHandle *fileHandle;
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if(fileAllName){
        // 视频编码保存的路径
        NSString *filePath = fileAllName;
        //判断路径存在吗，不存在，创建
        BOOL isDir;
        if (![fileManager fileExistsAtPath:[filePath stringByDeletingLastPathComponent] isDirectory:&isDir])
        {
            [fileManager createDirectoryAtPath:[filePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        }
        //移除旧文件
        if([fileManager fileExistsAtPath:filePath isDirectory:nil]){
            [fileManager removeItemAtPath:filePath error:nil]; // 移除旧文件
        }
        [fileManager createFileAtPath:filePath contents:nil attributes:nil]; // 创建新文件
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];  // 管理写进文件
    }
    return fileHandle;
}
#pragma mark - 其他工具类

+(NSString *)fan_cachePath{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = ([paths count] > 0) ? [paths objectAtIndex:0] : [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] ;
    return cachePath;
}
@end
