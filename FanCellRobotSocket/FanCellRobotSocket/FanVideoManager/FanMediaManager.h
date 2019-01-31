//
//  FanMediaManager.h
//  FanVideoEcode
//
//  Created by 向阳凡 on 2018/5/23.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "FanEncoderH264.h"
#import "FanAACEncoder.h"

typedef void(^FanReturnDataH264Block)(NSData *data);


@interface FanMediaManager : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
/**
 *  预览层Layer
 */
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
/**
 *  会话session
 */
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoDataOutput *movieOutput;

@property (nonatomic, weak) UIView *videoPreView;//传过来的预览View


@property (nonatomic, assign)BOOL isOpenAudio;//默认不开起

@property (nonatomic, strong)FanEncoderH264 *encoderH264;
@property (nonatomic, strong)FanAACEncoder *aacEncoder;


@property (nonatomic, copy)FanReturnDataH264Block returnDataH264Block;



-(BOOL)openCaptureWithShowView:(UIView *)videoPreView;
-(void)stopVideo;

/**
 每次开启摄像头之前，要开启次方法，不然就无法解析；我可以内置到 打开摄像头的方法里面
 */
-(void)startEncoderH264;
-(void)endEncoderH264;

- (AVCaptureVideoOrientation) videoOrientationFromCurrentDeviceOrientation;

@end
