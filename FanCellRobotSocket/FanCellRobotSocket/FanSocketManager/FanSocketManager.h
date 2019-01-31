//
//  FanSocketManager.h
//  FanServerSocket
//
//  Created by 向阳凡 on 2018/5/12.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GCDAsyncSocket.h"

///分包的大小，字节，每包大小
#define PackSize (30*1024)
#define KPacketHeaderLength 8
typedef NS_ENUM(NSUInteger ,FanReadDataType){
    TAG_HEADER = 10,//消息头部tag
    TAG_BODY = 11,//消息体tag
    TAG_SEND = 12//消息体tag
};


/**
 SocketType通信类型
 
 - SocketTypeTxt: 文本，不是TXT格式文件
 - SocketTypePng: png格式
 - SocketTypeJpg: jpg格式
 - SocketTypeGif: GIF格式
 - SocketTypeMp3: MP3格式
 - SocketTypeWav: WAV格式
 - SocketTypeMp4: MP4格式
 - SocketTypeMov: mov格式
 - SocketTypeXml: XML格式
 - SocketTypeJson: json数据
 - SocketTypeVoiceTxt: 声音文本
 - SocketTypeFaceAnimation: 表情动画
 - SocketTypeJsonFile: json文件
 - SocketTypeHeartBeat: 心跳包
 - SocketTypeCommand: 命令1000+
 */
typedef NS_ENUM(UInt16,SocketType){
    SocketTypeTxt=0,
    SocketTypePng,
    SocketTypeJpg,
    SocketTypeGif,
    SocketTypeMp3,
    SocketTypeWav,
    SocketTypeMp4,
    SocketTypeMov,
    SocketTypeXml,
    SocketTypeJson,
    SocketTypeVoiceTxt,
    SocketTypeFaceAnimation,
    SocketTypeJsonFile,
    
    SocketTypeHeartBeat=995,
    
    SocketTypeCommand=(UInt16)1000
};




#pragma mark - FanSocketManager管理对象
@class SocketModel;
typedef void(^FanSocketLogBlock)(id log);
typedef void(^FanReceiveSocketBlock)(SocketModel *socketModel);

@interface FanSocketManager : NSObject<GCDAsyncSocketDelegate,NSNetServiceDelegate,NSNetServiceBrowserDelegate>

//Socket服务器数据和对象
@property(nonatomic,strong)dispatch_queue_t socketQueue;
@property(nonatomic,strong)GCDAsyncSocket *localSocket;
@property(nonatomic,strong)GCDAsyncSocket *serverSocket;
@property(nonatomic,assign)uint16_t remotePort;//远程端口号
@property(nonatomic,copy)NSString *remoteHost;//远程主机

//发现广播
@property(nonatomic,strong)NSNetService *netService;

@property(nonatomic,strong)NSTimer *heartTimer;//心跳定时器
@property(nonatomic,assign)NSTimeInterval heartBeatTime;//心跳时间戳
@property(nonatomic,assign)NSInteger connectTimes;//重连次数间戳


//外部使用类
@property(nonatomic,assign)BOOL debugLog;//是否开启打印调试
@property(nonatomic,assign)BOOL connected;//是否连接
@property(nonatomic,assign)BOOL openNetServer;//是否打开Bonjour



@property(nonatomic,copy)FanSocketLogBlock socketLogBlock;
@property(nonatomic,copy)FanReceiveSocketBlock receiveSocketBlock;

///每条数据的model对象
@property(nonatomic,strong)SocketModel *socketModel;



+(instancetype)defaultManager;


#pragma mark -  Socket
-(void)startSocketHost:(NSString *)host port:(NSInteger)port;
-(void)startSocketHost:(NSString *)host port:(NSInteger)port openScan:(BOOL)openScan;
-(void)autoStartLocalSocket;//自动登录
-(void)stopSocket;

//发送文本数据
-(void)sendMessage:(NSString *)message;
-(void)sendMessage:(NSString *)message withTimeout:(NSTimeInterval)timout tag:(long)tag;
//发送json数据
-(void)sendJson:(NSString *)message;
-(void)sendJsonDic:(NSDictionary *)jsonDic;
//发送文件
-(void)sendFile:(NSData *)data fileType:(SocketType)fileType;
//发送控制brain命令
-(void)sendCommandSocketType:(UInt16)socketType;//发送socket命令类型，没有数据长度的
-(void)sendCommand:(NSString *)message socketType:(UInt16)socketType;

//原始命令
-(void)sendData:(NSData *)data socketType:(UInt16)socketType;
-(void)sendByte:(Byte *)bytes length:(NSUInteger)length socketType:(UInt16)socketType;
#pragma mark -  NSNetService

-(void)startNetServiceScan;
-(void)stopNetServiceScan;


#pragma mark -  发送队列，延时发送

/** 发送命令的串行队列*/
//@property(nonatomic,strong) dispatch_queue_t sendCommandQueue;
/** 新的队列，用来解决取消线程执行的*/
@property(nonatomic,strong)NSOperationQueue *sendCommandOperationQueue;
@property(nonatomic,strong)NSOperation *currentOperation;


//带延时的发送
-(void)sendCommandToBrain:(NSData *)data socketType:(UInt16)socketType mTime:(float)mTime;




@end


#pragma mark - SocketModel数据包解析对象
@interface SocketModel:NSObject

@property(nonatomic,assign)UInt16 type;//命令类型
@property(nonatomic,assign)UInt16 index;//发送下标
@property(nonatomic,assign)UInt32 length;//大概4GM大小
@property(nonatomic,strong)NSMutableData *data;
//解析出来的字符串数据
@property(nonatomic,assign)UInt16 command;//与brain交互命令编号
@property(nonatomic,copy)NSString *message;//文本信息UTF8编码,json数据，命令数据
@property(nonatomic,strong)NSDictionary *jsonDic;//json数据
@property(nonatomic,assign)NSInteger page;//用来处理分包，分段下载的大文件


-(void)clear;
-(SocketModel *)copyModel;

//初始化解析数据包
///tag=10是head ，tag=11是body
-(void)configWithData:(NSData *)data tag:(NSUInteger)tag;
///发送数据的拼接形式
-(NSData *)getData;
///只发送含一包数据的文本形式
+(NSData *)getDataWithMessage:(NSString *)message type:(UInt16)type index:(UInt16)index;
+(NSData *)getDataWithType:(UInt16)type length:(UInt32)length index:(UInt16)index data:(NSData *)data;


@end
