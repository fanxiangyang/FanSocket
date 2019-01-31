//
//  FanSocketManager.h
//  FanServerSocket
//
//  Created by 向阳凡 on 2018/5/12.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "FanUserModel.h"

///包的大小，字节，每包大小
#define PackSize (30*1024)
#define KPacketHeaderLength 8

typedef NS_ENUM(NSUInteger ,FanReadDataType){
    TAG_HEADER = 10,//消息头部tag
    TAG_BODY = 11,//消息体tag
    TAG_SEND = 12
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


/**
 数据包发送的结构体，暂时弃用该方法
 */
typedef struct FanSocketStruct {
    ///分页总数，0不分页
    UInt16 total;
    ///当前页，从1开始
    UInt16 page;
    ///数据类型
    UInt16 type;
    ///包含数据
    char * data;
    
}SocketStruct;


#pragma mark - SocketModel数据包解析对象
@interface SocketModel:NSObject

@property(nonatomic,assign)UInt16 type;
@property(nonatomic,assign)UInt16 index;//发送下标
@property(nonatomic,assign)UInt32 length;
@property(nonatomic,strong)NSMutableData *data;
//解析出来的字符串数据
@property(nonatomic,assign)UInt16 command;//命令编号
@property(nonatomic,copy)NSString *message;//文本信息UTF8编码,json数据，命令数据
@property(nonatomic,strong)NSDictionary *jsonDic;//json数据
@property(nonatomic,assign)NSInteger page;//用来处理分包，分段下载的大文件


-(void)clear;


//初始化解析数据包
///tag=10是head ，tag=11是body
-(void)configWithData:(NSData *)data tag:(NSUInteger)tag;
///发送数据的拼接形式
-(NSData *)getData;
///只发送含一包数据的文本形式
+(NSData *)getDataWithMessage:(NSString *)message type:(UInt16)type index:(UInt16)index;
+(NSData *)getDataWithType:(UInt16)type length:(UInt32)length index:(UInt16)index data:(NSData *)data;

@end


#pragma mark - FanSocketManager管理对象

typedef void(^FanSocketLogBlock)(id log);
typedef void(^FanReceiveSocketBlock)(SocketModel *skMocel);

@interface FanSocketManager : NSObject<GCDAsyncSocketDelegate,NSNetServiceDelegate>

//Socket服务器数据和对象
@property(nonatomic,strong)GCDAsyncSocket *listenSocket;

@property(nonatomic,strong)NSNetService *netService;
@property(nonatomic,strong)NSMutableArray *clientArray;
@property(nonatomic,strong)dispatch_queue_t socketQueue;

@property(nonatomic,strong)NSTimer *heartTimer;//心跳定时器
@property(nonatomic,assign)NSTimeInterval heartBeatTime;//心跳时间戳


//外部使用
@property(nonatomic,assign)BOOL debugLog;//是否打印调试信息
@property(nonatomic,assign)BOOL connected;//是否连接
@property(nonatomic,assign)BOOL openNetServer;//是否打开Bonjour





@property(nonatomic,copy)FanSocketLogBlock socketLogBlock;
@property(nonatomic,copy)FanReceiveSocketBlock receiveSocketBlock;



@property(nonatomic,strong)NSMutableArray *userArray;

///每条数据的model对象
@property(nonatomic,strong)SocketModel *socketModel;




+(instancetype)defaultManager;


#pragma mark -  Socket
-(void)startSocket:(NSInteger)port;
-(void)startSocket:(NSInteger)port openNetServer:(BOOL)open;
-(void)stopSocket;

//发送全部客户端
-(void)sendToAllMessage:(NSString *)message;

-(void)sendMessage:(NSString *)message socket:(GCDAsyncSocket *)socket;
-(void)sendJson:(NSString *)message socket:(GCDAsyncSocket *)socket;
-(void)sendCommand:(NSString *)message socketType:(UInt16)socketType socket:(GCDAsyncSocket *)socket;
-(void)sendMessage:(NSString *)message socket:(GCDAsyncSocket *)socket withTimeout:(NSTimeInterval)timout tag:(long)tag;
-(void)sendFile:(NSData *)data fileType:(SocketType)fileType socket:(GCDAsyncSocket *)socket;
//发送socket命令类型，没有数据长度的
-(void)sendCommandSocketType:(UInt16)socketType socket:(GCDAsyncSocket *)socket;
#pragma mark -  NSNetService

-(void)startNetService:(int)port;
- (void)stopNetService;
@end
