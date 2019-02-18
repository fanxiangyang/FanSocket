//
//  ViewController.m
//  FanCellRobotSocket
//
//  Created by 向阳凡 on 2018/5/9.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import "ViewController.h"
#import "FanSocketManager.h"
#import "FanDataTool.h"
#import "FanUdpSocketManager.h"
#import "FanVideoViewController.h"
#import <VideoToolbox/VideoToolbox.h>
#import "BrainViewController.h"

@interface ViewController ()


@end

@implementation ViewController{
    
}
-(void)test{
    Byte face[]={0xe8,0x03};
    NSData *data =[NSData dataWithBytes:face length:2];

   uint16_t  type =[FanDataTool fan_unpack_int16:data bigEndian:NO];
    NSLog(@"接收Head :Type:%ld",type);
}
- (void)viewDidLoad {
    [super viewDidLoad];
//    [self test];
    // Do any additional setup after loading the view, typically from a nib.
    self.logTextView.layer.borderWidth=1;
    self.logTextView.layer.borderColor=[UIColor orangeColor].CGColor;
    self.logTextView.editable=NO;
    
    self.hostTextField.text=@"192.168.1.193";
    
    [[FanSocketManager defaultManager]setSocketLogBlock:^(id log) {
        [self refreshLog:log];
    }];

    [[FanSocketManager defaultManager]setReceiveSocketBlock:^(SocketModel *socketModel) {
        if (socketModel.type==SocketTypeJpg) {
            self.showImageView.image=[[UIImage alloc]initWithData:socketModel.data];
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
}
-(void)refreshLog:(NSString *)log{
    self.logTextView.text=[self.logTextView.text stringByAppendingFormat:@"%@\n",log ];
    [self.logTextView scrollRangeToVisible:NSMakeRange([self.logTextView.text length], 0)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -  按钮事件
- (IBAction)scanClick:(id)sender {
    [[FanSocketManager defaultManager]startNetServiceScan];
}

- (IBAction)loginClick:(id)sender {
    NSString *host=[self.hostTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *port=[self.portTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [[FanSocketManager defaultManager]startSocketHost:host port:[port integerValue]];
    
//    [[FanUdpSocketManager defaultManager]startUdpSocket];
}

- (IBAction)logoutClick:(id)sender {
    [[FanSocketManager defaultManager]stopSocket];
    [[FanSocketManager defaultManager]stopNetServiceScan];

}
- (IBAction)sendClick:(id)sender {
    NSString *message = self.sendTextField.text;
//    for (int i=0; i<10; i++) {
////        [[FanSocketManager defaultManager]sendMessage:message];
//        [[FanSocketManager defaultManager].localSocket writeData:[NSData dataWithBytes:"1234" length:4] withTimeout:-1 tag:12];
//
//    }
    
    message=@"打开手机方可为的设计费老实交代覅偶尔玩发的开始发了多少叫夸父京东数科两份就的设计费卡兰蒂斯就打开手机方可为的设计费老实交代覅偶尔玩发的开始发了多少叫夸父京东数科两份就的设计费卡兰蒂斯就打开手机方可为的设计费老实交代覅偶尔玩发的开始发了多少叫夸父京东数科两份就的设计费卡兰蒂斯就打开手机方可为的设计费老实交代覅偶尔玩发的开始发了多少叫夸父京东数科两份就的设计费卡兰蒂斯就打开手机方可为的设计费老实交代覅偶尔玩发的开始发了多少叫夸父京东数科两份就的设计费卡兰蒂斯就打开手机方可为的设计费老实交代覅偶尔玩发的开始发了多少叫夸父京东数科两份就的设计费卡兰蒂斯就打开手机方可为的设计费老实交代覅偶尔玩发的开始发了多少叫夸父京东数科两份就的设计费卡兰蒂斯就打开手机方可为的设计费老实交代000000000----123456";
    
    
//    [[FanSocketManager defaultManager]sendMessage:message];
//    [[FanUdpSocketManager defaultManager]sendMessage:message toHost:@"192.168.1.193" port:6001];
    
  
    for (int i=0; i<10; i++) {
        NSString *msg=[NSString stringWithFormat:@"我们%d！",i];
        [[FanSocketManager defaultManager]sendMessage:msg];


//        [[FanSocketManager defaultManager]sendMessage:message];
    }
//    Byte turn[]={0x00,0x00,0x00,0x00};
//
//    [[FanSocketManager defaultManager].localSocket writeData:[NSData dataWithBytes:turn length:4] withTimeout:-1 tag:12];

}
- (IBAction)sendImgClick:(id)sender {
    NSString *bPath=[[NSBundle mainBundle]pathForResource:@"hua" ofType:@"jpg"];
    NSData *data=[NSData dataWithContentsOfFile:bPath];
    [[FanSocketManager defaultManager]sendFile:data fileType:SocketTypeJpg];
//    [[FanUdpSocketManager defaultManager]sendData:data type:UdpSocketTypeJpg toHost:@"192.168.1.193" port:6001];

}

- (IBAction)sendFileClick:(id)sender {
//    NSMutableString *message=[@"测试发送实际间隔！" mutableCopy];
//    for (int j=0; j<20; j++) {
//        [message appendFormat:@"%ld:%@",j,@"这是我们测试发送的数据长度哈哈了吗"];
//    }
//    NSLog(@"11111111");
//    for (int i=0; i<1; i++) {
//        [[FanSocketManager defaultManager]sendMessage:message];
//    }
//    NSLog(@"2222222");
    
    NSString *path=@"/Users/fanxiangyang/Desktop/sizu.xml";
    NSString *bPath=[[NSBundle mainBundle]pathForResource:@"sizu" ofType:@"xml"];
    NSData *data=[NSData dataWithContentsOfFile:bPath];
    [[FanSocketManager defaultManager]sendFile:data fileType:SocketTypeXml];

    
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.editing=NO;
//    BrainViewController *vc=[[BrainViewController alloc]init];
//    [self presentViewController:vc animated:YES completion:^{
//
//    }];
    
}
- (IBAction)openCamerClick:(id)sender {
    FanVideoViewController *vc=[[FanVideoViewController alloc]init];
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}
@end
