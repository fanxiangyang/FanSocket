//
//  FanSocketManager.m
//  FanServerSocket
//
//  Created by 向阳凡 on 2018/5/12.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import "FanSocketManager.h"
#import "FanDataTool.h"
#define CR_Port 9632


#pragma mark - FanSocketManager管理对象

@implementation FanSocketManager{
    NSNetServiceBrowser *netServiceBrowser;
    NSNetService *serverService;
    NSMutableArray *serverAddresses;
    NSMutableArray *serverServiceArray;
}


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
        self.socketQueue = dispatch_queue_create("socketQueue", DISPATCH_QUEUE_SERIAL);
        //        self.socketQueue = dispatch_get_main_queue();
        _localSocket=[[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:self.socketQueue];
        //接收每包数据
        _socketModel=[[SocketModel alloc]init];
        
        //DISPATCH_QUEUE_SERIAL串行队列    DISPATCH_QUEUE_CONCURRENT并行
        //        _sendCommandQueue= dispatch_queue_create("sendCommandQueue", DISPATCH_QUEUE_SERIAL);
        
        _sendCommandOperationQueue=[[NSOperationQueue alloc]init];
        _sendCommandOperationQueue.maxConcurrentOperationCount=1;
    }
    return self;
}
#pragma mark -  NSNetService发现 和 NSNetServiceBrowserDelegate

-(void)startNetServiceScan{
    if (_connected) {
        return;
    }
    [netServiceBrowser setDelegate:nil];
    netServiceBrowser = nil;
    
    netServiceBrowser = [[NSNetServiceBrowser alloc] init];
    [netServiceBrowser setDelegate:self];
    [netServiceBrowser searchForServicesOfType:@"_CellRobot._tcp." inDomain:@"local."];
    
    
    serverServiceArray=[[NSMutableArray alloc]init];
    //初始化地址数据IPV4,IPV6
    serverAddresses=nil;
    serverAddresses=[[NSMutableArray alloc]init];
    
    _openNetServer=YES;
    
    [_localSocket setDelegate:self];
    
}
-(void)stopNetServiceScan{
    if(netServiceBrowser){
        [netServiceBrowser stop];
    }
}
-(void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary<NSString *,NSNumber *> *)errorDict{
    //没有搜索
    [self socketLog:errorDict];
}
-(void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing{
    [self socketLog:[NSString stringWithFormat:@"发现Bonjour服务: %@", [service name]]];
    //发现服务连接服务
    if (![serverServiceArray containsObject:service]) {
        [serverServiceArray addObject:service];
    }
    //MARK:目前先发现一个连接一个
    serverService = service;
    [serverService setDelegate:self];
    [serverService resolveWithTimeout:5.0];//数组解析地址超时时长
    
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing{
    [self socketLog:[NSString stringWithFormat:@"Bonjour服务: %@  已关闭！", [service name]]];
    
}
-(void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser{
    NSLog(@"停止搜索！");
}
-(void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *,NSNumber *> *)errorDict{
    //MARK: 这个如果出错，要重新解析，或者重新刷新服务列表
    [self socketLog:@"解析NetService出错!"];
    
}
-(void)netServiceDidResolveAddress:(NSNetService *)sender{
    //获取设备服务的地址
    [serverAddresses removeAllObjects];
    
    [serverAddresses addObjectsFromArray:[sender addresses]];
    
    if([self connectToNextAddress]){
        //连接成功,停止扫描设备
        [self stopNetServiceScan];
    }else{
        
    }
    
}

- (BOOL)connectToNextAddress
{
    BOOL done = NO;
    
    while (!done && ([serverAddresses count] > 0))
    {
        NSData *addr;
        
        //MARK: 这里是IPV4和IPV6的地址数据，循环连接，连接上就跳出，如果服务器确定可以直接写死
        if (YES) // Iterate forwards
        {
            addr = [serverAddresses objectAtIndex:0];
            [serverAddresses removeObjectAtIndex:0];
        }
        else // Iterate backwards
        {
            addr = [serverAddresses lastObject];
            [serverAddresses removeLastObject];
        }
        NSError *err = nil;
        if ([_localSocket connectToAddress:addr error:&err])
        {
            done = YES;
        }
        else
        {
            NSLog(@"不能连接这个地址，尝试连接下一个地址: %@", err);
        }
        
    }
    
    if (!done)
    {
        NSLog(@"不能连接IPV4和IPV6");
    }
    return done;
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
-(void)startSocketHost:(NSString *)host port:(NSInteger)port{
    [self startSocketHost:host port:port openScan:NO];
}
-(void)startSocketHost:(NSString *)host port:(NSInteger)port openScan:(BOOL)openScan{
    if (_connected) {
        return;
    }
    [_localSocket setDelegate:self];
    uint16_t uport = (uint16_t)port;
    NSError *error=nil;
    if(![_localSocket connectToHost:host onPort:uport withTimeout:3 error:&error]){
        [self socketLog:[NSString stringWithFormat:@"连接失败:%@",error]];
        if (openScan) {
            [self startNetServiceScan];
        }
    }
}
-(void)autoStartLocalSocket{
    if (self.connected) {
        [self stopHeartPack];
    }else{
        [self startSocketHost:_remoteHost port:_remotePort openScan:NO];
    }
}
-(void)stopSocket{
    //服务器没有断开方法
    //停止心跳包
    [self stopHeartPack];
    [self.localSocket setDelegate:nil];
    [self.localSocket disconnect];
    self.connected=NO;
    [self socketLog:@"退出登录！"];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        ShowHUDMessage(@"断开与brain了");
//    });
    
}
-(void)sendMessage:(NSString *)message{
    [self sendMessage:message withTimeout:-1 tag:TAG_SEND];
}
-(void)sendMessage:(NSString *)message withTimeout:(NSTimeInterval)timout tag:(long)tag{
    //方法二：对象拼数据包
    NSData *data=[SocketModel getDataWithMessage:message type:0 index:0];
    [self.localSocket writeData:data withTimeout:timout tag:tag];
}
-(void)sendJson:(NSString *)message {
    NSData *data=[message dataUsingEncoding:NSUTF8StringEncoding];
    NSData * sendData=[SocketModel getDataWithType:SocketTypeJson length:(UInt32)data.length index:0 data:data];
    [self.localSocket writeData:sendData withTimeout:-1 tag:TAG_SEND];
}
-(void)sendJsonDic:(NSDictionary *)jsonDic {
    NSError *error;
    NSData *data=[NSJSONSerialization dataWithJSONObject:jsonDic options:NSJSONWritingPrettyPrinted error:&error];
    if (data) {
        NSData * sendData=[SocketModel getDataWithType:SocketTypeJson length:(UInt32)data.length index:0 data:data];
        [self.localSocket writeData:sendData withTimeout:-1 tag:TAG_SEND];
    }else{
        NSLog(@"发送json错误：%@",error);
    }
    
}
-(void)sendCommand:(NSString *)message socketType:(UInt16)socketType{
    NSData *data=[message dataUsingEncoding:NSUTF8StringEncoding];
    NSData * sendData=[SocketModel getDataWithType:socketType length:(UInt32)data.length index:0 data:data];
    [self.localSocket writeData:sendData withTimeout:-1 tag:TAG_SEND];
    
}

//发送socket命令类型，没有数据长度的
-(void)sendCommandSocketType:(UInt16)socketType{
    NSData * sendData=[SocketModel getDataWithType:socketType length:0 index:0 data:nil];
    [self.localSocket writeData:sendData withTimeout:-1 tag:TAG_SEND];
    
}
-(void)sendFile:(NSData *)data fileType:(SocketType)fileType{
    NSData * sendData=[SocketModel getDataWithType:fileType length:(UInt32)data.length index:0 data:data];
    [self.localSocket writeData:sendData withTimeout:-1 tag:TAG_SEND];
}
//发送原始数据
-(void)sendData:(NSData *)data socketType:(UInt16)socketType{
    NSData * sendData=[SocketModel getDataWithType:socketType length:(UInt32)data.length index:0 data:data];
    [self.localSocket writeData:sendData withTimeout:-1 tag:TAG_SEND];
    
}
-(void)sendByte:(Byte *)bytes length:(NSUInteger)length socketType:(UInt16)socketType{
    NSData *data=[NSData dataWithBytes:bytes length:length];
    [self sendData:data socketType:socketType];
}

#pragma mark -  发送队列，延时发送
//带延时的发送
-(void)sendCommandToBrain:(NSData *)data socketType:(UInt16)socketType mTime:(float)mTime{
    if(!self.connected){
//        ShowHUDMessage(@"没有连接Brain，不能发送！");//你还没有连接蓝牙
        return ;
    }
    if(data==nil){
        [self sendCommandSocketType:socketType];
        return;
    }
    if(mTime==-2.0f){
        //        _sendCommandOperationQueue.suspended=NO;
        
        [_sendCommandOperationQueue cancelAllOperations];
        _currentOperation=nil;
        [self sendData:data socketType:socketType];
        //        [NSThread sleepForTimeInterval:0.1];
        return;
    }else if(mTime==-1.0f){
        //        [NSThread sleepForTimeInterval:0.1];
        [self sendData:data socketType:socketType];
        return;
    }
    NSBlockOperation *operationNow = [NSBlockOperation blockOperationWithBlock:^(){
        [self sendData:data socketType:socketType];
        [NSThread sleepForTimeInterval:mTime];
    }];
    if (_currentOperation) {
        [operationNow addDependency:_currentOperation];
    }
    [_sendCommandOperationQueue addOperation:operationNow];
    _currentOperation=nil;
    _currentOperation=operationNow;
}
#pragma mark - socketDelegate

-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    //通过这里判断连接成功
    _serverSocket=sock;
    _remotePort=port;
    _remoteHost=host;
    _connected=YES;
    [self socketLog:[NSString stringWithFormat:@"连接成功, 主机:%@  端口:%hu",host,port]];
    [_serverSocket readDataToLength:KPacketHeaderLength withTimeout:-1 tag:TAG_HEADER];
    //tag标识将要读取的数据是几，他就是几，给发送没有关系
//    dispatch_async(dispatch_get_main_queue(), ^{
//        ShowHUDMessage(@"brain连接成功");
//    });
    [self runHeartPackTimer];
    [sock performBlock:^{
        [sock enableBackgroundingOnSocket];
    }];
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    //code=0 连接失败, code=7远程服务器断开
    [self stopHeartPack];
    _connected=NO;
    //连接断开要重新连接，还是先断开再重新连接，先强制执行下disconnect吗？？？？
    if (err.code==0) {
        [self socketLog:@"连接不到服务器！"];
    }else if (err.code==1) {
        [self socketLog:@"连接不到服务器！"];
    }else if (err.code==3) {
        [self socketLog:@"服务器连接超时！"];
    }else if(err.code==7){
        [self socketLog:@"服务器已断开！"];
    }else if(err.code==8){
        [self socketLog:@"连接主机地址不正确！"];
    }else{
        [self socketLog:err];
    }
//    dispatch_async(dispatch_get_main_queue(), ^{
//        ShowHUDMessage(@"brain连接失败，请重试");
//    });
    
}
//- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock{
//    NSLog(@"11111111");
//}
//- (void)socketDidSecure:(GCDAsyncSocket *)sock{
//    NSLog(@"22222222");
//
//}
//- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
//                 elapsed:(NSTimeInterval)elapsed
//               bytesDone:(NSUInteger)length{
//    return 5;
//}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    //对象解析数据
    if(tag==TAG_HEADER){
        [_socketModel configWithData:data tag:TAG_HEADER];
        //MARK:通过判断头，如果接受的是长度为0，那么就是心跳包
        if (_socketModel.type==995) {
            [self analysis:_socketModel];
            [sock readDataToLength:KPacketHeaderLength withTimeout:-1 tag:TAG_HEADER];
        }else if(_socketModel.length==0){
            [self analysis:_socketModel];
            //判断是否是只有头，没有数据的包，直接读取下一条
            [sock readDataToLength:KPacketHeaderLength withTimeout:-1 tag:TAG_HEADER];
        }else{
            [sock readDataToLength:_socketModel.length withTimeout:-1 tag:TAG_BODY];
        }
        
        [self socketLog:[NSString stringWithFormat:@"接收Head :Type:%ld, length:%ld",(long)_socketModel.type,(long)_socketModel.length]];
    }else if(tag==TAG_BODY){
        [_socketModel configWithData:data tag:TAG_BODY];
        if (_socketModel.type==0) {
            [self socketLog:[NSString stringWithFormat:@"接收Body:%@",_socketModel.message]];
        }else{
            //            NSLog(@"接收文件数据包！");
        }
        [self analysis:_socketModel];
        [sock readDataToLength:KPacketHeaderLength withTimeout:-1 tag:TAG_HEADER];
        
    }
    
}
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"发送成功！");
}

#pragma mark - 发送解析协议
//解析每包数据
-(void)analysis:(SocketModel *)pack{
    NSLog(@"接收数据：%@",pack.data);
    
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
        }
            break;
        case SocketTypeHeartBeat:
        {
            //心跳包
            _heartBeatTime=[NSDate timeIntervalSinceReferenceDate];
            if (_connectTimes==0) {
                
            }else{
                [self runHeartPackTimer];
            }
        }
            break;
            
        default:
            break;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.receiveSocketBlock) {
            self.receiveSocketBlock([pack copyModel]);
        }
    });
}


#pragma mark - 心跳包处理
//启动心跳包定时器
-(void)runHeartPackTimer{
    return;
    _connectTimes=0;
    __weak typeof(self)weakSelf=self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [weakSelf.heartTimer invalidate];
        weakSelf.heartTimer=nil;
        weakSelf.heartBeatTime=[NSDate timeIntervalSinceReferenceDate];
        weakSelf.heartTimer = [NSTimer scheduledTimerWithTimeInterval:50 target:self selector:@selector(runHeartBeat) userInfo:nil repeats:YES];
        //    [_heartTimer fire];
        [[NSRunLoop currentRunLoop] run];
    });
}
-(void)stopHeartPack{
    [_heartTimer invalidate];
    _heartTimer=nil;
}
//每50秒一个心跳包
-(void)runHeartBeat{
    NSTimeInterval currentTime=[NSDate timeIntervalSinceReferenceDate];
    if (currentTime - _heartBeatTime < 60.0) {
        NSLog(@"发送心跳包！%f",currentTime - _heartBeatTime);
        //        _heartBeatTime=currentTime;
        [self sendCommandSocketType:SocketTypeHeartBeat];
    }else{
        //服务器长时间不响应，要断开，重新连接
        NSLog(@"服务器长时间不响应！");
        __weak typeof(self)weakSelf=self;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [weakSelf.heartTimer invalidate];
            weakSelf.heartTimer=nil;
            weakSelf.heartBeatTime=[NSDate timeIntervalSinceReferenceDate];
            weakSelf.heartTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(reConnectHeartBeat) userInfo:nil repeats:YES];
            [weakSelf.heartTimer fire];
            [[NSRunLoop currentRunLoop] run];
        });
    }
}
//重新探测3次心跳包
-(void)reConnectHeartBeat{
    if(_connectTimes<3){
        _connectTimes++;
        NSLog(@"发送重连心跳包！");
        [self sendCommandSocketType:SocketTypeHeartBeat];
    }else{
        [self stopHeartPack];
        _connectTimes=0;
        [self stopSocket];
        
        //真正断开了socket，发送重新连接
        [self autoStartLocalSocket];
        //        dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //            [_heartTimer invalidate];
        //            _heartTimer=nil;
        //            _heartBeatTime=[NSDate timeIntervalSinceReferenceDate];
        //            _heartTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(autoStartLocalSocket) userInfo:nil repeats:YES];
        //            [_heartTimer fire];
        //            [[NSRunLoop currentRunLoop] run];
        //        });
    }
}

@end



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
        }else{
            _command=0;
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
-(SocketModel *)copyModel{
    SocketModel *model=[[SocketModel alloc]init];
    model.type=_type;
    model.index=_index;
    model.length=_length;
    model.data=[_data copy];
    
    model.command=_command;
    model.message=[_message copy];
    model.jsonDic=[_jsonDic copy];
    model.page=_page;
    return model;
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
