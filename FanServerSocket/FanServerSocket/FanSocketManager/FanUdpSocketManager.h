//
//  FanUdpSocketManager.h
//  FanServerSocket
//
//  Created by 向阳凡 on 2018/5/21.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"
#import "FanDataTool.h"


/**
 SocketType通信类型
 
 - UdpSocketTypeTxt: 文本，不是TXT格式文件
 - UdpSocketTypePng: png格式
 - UdpSocketTypeJpg: jpg格式
 - UdpSocketTypeGif: GIF格式
 - UdpSocketTypeMp3: MP3格式
 - UdpSocketTypeWav: WAV格式
 - UdpSocketTypeMp4: MP4格式
 - UdpSocketTypeMov: mov格式
 - UdpSocketTypeXml: XML格式
 */
typedef NS_ENUM(UInt16,UdpSocketType){
    UdpSocketTypeTxt=0,
    UdpSocketTypePng,
    UdpSocketTypeJpg,
    UdpSocketTypeGif,
    UdpSocketTypeMp3,
    UdpSocketTypeWav,
    UdpSocketTypeMp4,
    UdpSocketTypeMov,
    UdpSocketTypeXml,
    UdpSocketTypeVideoStream,
    UdpSocketTypeAudioStream,
    
    UdpSocketTypeBroad=666
    
};

#pragma mark - SocketModel数据包解析对象
@interface UdpSocketModel:NSObject

@property(nonatomic,assign)UInt16 type;
@property(nonatomic,assign)UInt16 length;//大概4GM大小(不包含前9个字节)
@property(nonatomic,assign)UInt16 total;//总也数
@property(nonatomic,assign)UInt16 page;//当前页
@property(nonatomic,assign)UInt16 index;//下标
@property(nonatomic,strong)NSMutableData *data;

-(UdpSocketModel *)copyModel;
//解析出来的字符串数据
@property(nonatomic,copy)NSString *message;//文本信息UTF8编码
@property(nonatomic,assign)BOOL isComplete;//一包数据是否完整切拼包完成


-(void)clear;


//初始化解析数据包
-(BOOL)configWithData:(NSData *)data;
///发送数据的拼接形式
-(NSData *)getData;
///只发送含一包数据的文本形式
+(NSData *)getDataWithMessage:(NSString *)message;
+(NSData *)getDataWithType:(UInt16)type length:(UInt16)length data:(NSData *)data;

@end


#pragma mark - FanUdpSocketManager

///每包udp发送大小
#define UdpPackSize (60*1024)

typedef void(^FanReceiveUdpSocketBlock)(NSData *data,NSString *message, UdpSocketType socketType);

@interface FanUdpSocketManager : NSObject<GCDAsyncUdpSocketDelegate>


@property(nonatomic,strong)GCDAsyncUdpSocket *localUdpSocket;


@property(nonatomic,strong)dispatch_queue_t socketQueue;
@property(nonatomic,strong)NSTimer *broadTimer;
@property(nonatomic,copy)FanReceiveUdpSocketBlock receiveUdpSocketBlock;


//外部使用
///每条数据的model对象
@property(nonatomic,strong)UdpSocketModel *socketModel;

+(instancetype)defaultManager;
-(void)startUdpSocket;
-(void)stopUdpSocket;


///启动广播
-(void)startUDPBroad:(NSTimeInterval)timeInterval;
///停止广播
-(void)stopUDPBroad;



-(void)sendMessage:(NSString *)message toHost:(NSString *)host port:(uint16_t)port;
///发送任何数据，支持分包发送
-(void)sendData:(NSData *)data type:(UInt16)type toHost:(NSString *)host port:(uint16_t)port;
-(void)sendByte:(Byte *)bytes length:(NSInteger)length type:(UInt16)type toHost:(NSString *)host port:(uint16_t)port;





@end
