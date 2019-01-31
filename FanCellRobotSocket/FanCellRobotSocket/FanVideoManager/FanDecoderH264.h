//
//  FanDecoderH264.h
//  FanVideoEcode
//
//  Created by 向阳凡 on 2018/5/24.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>


typedef void (^FanDecodedVideoDataBlock) (CVPixelBufferRef pixelBuffer);


@interface FanDecoderH264 : NSObject

@property (nonatomic, copy) FanDecodedVideoDataBlock decodedVideoDataBlock;

- (void)fan_initVideoToolBox;//解码准备阶段
//开始一帧一帧解码
-(void)fan_decodeVideoH264:(NSData *)videoData length:(long)length decodedVideoDataBlock:(FanDecodedVideoDataBlock)decodedVideoDataBlock;
//结束解码，释放全部
-(void)fan_stopDecodeH264;



@end
