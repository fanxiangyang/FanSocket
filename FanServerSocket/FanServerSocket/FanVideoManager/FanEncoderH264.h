//
//  FanEncoderH264.h
//  FanVideoEcode
//
//  Created by 向阳凡 on 2018/5/23.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>


/**
 分辨率类型
 */
typedef NS_ENUM(NSUInteger,EncodeResolutionType) {
    EncodeResolutionType640x480,//每帧4-5KB
    EncodeResolutionType960x540,//每帧6-8KB
    EncodeResolutionType1280x720,//10-55KB，大部分在20左右
    EncodeResolutionType1920x1080//10-60KB,大部分在20左右
};


//回调解析后的数据errorStr!=nil失败
typedef void (^FanEncodeH264DataBlock)(NSData *data,NSString *errorStr);


@interface FanEncoderH264 : NSObject

@property (nonatomic, copy)FanEncodeH264DataBlock encodeH264DataBlock;

/**
 分辨率
 */
@property (nonatomic, assign)EncodeResolutionType resolutionType;


//建议调用次方法 1
-(instancetype)initWithEncodeResolutionType:(EncodeResolutionType)resolutionType;

//编码准备  2
-(void)fan_initVideoToolBox;
/**
 视频编码并回调 3

 @param videoSampleBuffer 图片采集的原数据
 @param encodeBlock 成功或失败的数据回调
 */
-(void)fan_encodeVideo:(CMSampleBufferRef)videoSampleBuffer encodeBlock:(FanEncodeH264DataBlock)encodeBlock;
-(void)fan_encodeVideo:(CMSampleBufferRef)videoSampleBuffer;


/**
 结束编码 4
 */
- (void)fan_endEncodeVideo;



@end
