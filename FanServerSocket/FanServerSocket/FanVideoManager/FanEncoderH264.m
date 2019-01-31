//
//  FanEncoderH264.m
//  FanVideoEcode
//
//  Created by 向阳凡 on 2018/5/23.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import "FanEncoderH264.h"

@interface FanEncoderH264()
//编码会话
@property (nonatomic, assign)VTCompressionSessionRef encodeingSession;

@end

@implementation FanEncoderH264{
    //是否开始了硬编码
    BOOL _isStartHardEncoding;
    //编码队列
    dispatch_queue_t _encodeQueue;
    int _frameID;//帧编号
    //给定宽高,过高的话会编码失败
    int _videoWidth, _videoHeight;
    
}
-(instancetype)init{
    self=[super init];
    if (self) {
        _encodeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);//全局队列，后台执行
        _videoWidth=640;
        _videoHeight=480;
    }
    return self;
}
-(void)dealloc{
    NSLog(@"%s",__func__);
}
-(instancetype)initWithEncodeResolutionType:(EncodeResolutionType)resolutionType{
    self=[super init];
    if (self) {
        _encodeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);//全局队列，后台执行
        _resolutionType=resolutionType;
        [self fan_initVideoToolBox];
    }
    return self;
}
/*
 1、-initVideoToolBox中调用VTCompressionSessionCreate创建编码session，然后调用VTSessionSetProperty设置参数，最后调用VTCompressionSessionPrepareToEncodeFrames开始编码；
 2、开始视频录制，获取到摄像头的视频帧，传入-encode:，调用VTCompressionSessionEncodeFrame传入需要编码的视频帧，如果返回失败，调用VTCompressionSessionInvalidate销毁session，然后释放session；
 3、每一帧视频编码完成后会调用预先设置的编码函数didCompressH264，如果是关键帧需要用CMSampleBufferGetFormatDescription获取CMFormatDescriptionRef，然后用
 CMVideoFormatDescriptionGetH264ParameterSetAtIndex取得PPS和SPS；
 最后把每一帧的所有NALU数据前四个字节变成0x00 00 00 01之后再写入文件；
 4、调用VTCompressionSessionCompleteFrames完成编码，然后销毁session：VTCompressionSessionInvalidate，释放session。
 
 */

#pragma mark - 编码准备
/**
 初始化videoToolBox,初始化硬件编码配置
 */
-(void)fan_initVideoToolBox{
    _frameID = 0;
    //给定宽高,过高的话会编码失败
    switch (_resolutionType) {
        case EncodeResolutionType640x480:
        {
            _videoWidth=640;
            _videoHeight=480;
        }
            break;
        case EncodeResolutionType960x540:
        {
            _videoWidth=960;
            _videoHeight=540;
        }
            break;
        case EncodeResolutionType1280x720:
        {
            _videoWidth=1280;
            _videoHeight=720;
        }
            break;
        case EncodeResolutionType1920x1080:
        {
            _videoWidth=1920;
            _videoHeight=1080;
        }
            break;
            
        default:{
            _videoWidth=640;
            _videoHeight=480;
        }
            break;
    }
    __block int width = _videoWidth;
    __block int height = _videoHeight;

    //在后台 同步执行 （同步，需要加锁）
    dispatch_sync(_encodeQueue, ^{
        
        /**
         创建编码会话
         
         @param allocator#> 会话的分配器,传入NULL默认 description#>
         @param width#> 帧宽 description#>
         @param height#> 帧高 description#>
         @param codecType#> 编码器类型 description#>
         @param encoderSpecification#> 指定必须使用的特定视频编码器。通过空来让视频工具箱选择一个编码器。 description#>
         @param sourceImageBufferAttributes#> 像素缓存池源帧 description#>
         @param compressedDataAllocator#> 压缩数据分配器,默认为空 description#>
         @param outputCallback#> 回调函数,图像编码成功后调用 description#>
         @param outputCallbackRefCon#> 客户端定义的输出回调的参考值。 description#>
         @param compressionSessionOut#> 指向一个变量，以接收新的压缩会话 description#>
         @return <#return value description#>
         */
        OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, didCompressH264, (__bridge void *)(self), &_encodeingSession);
        
        NSLog(@"H264状态:VTCompressionSessionCreate %d",(int)status);
        
        if (status != 0) {
            
            NSLog(@"H264会话创建失败");
            return ;
        }
        
        //设置实时编码输出(避免延迟)
        VTSessionSetProperty(_encodeingSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        VTSessionSetProperty(_encodeingSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
        
        // 设置关键帧（GOPsize)间隔,gop太小的话有时候图像会糊
        int frameInterval = 10;
        CFNumberRef  frameIntervalRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &frameInterval);
        VTSessionSetProperty(_encodeingSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, frameIntervalRef);
        
        // 设置期望帧率,不是实际帧率
        int fps = 10;
        CFNumberRef fpsRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &fps);
        VTSessionSetProperty(_encodeingSession, kVTCompressionPropertyKey_ExpectedFrameRate, fpsRef);
        
        //设置码率，上限，单位是bps
        int bitRate = width * height * 3 * 4 * 8 ;
        CFNumberRef bitRateRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRate);
        VTSessionSetProperty(_encodeingSession, kVTCompressionPropertyKey_AverageBitRate, bitRateRef);
        
        // 设置码率，均值，单位是byte
        int bitRateLimit = width * height * 3 * 4 ;
        CFNumberRef bitRateLimitRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRateLimit);
        NSLog(@"码率:%@",bitRateLimitRef);
        VTSessionSetProperty(_encodeingSession, kVTCompressionPropertyKey_DataRateLimits, bitRateLimitRef);
        
        //可以开始编码
        VTCompressionSessionPrepareToEncodeFrames(_encodeingSession);
        
    });
}
#pragma mark - H264编码
/**
 视频编码
 */
-(void)fan_encodeVideo:(CMSampleBufferRef)videoSampleBuffer encodeBlock:(FanEncodeH264DataBlock)encodeBlock{
    _encodeH264DataBlock=encodeBlock;
    //必须同步，异步会报错
    dispatch_sync(_encodeQueue, ^{
        [self fan_encodeVideo:videoSampleBuffer];
    });
}
/**
 视频编码
  */
-(void)fan_encodeVideo:(CMSampleBufferRef)videoSampleBuffer{
    
    // CVPixelBufferRef 编码前图像数据结构
    // 利用给定的接口函数CMSampleBufferGetImageBuffer从中提取出CVPixelBufferRef
    CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(videoSampleBuffer);
    
    // 帧时间, 如果不设置会导致时间轴过长
    CMTime presentationTimeStamp = CMTimeMake(_frameID++, 1000);// CMTimeMake(分子，分母)；分子/分母 = 时间(秒)
    VTEncodeInfoFlags flags;
    
    // 使用硬编码接口VTCompressionSessionEncodeFrame来对该帧进行硬编码
    // 编码成功后，会自动调用session初始化时设置的回调函数
    OSStatus statusCode = VTCompressionSessionEncodeFrame(_encodeingSession, imageBuffer, presentationTimeStamp, kCMTimeInvalid, NULL, NULL, &flags);
    
    if (statusCode != noErr) {
        NSString *errStr=[NSString stringWithFormat:@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode];
        
//        NSLog(errStr);
        if (self.encodeH264DataBlock) {
            self.encodeH264DataBlock(nil, errStr);
        }
        //释放后，下一包来领，就更新不了了
//        if (_encodeingSession) {
//            VTCompressionSessionCompleteFrames(_encodeingSession, kCMTimeInvalid);
//            VTCompressionSessionInvalidate(_encodeingSession);
//            CFRelease(_encodeingSession);
//            _encodeingSession = NULL;
//        }

        return;
    }
}
/**
 *  h.264硬编码完成后回调 VTCompressionOutputCallback
 *  将硬编码成功的CMSampleBuffer转换成H264码流，通过网络传播
 *  解析出参数集SPS和PPS，加上开始码后组装成NALU。提取出视频数据，将长度码转换成开始码，组长成NALU。将NALU发送出去。
 */

//编码完成后回调
void didCompressH264(void *outputCallbackRefCon, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer){
    
    //    NSLog(@"didCompressH264 called with status %d infoFlags %d", (int)status, (int)infoFlags);
    //状态错误
    if (status != 0) {
        return;
    }
    
    //没准备好
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        
        NSLog(@"didCompressH264 data is not ready ");
        return;
    }
    
    FanEncoderH264 * encoder = (__bridge FanEncoderH264*)outputCallbackRefCon;
    
    bool keyframe = !CFDictionaryContainsKey( (CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
    
    // 判断当前帧是否为关键帧 获取sps & pps 数据
    // 解析出参数集SPS和PPS，加上开始码后组装成NALU。提取出视频数据，将长度码转换成开始码，组长成NALU。将NALU发送出去。
    if (keyframe) {
        
        // CMVideoFormatDescription：图像存储方式，编解码器等格式描述
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        // sps
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus statusSPS = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0);
        if (statusSPS == noErr) {
            
            // Found sps and now check for pps
            // pps
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusPPS = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0);
            if (statusPPS == noErr) {
                
                // found sps pps
                NSData *sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                NSData *pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                if (encoder) {
                    
                    [encoder gotSPS:sps withPPS:pps];
                }
            }
        }
    }
    
    // 编码后的图像，以CMBlockBuffe方式存储
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr) {
        
        size_t bufferOffSet = 0;
        // 返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
        static const int AVCCHeaderLength = 4;
        
        // 循环获取nalu数据
        while (bufferOffSet < totalLength - AVCCHeaderLength) {
            
            uint32_t NALUUnitLength = 0;
            // Read the NAL unit length
            memcpy(&NALUUnitLength, dataPointer + bufferOffSet, AVCCHeaderLength);
            // 从大端转系统端
            NALUUnitLength = CFSwapInt32BigToHost(NALUUnitLength);
            NSData *data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffSet + AVCCHeaderLength) length:NALUUnitLength];
            [encoder gotEncodedData:data isKeyFrame:keyframe];
            
            // Move to the next NAL unit in the block buffer
            bufferOffSet += AVCCHeaderLength + NALUUnitLength;
        }
    }
}

//传入PPS和SPS,写入到文件
// 获取sps & pps数据
/*
 序列参数集SPS：作用于一系列连续的编码图像；
 图像参数集PPS：作用于编码视频序列中一个或多个独立的图像；
 */
- (void)gotSPS:(NSData *)sps withPPS:(NSData *)pps{
    
    //    NSLog(@"gotSPSAndPPS %d withPPS %d", (int)[sps length], (int)[pps length]);
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *byteHeader = [NSData dataWithBytes:bytes length:length];
    NSMutableData *totalData=[[NSMutableData alloc]init];
    [totalData appendData:byteHeader];
    [totalData appendData:sps];
    [self fan_encodeH264Success:totalData];
    //分开两包便于接收方判断，
    NSMutableData *totalData1=[[NSMutableData alloc]init];
    [totalData1 appendData:byteHeader];
    [totalData1 appendData:pps];
    [self fan_encodeH264Success:totalData1];
}

- (void)gotEncodedData:(NSData *)data isKeyFrame:(BOOL)isKeyFrame {
    
    // 把每一帧的所有NALU数据前四个字节变成0x00 00 00 01之后再写入文件
    const char bytes[]= "\x00\x00\x00\x01";
    size_t lenght = (sizeof bytes) - 1; //字符串文字具有隐式结尾 '\0'  。    把上一段内容中的’\0‘去掉，
    NSData *byteHeader = [NSData dataWithBytes:bytes length:lenght];
    NSMutableData *totalData=[[NSMutableData alloc]init];
    [totalData appendData:byteHeader];
    [totalData appendData:data];
    [self fan_encodeH264Success:totalData];

}
-(void)fan_encodeH264Success:(NSData *)data{
    if (self.encodeH264DataBlock) {
        //先回调出去，用来TCP 或者UDP上传
        self.encodeH264DataBlock(data, nil);
    }
}

/**
 结束编码
 */
- (void)fan_endEncodeVideo{
    if (_encodeingSession) {
        VTCompressionSessionCompleteFrames(_encodeingSession, kCMTimeInvalid);
        VTCompressionSessionInvalidate(_encodeingSession);
        CFRelease(_encodeingSession);
        _encodeingSession = NULL;
    }
}

#pragma mark -  SmapleBuffer转换
-(NSData *)convertVideoSampleToYUV420:(CMSampleBufferRef)videoSample{
    
    // 获取yuv数据
    // 通过CMSampleBufferGetImageBuffer方法，获得CVImageBufferRef。
    // 这里面就包含了yuv420(NV12)数据的指针
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(videoSample);
    
    //表示开始操作数据
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    //图像宽度（像素）
    size_t pixelWidth = CVPixelBufferGetWidth(pixelBuffer);
    //图像高度（像素）
    size_t pixelHeight = CVPixelBufferGetHeight(pixelBuffer);
    
    //yuv中的y所占字节数
    size_t y_size = pixelWidth * pixelHeight;
    //yuv中的uv所占的字节数
    size_t uv_size = y_size / 2;
    
    //开创空间
    uint8_t *yuv_frame = malloc(uv_size + y_size);
    
    //清0
    memset(yuv_frame, 0, y_size+uv_size);
    
    
    //获取CVImageBufferRef中的y数据
    uint8_t *y_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    memcpy(yuv_frame, y_frame, y_size);
    
    //获取CMVImageBufferRef中的uv数据
    uint8_t *uv_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    memcpy(yuv_frame+y_size, uv_frame, uv_size);
    
    //锁定操作
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    //返回数据
    return [NSData dataWithBytesNoCopy:yuv_frame length:y_size+uv_size];
}

-(NSData *)convertAudioSampleToYUV420:(CMSampleBufferRef)audioSample{
    
    //获取pcm数据大小
    NSInteger audioDataSize = CMSampleBufferGetTotalSampleSize(audioSample);
    
    //分配空间
    int8_t *audio_data = malloc(audioDataSize);
    
    //清0
    memset(audio_data, 0, audioDataSize);
    
    //获取CMBlockBufferRef
    //这个结构里面就保存了 PCM数据
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(audioSample);
    
    //直接将数据copy至我们自己分配的内存中
    CMBlockBufferCopyDataBytes(dataBuffer, 0, audioDataSize, audio_data);
    
    //返回数据
    return [NSData dataWithBytesNoCopy:audio_data length:audioDataSize];
}


@end
