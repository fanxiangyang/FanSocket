//
//  FanMediaManager.m
//  FanVideoEcode
//
//  Created by 向阳凡 on 2018/5/23.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import "FanMediaManager.h"
#import "FanAACPlayer.h"
#import "FanUdpSocketManager.h"

@implementation FanMediaManager{
    FanAACPlayer *_aacPlayer;
}

-(instancetype)init{
    self=[super init];
    if (self) {
//        [self startEncoderH264];
    }
    return self;
}
-(void)startEncoderH264{
    if (self.encoderH264) {
        [self.encoderH264 fan_endEncodeVideo];
        self.encoderH264=nil;
    }
    self.encoderH264=[[FanEncoderH264 alloc]initWithEncodeResolutionType:EncodeResolutionType640x480];
    
    self.aacEncoder=[[FanAACEncoder alloc]init];
    
    _aacPlayer=[[FanAACPlayer alloc]init];
    //录制到本地
//    [self.encoderH264 fan_createFileHandle:@"1.mp4" audioFileName:@"1.aac"];
}
-(void)endEncoderH264{
    if (self.encoderH264) {
        [self.encoderH264 fan_endEncodeVideo];
        self.encoderH264=nil;
    }
}
#pragma mark 初始化相机处理
/// 打开相机
-(BOOL)openCaptureWithShowView:(UIView *)videoPreView{
    _videoPreView=videoPreView;
    AVAuthorizationStatus deviceStatus=[AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (deviceStatus == AVAuthorizationStatusRestricted||deviceStatus==AVAuthorizationStatusDenied) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"没有相机权限，或者不能打开摄像机！");
            
        });
        return NO;
    }
    
    self.captureSession = [[AVCaptureSession alloc]init];
    [self.captureSession setSessionPreset:AVCaptureSessionPresetHigh];//AVCaptureSessionPresetPhoto
    
    //摄像头设备
    AVCaptureDevice *captureDevice=[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //captureDevice.position = AVCaptureDevicePositionBack;只读的
//    CMFormatDescriptionRef formatDesc = captureDevice.activeFormat.formatDescription;
//    CMVideoFormatDescriptionGetDimensions(formatDesc);
    //设备输入口
    NSError *error = nil;
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (error || !captureInput) {
        NSLog(@"error:%@",[error description]);
        return NO;
    }
    //  把输入口加入会话session
    if ([self.captureSession canAddInput:captureInput]) {
        [self.captureSession addInput:captureInput];
    }else{
        return NO;
    }
    
    _movieOutput=[[AVCaptureVideoDataOutput alloc]init];
    [_movieOutput setAlwaysDiscardsLateVideoFrames:NO];  // 是否抛弃延迟的帧：NO

    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* val = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
    NSDictionary* videoSettings =[NSDictionary dictionaryWithObject:val forKey:key];
    
    NSError *errorDevice;
    [captureDevice lockForConfiguration:&errorDevice];
    if (errorDevice==nil) {
        if (captureDevice.activeFormat.videoSupportedFrameRateRanges) {
            [captureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 20)];
            [captureDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 20)];
        }
    }
    [captureDevice unlockForConfiguration];
    
    _movieOutput.videoSettings=videoSettings;
    [_movieOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    
    if ([self.captureSession canAddOutput:_movieOutput]) {
        [self.captureSession addOutput:_movieOutput];
    }else{
        return NO;
    }
    
    //    [_captureSession beginConfiguration];
    
    AVCaptureConnection *captureConnection = [_movieOutput connectionWithMediaType:AVMediaTypeVideo];
    // 视频稳定设置
    if ([captureConnection isVideoStabilizationSupported]) {
        captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }
    captureConnection.videoScaleAndCropFactor = captureConnection.videoMaxScaleAndCropFactor;
    captureConnection.videoOrientation=[self videoOrientationFromCurrentDeviceOrientation];
    
    if (_isOpenAudio) {
        AVAuthorizationStatus audioDeviceStatus=[AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
        if (deviceStatus == AVAuthorizationStatusRestricted||deviceStatus==AVAuthorizationStatusDenied) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"没有麦克风权限，或者不能打开麦克风！");
                
            });
            return NO;
        }

        /*-------------input---------*/
        NSError *audioError;
        // 添加一个音频输入设备
        AVCaptureDevice* _audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        //  音频输入对象
        AVCaptureDeviceInput *_audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:_audioDevice error:&audioError];
        if (audioError) {
            NSLog(@"取得录音设备时出错 ------ %@",audioError);
        }
        // 输出流
        AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [audioOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        // 添加输入输出流
       
        // 将音频输入对象添加到会话 (AVCaptureSession) 中
        if ([_captureSession canAddInput:_audioInput]) {
            [_captureSession addInput:_audioInput];
        }else{
            return NO;
        }
        if ([_captureSession canAddOutput:audioOutput]) {
            [_captureSession addOutput:audioOutput];
        }else{
            return NO;
        }
        
    }
    
    //设置预览层信息
    if (!self.captureVideoPreviewLayer) {
        self.captureVideoPreviewLayer=[AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    }
    self.captureVideoPreviewLayer.frame=_videoPreView.layer.bounds;
    //    self.captureVideoPreviewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    self.captureVideoPreviewLayer.connection.videoOrientation=[self videoOrientationFromCurrentDeviceOrientation];
    [_videoPreView.layer addSublayer:self.captureVideoPreviewLayer];
    
    //启动扫描
    [self.captureSession startRunning];
    
    //开启编码准备程序
    [self startEncoderH264];

    return  YES;
}
//解决视频旋转问题
- (AVCaptureVideoOrientation) videoOrientationFromCurrentDeviceOrientation {
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortrait: {
            return AVCaptureVideoOrientationPortrait;
        }
        case UIInterfaceOrientationLandscapeLeft: {
            return AVCaptureVideoOrientationLandscapeLeft;
        }
        case UIInterfaceOrientationLandscapeRight: {
            return AVCaptureVideoOrientationLandscapeRight;
        }
        case UIInterfaceOrientationPortraitUpsideDown: {
            return AVCaptureVideoOrientationPortraitUpsideDown;
        }
        default:
            return AVCaptureVideoOrientationPortrait;
            break;
    }
}
-(void)stopVideo{
    [self.captureSession stopRunning];
    [self.captureVideoPreviewLayer removeFromSuperlayer];
    //不设置空，第二次打开时，画面卡着不动，但是数据回调是走的
    self.captureVideoPreviewLayer=nil;
    self.captureSession=nil;
    //停止编码
    [self endEncoderH264];
    
    if (_aacPlayer) {
//        [_aacPlayer fan_stop];
        [_aacPlayer fan_audioPause];
        _aacPlayer =nil;
    }
    
    _aacEncoder=nil;
}
#pragma mark AVCaptureMetadataOutputObjectsDelegate//iOS7以后下触发
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if ([_movieOutput isEqual:captureOutput]) {
        //视频数据
        //将视频数据转换成YUV420数据
//        NSData *yuv420Data = [self convertVideoSampleToYUV420:sampleBuffer];
        
        // 摄像头采集后的图像是未编码的CMSampleBuffer形式，
        [self.encoderH264 fan_encodeVideo:sampleBuffer encodeBlock:^(NSData *data, NSString *errorStr) {
            //编码成功后，数据发送到
            if(errorStr){
                NSLog(@"编码失败:%@",errorStr);
            }else{
                //发送data
                NSLog(@"视频编码后长度:%ld :%@",data.length,@"");
                if (self.returnDataH264Block) {
                    self.returnDataH264Block(data);
                }
//                [[FanUdpSocketManager defaultManager]sendData:data type:UdpSocketTypeVideoStream toHost:@"192.168.1.193" port:6001];

            }
        }];
    }else{
        //音频
        [self.aacEncoder fan_encodeSampleBuffer:sampleBuffer completionBlock:^(NSData *data, NSError *error) {
            if (error) {
                NSLog(@"音频编码错误:%@",error);
            }else{
                NSLog(@"音频编码成功:%ld",data.length);
                // 开始播放音频 (必须在主线程刷新)
                [[FanUdpSocketManager defaultManager]sendData:data type:UdpSocketTypeAudioStream toHost:@"192.168.1.193" port:6001];

                dispatch_sync(dispatch_get_main_queue(), ^{
//                    [_aacPlayer fan_playAudioWithData:data length:data.length];

                });
            }
        }];
       
    }
    
    
}


@end
