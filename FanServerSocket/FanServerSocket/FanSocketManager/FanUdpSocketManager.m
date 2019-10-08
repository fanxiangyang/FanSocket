//
//  FanUdpSocketManager.m
//  FanServerSocket
//
//  Created by 向阳凡 on 2018/5/21.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import "FanUdpSocketManager.h"
//#import "FanFileHandle.h"
//#import "FanAACPlayer.h"
#import "FanToolBox.h"

@implementation UdpSocketModel

-(BOOL)configWithData:(NSData *)data address:(NSString*)address{
    if (data.length<10) {
        //不够一包数据
        return NO;
    }
    _type=(UInt16)[FanDataTool fan_unpack_int16:[data subdataWithRange:NSMakeRange(0, 2)]bigEndian:NO];
    _length=(UInt16)[FanDataTool fan_unpack_int16:[data subdataWithRange:NSMakeRange(2, 2)]bigEndian:NO];
    _total=(UInt16)[FanDataTool fan_unpack_int16:[data subdataWithRange:NSMakeRange(4, 2)]bigEndian:NO];
    _page=(UInt16)[FanDataTool fan_unpack_int16:[data subdataWithRange:NSMakeRange(6, 2)]bigEndian:NO];
    _index=(UInt16)[FanDataTool fan_unpack_int16:[data subdataWithRange:NSMakeRange(8, 2)]bigEndian:NO];
    if (data.length-10!=_length) {
        //数据包不完整
        return NO;
    }
    if (_total==0) {
        //不分页
        _data=[[NSMutableData alloc]init];
        [_data appendData:[data subdataWithRange:NSMakeRange(10, data.length-10)]];
        _isComplete=YES;
    }else{
        if (_page==1) {
            _isComplete=NO;
            _data=[[NSMutableData alloc]init];
            [_data appendData:[data subdataWithRange:NSMakeRange(10, data.length-10)]];
        }else{
            if (_data==nil) {
                _data=[[NSMutableData alloc]init];
            }
            [_data appendData:[data subdataWithRange:NSMakeRange(10, data.length-10)]];
        }
        if (_page==_total) {
            //最后一页，
            _isComplete=YES;
        }
    }
    if (_isComplete) {
        //数据接收完成
        if (_type==0) {
            _message=[[NSString alloc]initWithData:_data encoding:NSUTF8StringEncoding];
        }
    }
    
    _address=address;
    
    return YES;
}

-(void)clear{
    _type=0;
    _length=0;
    _total=0;
    _page=0;
    _index=0;
    _data=nil;
    _message=nil;
    _address=@"";
    _ipAddress=@"";
    _port=0;
}
-(UdpSocketModel *)copyModel{
    UdpSocketModel *model=[[UdpSocketModel alloc]init];
    model.type=_type;
    model.length=_length;
    model.total=_total;
    model.page=_page;
    model.index=_index;
    model.data=[_data copy];
    model.message=[_message copy];
    model.address=[_address copy];
    model.ipAddress=[_ipAddress copy];
    model.port=_port;
    return model;
}
-(NSData *)getData{
    NSMutableData *data=[[NSMutableData alloc]init];
    [data appendData:[FanDataTool fan_pack_int16:_type bigEndian:NO]];
    [data appendData:[FanDataTool fan_pack_int16:_length bigEndian:NO]];
    [data appendData:[FanDataTool fan_pack_int16:_total bigEndian:NO]];
    [data appendData:[FanDataTool fan_pack_int16:_page bigEndian:NO]];
    [data appendData:[FanDataTool fan_pack_int16:_index bigEndian:NO]];
    if(_data){
        [data appendData:_data];
    }else if(_message){
        [data appendData:[_message dataUsingEncoding:NSUTF8StringEncoding]];
    }else{
        //        NSLog(@"UDP数据包不完整或为空！");
    }
    return data;
}
+(NSData *)getDataWithMessage:(NSString *)message{
    NSData *data=[message dataUsingEncoding:NSUTF8StringEncoding];
    return  [[self class] getDataWithType:0 length:data.length data:data];
}
+(NSData *)getDataWithType:(UInt16)type length:(UInt16)length data:(NSData *)data{
    NSMutableData *mData=[[NSMutableData alloc]init];
    [mData appendData:[FanDataTool fan_pack_int16:type bigEndian:NO]];
    [mData appendData:[FanDataTool fan_pack_int16:length bigEndian:NO]];
    [mData appendData:[FanDataTool fan_pack_int16:0 bigEndian:NO]];
    [mData appendData:[FanDataTool fan_pack_int16:0 bigEndian:NO]];
    [mData appendData:[FanDataTool fan_pack_int16:0 bigEndian:NO]];
    [mData appendData:data];
    return mData;
}
@end
@implementation FanUdpSocketManager{
    //    FanFileHandle *fanFileHandle;
    //    FanAACPlayer *_aacPlayer;
}

+(instancetype)defaultManager{
    static FanUdpSocketManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager=[[FanUdpSocketManager alloc]init];
    });
    return manager;
}


-(instancetype)init{
    self=[super init];
    if (self) {
        self.socketQueue = dispatch_queue_create("socketQueue", DISPATCH_QUEUE_SERIAL);
        //        self.socketQueue = dispatch_get_main_queue();
        self.localUdpSocket=[[GCDAsyncUdpSocket alloc]initWithDelegate:self delegateQueue:self.socketQueue];
        //接收每包数据
        _socketModel=[[UdpSocketModel alloc]init];
    }
    return self;
}


-(void)startUdpSocket{
    if (_localUdpSocket.isClosed==NO) {
        return;
    }
    //2.banding一个端口(可选),如果不绑定端口, 那么就会随机产生一个随机的电脑唯一的端口
    //端口数字范围(1024,2^16-1)
    NSError * error = nil;
    [_localUdpSocket bindToPort:9634 error:&error];
    
    if (error) {//监听错误打印错误信息
        NSLog(@"error:%@",error);
    }else {//监听成功则开始接收信息
        [_localUdpSocket beginReceiving:&error];//这个是持续接收消息
    }
    
    NSString *ip = [FanToolBox fan_IPAdress];
    NSLog(@"host:%@",ip);
    //录制到本地,调试功能
    //    fanFileHandle=[[FanFileHandle alloc]init];
    //    [fanFileHandle fan_createFileHandle:@"1.mp4" audioFileName:@"2.aac"];
    //
    //    _aacPlayer=[[FanAACPlayer alloc]init];
}
-(void)stopUdpSocket{
    [self stopUDPBroad];
    [_localUdpSocket close];
}

-(void)startUDPBroad:(NSTimeInterval)timeInterval{
    [_broadTimer invalidate];
    _broadTimer = nil;
    //启用广播
    NSError * broadError = nil;
    [_localUdpSocket enableBroadcast:YES error:&broadError];
    if (broadError) {//监听错误打印错误信息
        NSLog(@"开启广播出错:%@",broadError);
    }else{
        _broadTimer=[NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(broadcast) userInfo:nil repeats:YES];
        [_broadTimer fire];
    }
}
//通知广播
-(void)stopUDPBroad{
    [_broadTimer invalidate];
    _broadTimer = nil;
    //启用广播
    NSError * broadError = nil;
    [_localUdpSocket enableBroadcast:NO error:&broadError];
    if (broadError) {//监听错误打印错误信息
        NSLog(@"关闭广播出错:%@",broadError);
    }else{
    }
}
//发送广播数据
-(void)broadcast{
    NSLog(@"发送广播");//192.168.1.255
    [self sendData:nil type:666 toHost:@"255.255.255.255" port:9634];
    //    [self sendMessage:@"我是广播数据！" toHost:@"255.255.255.255" port:9633];
    //    Byte boardByte[]={0x00};
    //    NSData *data=[NSData dataWithBytes:boardByte length:1];
    //    [self sendData:data type:667 toHost:@"255.255.255.255" port:9633];
    
    //    [self sendMessage:@"我是谁啊" toHost:@"192.168.1.193" port:9633];
    
}




-(void)sendMessage:(NSString *)message toHost:(NSString *)host port:(uint16_t)port{
    NSData *data=[message dataUsingEncoding:NSUTF8StringEncoding];
    [self sendData:data type:UdpSocketTypeTxt toHost:host port:port];
}
-(void)sendByte:(Byte *)bytes length:(NSInteger)length type:(UInt16)type toHost:(NSString *)host port:(uint16_t)port{
    NSData *data=[NSData dataWithBytes:bytes length:length];
    [self sendData:data type:type toHost:host port:port];
}
-(void)sendData:(NSData *)data type:(UInt16)type toHost:(NSString *)host port:(uint16_t)port{
    if (data==nil) {
        UdpSocketModel *socketModel=[[UdpSocketModel alloc]init];
        socketModel.type=type;
        socketModel.length=0;
        socketModel.total=0;
        socketModel.page=0;
        NSData *packData=[socketModel getData];
        [_localUdpSocket sendData:packData toHost:host port:port withTimeout:-1 tag:100];
    }else{
        UInt16 tPage=data.length/UdpPackSize;
        int t=data.length%(UdpPackSize)?1:0;
        for (int i=0; i<tPage+t; i++) {
            UdpSocketModel *socketModel=[[UdpSocketModel alloc]init];
            socketModel.type=type;
            socketModel.length=UdpPackSize;
            if (i==tPage&&t==1) {
                socketModel.length=data.length%UdpPackSize;
            }
            socketModel.total=t+tPage;
            socketModel.page=i+1;
            socketModel.data=[[data subdataWithRange:NSMakeRange(i*UdpPackSize, socketModel.length)] mutableCopy];
            NSData *packData=[socketModel getData];
            [_localUdpSocket sendData:packData toHost:host port:port withTimeout:-1 tag:100];
        }
    }
}
#pragma mark - GCDAsyncUdpSocketDelegate
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
    //发送数据成功
}
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error{
    NSLog(@"发送失败Tag：%ld==%@",tag,error);
}
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext{
    //address当是广播数据时候，会接收两条，
    //第一条28个字节【::ffff:192.168.1.126:9633】 第二条 16个字节【192.168.1.126:9633】
    
    //接受数据
    NSString *ip = [GCDAsyncUdpSocket hostFromAddress:address];
    uint16_t port = [GCDAsyncUdpSocket portFromAddress:address];
//    NSLog(@"收到UDP的数据: [%@:%d] leng=%ld  data:%@", ip, port,data.length,data);
    
    NSString *ipport=[NSString stringWithFormat:@"%@:%d", ip, port];
    if ([ip hasPrefix:@"::ffff:"]) {
        //广播数据的自己接受的第一条
        
    }else{
        if([_socketModel configWithData:data address:ipport]){
            if (_socketModel.isComplete) {
                //完整包
                _socketModel.ipAddress=ip;
                _socketModel.port=port;
                [self analysis:[_socketModel copyModel]];
            }
        }
    }
    
    // 继续来等待接收下一次消息
    [sock receiveOnce:nil];//这个是只接收一条
    
    //    [self sendMessage:@"我收到了" toHost:ip port:port];
    
    
    
    //此处根据实际和硬件商定的需求决定是否主动回一条消息
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    //        [self sendMessage:@"我收到了" toHost:ip port:port];
    //    });
}
-(void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error{
    //udpSocket关闭
    NSLog(@"udpSocket关闭");
}
NSTimeInterval timeInterval=0.0f;
#pragma mark - 发送解析协议
//解析每包数据
-(void)analysis:(UdpSocketModel *)pack{
    switch (pack.type) {
        case UdpSocketTypeTxt:
        {
            //文本，字符串
            //            NSLog(@"接收UDP文本：%@",pack.message);
            
           NSTimeInterval tv=[NSDate timeIntervalSinceReferenceDate];
            NSLog(@"%f",tv-timeInterval);
            timeInterval=tv;
            return;

        }
            break;
        case UdpSocketTypePng:
        {
            //图片
        }
            break;
        case UdpSocketTypeJpg:
        {
            //图片
        }
            break;
        case UdpSocketTypeGif:
        {
            //GIF
        }
            break;
        case UdpSocketTypeMp3:
        {
            //视频
        }
            break;
        case UdpSocketTypeWav:
        {
            //音频
        }
            break;
        case UdpSocketTypeMp4:
        {
            //视频
        }
            break;
        case UdpSocketTypeMov:
        {
            //视频
        }
            break;
        case UdpSocketTypeXml:
        {
            //XML
        }
            break;
        case UdpSocketTypeVideoStream:
        {
            //video
            //            if (fanFileHandle != NULL) {
            //                [fanFileHandle fan_writeVideoData:pack.data];
            //            }
        }
            break;
        case UdpSocketTypeAudioStream:
        {
            //audio
            //            if (fanFileHandle != NULL) {
            //                [fanFileHandle fan_writeAudioData:pack.data];
            //            }
            //
            //            [_aacPlayer fan_playAudioWithData:pack.data length:pack.data.length];
            
            
        }
            break;
            
        default:
            break;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.receiveUdpSocketBlock) {
            self.receiveUdpSocketBlock(pack);
        }
    });
}
@end
