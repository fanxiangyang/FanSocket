//
//  ViewController.m
//  FanServerSocket
//
//  Created by 向阳凡 on 2018/5/9.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import "ViewController.h"
#import "FanSocketManager.h"
#import "FanUdpSocketManager.h"
#import <VideoToolbox/VideoToolbox.h>
#import "FanSocketC.h"



@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    

    [[FanSocketManager defaultManager]setSocketLogBlock:^(id log) {
        [self refreshLog:log];
    }];
    [[FanSocketManager defaultManager]setReceiveSocketBlock:^(SocketModel *socketModel) {
        if (socketModel.type==SocketTypeJpg) {
            self.sImageView.image=[[NSImage alloc]initWithData:socketModel.data];
        }else if (socketModel.type ==SocketTypeJson){
            [self refreshLog:[[NSString alloc]initWithData:socketModel.data encoding:NSUTF8StringEncoding]];

            //            NSError *error;
            //            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:socketModel.jsonDic options:NSJSONWritingPrettyPrinted error:&error];
            //            NSString *jsonString=[[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
            //            [self refreshLog:jsonString];
        }else  if (socketModel.type ==SocketTypeCommand){
            [self refreshLog:[NSString stringWithFormat:@"命令：%hu=%@",socketModel.command,socketModel.message]];
        }
    }];

    [[FanUdpSocketManager defaultManager]setReceiveUdpSocketBlock:^(NSData *data, NSString *message, UdpSocketType socketType) {
        if (socketType==UdpSocketTypeJpg) {
            self.sImageView.image=[[NSImage alloc]initWithData:data];
        }
    }];
    
//    FanSocketC *socketC=[[FanSocketC alloc]init];
//    [socketC startC];

//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        if(fan_startSocketServer(9632)){
//            NSLog(@"服务器启动成功！");
//        }
//    });
    
//    NSInteger a=0x1234;
//
//    NSLog(@"0x%@",[FanDataTool fan_pack_int16:a]);
    
    
//    float a=7.25;
//    uint16_t a1=6;
//    NSData *data=[FanDataTool fan_pack_float32:a bigEndian:YES];
//    NSData *data1 = [NSData dataWithBytes:&a length:4];
//    if([FanDataTool fan_isLittleEndian]){
//        NSLog(@"小端的！");
//    }
//    NSLog(@"%@===%@",data,data1);
//
//    float b=[FanDataTool fan_unpack_float32:data bigEndian:YES];
//    NSLog(@"%f",b);
//
//
//    NSData *data2 = [NSData dataWithBytes:&a1 length:4];
//    NSData *data3 = [FanDataTool fan_pack_int32:a1 bigEndian:YES];
//
//    uint32_t bb= [FanDataTool fan_unpack_int32:data3 bigEndian:YES];
//
//    NSLog(@"%ld",bb);
//    NSLog(@"%@===%@",data2,data3);

}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}
#pragma mark -  UI
-(void)refreshLog:(NSString *)log{
    self.logTextView.string=[self.logTextView.string stringByAppendingFormat:@"%@\n",log ];
    [self.logTextView scrollRangeToVisible:NSMakeRange([self.logTextView.string length], 0)];
}

#pragma mark -  按钮事件
- (IBAction)startClick:(id)sender {
    
    //socket TCP
    NSInteger port = [self.portTextField.stringValue integerValue];
    if (port <= 1024) {
        port=9632;
    }
    [[FanSocketManager defaultManager]startSocket:port openNetServer:YES];
    //UDP
//    [[FanUdpSocketManager defaultManager]startUdpSocket];
}

- (IBAction)stopClick:(id)sender {
    [[FanSocketManager defaultManager]stopSocket];
}
- (IBAction)sendClick:(id)sender {
    NSString *message=self.sendTextField.stringValue;
    [[FanSocketManager defaultManager]sendToAllMessage:message];
    
//    NSString *path=@"/Users/fanxiangyang/Desktop/sizu.xml";
//    NSString *str=[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
//    NSMutableString *mStr= [[str stringByAppendingString:str] mutableCopy];
//    [mStr appendString:str];
//    [mStr appendString:str];
//    [mStr appendString:str];
//    [mStr appendString:str];
//    [mStr appendString:str];
//    [mStr appendString:str];
//    [mStr appendString:str];
//
//    [[FanSocketManager defaultManager]sendMessage:str];
    
    
//    [[FanUdpSocketManager defaultManager]sendMessage:message toHost:@"192.168.1.79" port:6001];

}

- (IBAction)cleanLogBtnClick:(id)sender {
    self.logTextView.string=@"";
}



- (IBAction)sendImgClick:(id)sender {
    NSString *bPath=[[NSBundle mainBundle]pathForResource:@"hua" ofType:@"jpg"];
    NSData *data=[NSData dataWithContentsOfFile:bPath];
    if ([FanSocketManager defaultManager].clientArray.count>0) {
        GCDAsyncSocket *sck=[FanSocketManager defaultManager].clientArray[0];
        [[FanSocketManager defaultManager]sendFile:data fileType:SocketTypeJpg socket:sck];
    }
}

- (IBAction)sendFileClick:(id)sender {
//    NSString *bPath=[[NSBundle mainBundle]pathForResource:@"sizu" ofType:@"xml"];
//    NSData *data=[NSData dataWithContentsOfFile:bPath];
//    [[FanSocketManager defaultManager]sendFile:data fileType:SocketTypeXml socket:[FanSocketManager defaultManager].clientArray[0]];
    NSArray *fileTypeArray=@[@"txt",@"png",@"jpg",@"gif",@"mp3",@"wav",@"mp4",@"mov",@"xml"];
    NSOpenPanel *oPanel=[NSOpenPanel openPanel];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setCanChooseFiles:YES];
    [oPanel setDirectoryURL:[NSURL URLWithString:NSHomeDirectory()]];
    if ([oPanel runModal] == NSModalResponseOK) {  //如果用户点OK
        NSString *path=[[[oPanel URLs] objectAtIndex:0] absoluteString];
        NSLog(@"%@", path);
        NSString *extension=[[path pathExtension] lowercaseString];
        if ([fileTypeArray containsObject:extension]) {
            UInt16 type=[fileTypeArray indexOfObject:extension];
            NSData *data=[NSData dataWithContentsOfFile:path];
            if ([FanSocketManager defaultManager].clientArray.count>0) {
                GCDAsyncSocket *sck=[FanSocketManager defaultManager].clientArray[0];
                [[FanSocketManager defaultManager]sendFile:data fileType:type socket:sck];
            }
           
        }else{
//            NSLog(@"文件类型不支持");
            [self refreshLog:@"文件类型不支持,请联系管理员"];
        }
    }
}

- (IBAction)jsonButtonClick:(id)sender {
    NSString *message=self.jsonTextField.stringValue;
    if ([FanSocketManager defaultManager].clientArray.count>0) {
        GCDAsyncSocket *sck=[FanSocketManager defaultManager].clientArray[0];
        [[FanSocketManager defaultManager]sendJson:message socket:sck];
    }
    
//    NSData *data=[message dataUsingEncoding:NSUTF8StringEncoding];
//    NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    
}

- (IBAction)commandButtonClick:(id)sender {
    NSString *type=self.typeTextField.stringValue;
    NSString *message=self.commandTextField.stringValue;
    UInt16 sType=[type intValue];
    if ([FanSocketManager defaultManager].clientArray.count>0) {
        GCDAsyncSocket *sck=[FanSocketManager defaultManager].clientArray[0];
        [[FanSocketManager defaultManager]sendCommand:message socketType:sType socket:sck];
    }
    

}
@end
