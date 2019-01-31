//
//  FanSocketManager.m
//  FanServerSocket
//
//  Created by 向阳凡 on 2018/5/12.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import "FanSocketManager.h"
#import "FanDataTool.h"
#import "FanToolBox.h"

#pragma mark - SocketModel数据包解析对象
@implementation SocketModel
-(void)configWithData:(NSData *)data tag:(NSUInteger)tag{
    if (tag==TAG_HEADER) {
        [self clear];
        _type=(UInt16)[FanDataTool fan_unpack_int16:[data subdataWithRange:NSMakeRange(0, 2)]bigEndian:NO];
        _index=(UInt16)[FanDataTool fan_unpack_int16:[data subdataWithRange:NSMakeRange(2, 2)]bigEndian:NO];
        _length=(UInt32)[FanDataTool fan_unpack_int32:[data subdataWithRange:NSMakeRange(4, 4)]bigEndian:NO];
        _data=[[NSMutableData alloc]init];
        if (_type>=SocketTypeCommand) {
            _command=_type;
            _type=SocketTypeCommand;
        }
    }else if(tag==TAG_BODY){
        [_data appendData:data];
        if (_type==SocketTypeTxt||_type==SocketTypeCommand) {
            _message=[[NSString alloc]initWithData:_data encoding:NSUTF8StringEncoding];
        }else if (_type==SocketTypeJson){
            _jsonDic=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        }
    }
}
-(void)clear{
    _type=0;
    _length=0;
    _index=0;
    _page=0;
    _command=0;
    _data=nil;
    _message=nil;
}
-(NSData *)getData{
    NSMutableData *data=[[NSMutableData alloc]init];
    [data appendData:[FanDataTool fan_pack_int16:_type bigEndian:NO]];
    [data appendData:[FanDataTool fan_pack_int16:_index bigEndian:NO]];
    [data appendData:[FanDataTool fan_pack_int32:_length bigEndian:NO]];

    if(_data){
        [data appendData:_data];
    }else if(_message){
        [data appendData:[_message dataUsingEncoding:NSUTF8StringEncoding]];
    }else{
        NSLog(@"数据表不完成或为空！");
    }
    return data;
}
+(NSData *)getDataWithMessage:(NSString *)message type:(UInt16)type index:(UInt16)index{
    NSData *data=[message dataUsingEncoding:NSUTF8StringEncoding];
    return  [[self class] getDataWithType:type length:(UInt32)data.length index:index data:data];
}
+(NSData *)getDataWithType:(UInt16)type length:(UInt32)length index:(UInt16)index data:(NSData *)data{
    NSMutableData *mData=[[NSMutableData alloc]init];
    [mData appendData:[FanDataTool fan_pack_int16:type bigEndian:NO]];
    [mData appendData:[FanDataTool fan_pack_int16:index bigEndian:NO]];
    [mData appendData:[FanDataTool fan_pack_int32:length bigEndian:NO]];
    if (data) {
        [mData appendData:data];
    }
    return mData;
}
@end

#pragma mark - FanSocketManager管理对象

@implementation FanSocketManager
+(instancetype)defaultManager{
    static FanSocketManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager=[[FanSocketManager alloc]init];
    });
    return manager;
}


-(instancetype)init{
    self=[super init];
    if (self) {
        self.debugLog=YES;
        self.clientArray=[[NSMutableArray alloc]init];
        self.userArray=[[NSMutableArray alloc]init];
        self.socketQueue = dispatch_queue_create("socketQueue", DISPATCH_QUEUE_SERIAL);
//        self.socketQueue = dispatch_get_main_queue();
        self.listenSocket=[[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:self.socketQueue];
        //接收每包数据
        _socketModel=[[SocketModel alloc]init];
    }
    return self;
}
#pragma mark -  NSNetService 启动和Delegate
-(void)startNetService:(int)port{
    // 创建 bonjour 服务， Bonjour是一个协议.name 为空串表示主机自己的名字
    _netService = [[NSNetService alloc] initWithDomain:@"local."
                                                  type:@"_CellRobot._tcp."
                                                  name:@""
                                                  port:port];
    
    [_netService setDelegate:self];
    [_netService publish];
    // 添加额外信息
    NSMutableDictionary *txtDict = [NSMutableDictionary dictionaryWithCapacity:2];
    [txtDict setObject:@"moo" forKey:@"cow"];
    [txtDict setObject:@"quack" forKey:@"duck"];
    NSData *txtData = [NSNetService dataFromTXTRecordDictionary:txtDict];
    [_netService setTXTRecordData:txtData];
    
}

- (void)stopNetService{
    [_netService stop];
    [_netService stopMonitoring];
    [_netService setDelegate:nil];
    _netService=nil;
}
- (void)netServiceDidPublish:(NSNetService *)sender
{
    [self socketLog:[NSString stringWithFormat:@"Bonjour Service广播: 主机(%@) 类型(%@) name(%@) 端口(%i)",[sender domain], [sender type], [sender name], (int)[sender port]]];
}
-(void)netService:(NSNetService *)sender didNotPublish:(NSDictionary<NSString *,NSNumber *> *)errorDict{
    [self socketLog:[NSString stringWithFormat:@"广播服务失败: domain(%@) type(%@) name(%@) - %@",[sender domain], [sender type], [sender name], errorDict]];
}

#pragma mark -  Socket 实现
//Log
-(void)socketLog:(id)log{
    if (_debugLog) {
        NSLog(@"%@",log);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.socketLogBlock) {
                self.socketLogBlock(log);
            }
        });
    }
}
//启动socket
-(void)startSocket:(NSInteger)port{
    [self startSocket:port openNetServer:NO];
}
-(void)startSocket:(NSInteger)port openNetServer:(BOOL)open{
    _openNetServer=open;
    if (_connected) {return;}
    [self.listenSocket setDelegate:self];
    NSError *error=nil;
    //    [self.listenSocket setIPv4Enabled:YES];
    uint16 uport=(uint16)port;
    
    if(![self.listenSocket acceptOnPort:uport error:&error]){
        [self socketLog:[NSString stringWithFormat:@"启动失败：%@",error]];
    }else{
       
        self.connected=YES;
        NSString *ip = [FanToolBox fan_IPAdress];
        [self socketLog:[NSString stringWithFormat:@"服务器%@启动成功，主机：%@,端口：%hu",ip,self.listenSocket.localHost,self.listenSocket.localPort]];
        
        //广播设备
        if(open){
            [self startNetService:(int)port];
        }
    }
}
-(void)stopSocket{
    //服务器没有断开方法
    if(self.connected){
        
        [self.listenSocket setDelegate:nil];
        [self.listenSocket disconnect];
        [self.clientArray removeAllObjects];
        [self.userArray removeAllObjects];
//        self.listenSocket=nil;
        
        self.connected=NO;
        [self socketLog:@"服务器停止工作！"];
        
    }
    if (_openNetServer) {
        [self stopNetService];
    }
    //停止心跳包
    [self stopHeartPack];

}
-(void)sendToAllMessage:(NSString *)message{
    for (GCDAsyncSocket *socket in self.clientArray) {
        //循环发送所有数据
        [self sendMessage:message socket:socket];
    }
}
-(void)sendMessage:(NSString *)message socket:(GCDAsyncSocket *)socket{
    [self sendMessage:message socket:socket withTimeout:-1 tag:TAG_SEND];
}
-(void)sendMessage:(NSString *)message socket:(GCDAsyncSocket *)socket withTimeout:(NSTimeInterval)timout tag:(long)tag{
    //方法二：对象拼数据包
    NSData *data=[SocketModel getDataWithMessage:message type:0 index:0];
    [socket writeData:data withTimeout:timout tag:tag];
}
-(void)sendFile:(NSData *)data fileType:(SocketType)fileType socket:(GCDAsyncSocket *)socket{
    NSData * sendData=[SocketModel getDataWithType:fileType length:(UInt32)data.length index:0 data:data];
    [socket writeData:sendData withTimeout:-1 tag:TAG_SEND];
}
-(void)sendJson:(NSString *)message socket:(GCDAsyncSocket *)socket{
    NSData *data=[message dataUsingEncoding:NSUTF8StringEncoding];
//    NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    NSData * sendData=[SocketModel getDataWithType:SocketTypeJson length:(UInt32)data.length index:0 data:data];
    [socket writeData:sendData withTimeout:-1 tag:TAG_SEND];
    
}
-(void)sendCommand:(NSString *)message socketType:(UInt16)socketType socket:(GCDAsyncSocket *)socket{
    NSData *data=[FanDataTool fan_hexToBytes:message];
    NSData * sendData=[SocketModel getDataWithType:socketType length:(UInt32)data.length index:0 data:data];
    [socket writeData:sendData withTimeout:-1 tag:TAG_SEND];
    
}
//发送socket命令类型，没有数据长度的
-(void)sendCommandSocketType:(UInt16)socketType socket:(GCDAsyncSocket *)socket{
    NSData * sendData=[SocketModel getDataWithType:socketType length:0 index:0 data:nil];
    [socket writeData:sendData withTimeout:-1 tag:TAG_SEND];
    
}
///该方法弃用，用对象来操作
-(NSData *)getDataWithStruckMessage:(NSString *)message{
    //方法一：结构体封装数据源发送
    const char *str=[message dataUsingEncoding:NSUTF8StringEncoding].bytes;
    SocketStruct *pack;
    pack=(SocketStruct *)malloc(6+strlen(str));
    pack->total=512;
    pack->page=2;
    pack->type=3;
    pack->data=(char*)pack+6;
    strcpy(pack->data, str);
    NSData *data=[NSData dataWithBytes:pack length:6+strlen(str)];
    free(pack);
    return data;
}
#pragma mark - socketDelegate
-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    [self.clientArray addObject:newSocket];
    FanUserModel *model = [[FanUserModel alloc]initWithSocket:newSocket];
    [self.userArray addObject:model];
    
    
    //开启心跳包
//    [self runHeartPackTimer];
    
    
    [self socketLog:[NSString stringWithFormat:@"连接到新主机：%@,端口号%hu",newSocket.connectedHost,newSocket.connectedPort]];
//    [newSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];//读取数据，按照分隔符来读取
    [newSocket readDataToLength:KPacketHeaderLength withTimeout:-1 tag:TAG_HEADER];//按长度分割
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    if(err){
        if(err.code==7){
            //对象是对的，但是内容已经释放
            NSInteger index=[self.clientArray indexOfObject:sock];
            [self.clientArray removeObject:sock];
            FanUserModel *model=self.userArray[index];
            [self socketLog:[NSString stringWithFormat:@"客户端断开连接:%@ 端口:%ld",model.userHost,model.userPort]];
//            [self stopHeartPack];
            [self.userArray removeObjectAtIndex:index];

        }else{
            [self socketLog:err];
        }
       
        
    }else{
        [self socketLog:@"服务器停止并自动断开所有客户端！"];
    }
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    //对象解析数据
    if(tag==TAG_HEADER){
        [_socketModel configWithData:data tag:TAG_HEADER];
        if (_socketModel.length==0) {
            [self analysis:_socketModel];
            [sock readDataToLength:KPacketHeaderLength withTimeout:-1 tag:TAG_HEADER];
        }else{
            [sock readDataToLength:_socketModel.length withTimeout:-1 tag:TAG_BODY];
        }
        [self socketLog:[NSString stringWithFormat:@"接收Head :Type:%ld, length:%ld",_socketModel.type,(long)_socketModel.length]];

    }else if(tag==TAG_BODY){
        [_socketModel configWithData:data tag:TAG_BODY];
        
        [self analysis:_socketModel];
        
        [sock readDataToLength:KPacketHeaderLength withTimeout:-1 tag:TAG_HEADER];
        if (_socketModel.type==0) {
            [self socketLog:[NSString stringWithFormat:@"接收Body:%@",_socketModel.message]];
        }else{
            NSLog(@"接收文件数据包！");
        }
        
        NSLog(@"接收：%@",_socketModel.data);

    }

}
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
   
}


#pragma mark - 发送解析协议
//解析每包数据
-(void)analysis:(SocketModel *)pack{
    switch (pack.type) {
        case SocketTypeTxt:
        {
            //文本，字符串
        }
            break;
        case SocketTypePng:
        {
            //图片
        }
            break;
        case SocketTypeJpg:
        {
            //图片
        }
            break;
        case SocketTypeGif:
        {
            //GIF
        }
            break;
        case SocketTypeMp3:
        {
            //视频
        }
            break;
        case SocketTypeWav:
        {
            //音频
        }
            break;
        case SocketTypeMp4:
        {
            //视频
        }
            break;
        case SocketTypeMov:
        {
            //视频
        }
            break;
        case SocketTypeXml:
        {
            //XML
            [self receiveFile];
        }
            break;
        case SocketTypeHeartBeat:
        {
            //心跳包
            _heartBeatTime=[NSDate timeIntervalSinceReferenceDate];
            if (_clientArray.count>0) {
                [self sendCommandSocketType:SocketTypeHeartBeat socket:_clientArray[0]];
            }
        }
            break;
        case 1000:
        {
            //Data
            [self receiveDataFile];
        }
            break;
            
        default:
            break;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.receiveSocketBlock) {
            self.receiveSocketBlock(pack);
        }
    });
}
-(void)receiveDataFile{
     NSString *path=@"/Users/fanxiangyang/Desktop/Temp/a.data";
    [_socketModel.data writeToFile:path atomically:YES];
}

-(void)receiveFile{
    if (_socketModel.type==SocketTypeXml) {
        NSString *message=[[NSString alloc]initWithData:_socketModel.data encoding:NSUTF8StringEncoding];
        NSLog(@"文件：%@",message);
        [message writeToFile:@"/Users/fanxiangyang/Desktop/Temp/download.xml" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}


#pragma mark - 心跳包处理
//启动心跳包定时器
-(void)runHeartPackTimer{
    [_heartTimer invalidate];
    _heartTimer=nil;
    _heartBeatTime=[NSDate timeIntervalSinceReferenceDate];

    _heartTimer = [NSTimer scheduledTimerWithTimeInterval:50 target:self selector:@selector(runHeartBeat) userInfo:nil repeats:YES];
    [_heartTimer fire];
}
-(void)stopHeartPack{
    [_heartTimer invalidate];
    _heartTimer=nil;
}
//每50秒一个心跳包
-(void)runHeartBeat{
    NSTimeInterval currentTime=[NSDate timeIntervalSinceReferenceDate];
    if (currentTime - _heartBeatTime < 60.0) {
        //        _heartBeatTime=currentTime;
        if (_clientArray.count>0) {
            [self sendCommandSocketType:SocketTypeHeartBeat socket:_clientArray[0]];
        }
    }else{
        //服务器长时间不响应，要断开，重新连接
        //        [self stopSocket];
        NSLog(@"服务器长时间不响应！");
    }
}



@end
