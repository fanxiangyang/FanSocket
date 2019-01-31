//
//  ViewController.m
//  FanServerSocket
//
//  Created by 向阳凡 on 2018/5/9.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import "ViewController.h"
#import "FanSocketC.h"



@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
//    FanSocketC *socketC=[[FanSocketC alloc]init];
//    [socketC startC];
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
    int port = [self.portTextField.stringValue intValue];
    if (port <= 1024) {
        port=9632;
    }
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        if(fan_startSocketServer((int *)&port)){
//            //NSLog(@"服务器被断开，准备重启！");
//        }
//    });
    fan_startThreadSocketServer(port);
}

- (IBAction)stopClick:(id)sender {
//    [[FanSocketManager defaultManager]stopSocket];
    fan_stopThreadSocketServer();
    
    
}
- (IBAction)sendClick:(id)sender {
    NSString *message=self.sendTextField.stringValue;
//    [[FanSocketManager defaultManager]sendToAllMessage:message];
    
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

    
//    fan_thread_clean_queue();
    
}

- (IBAction)cleanLogBtnClick:(id)sender {
    self.logTextView.string=@"";
//    int rs=pthread_mutex_trylock(&fan_mutex);
//    printf("===============:%d\n",rs);
//    if(rs!=0){
//        pthread_mutex_unlock(&fan_mutex);
//    }
////    pthread_mutex_lock(&fan_mutex);
//    fan_thread_status=1;
//    pthread_cond_signal(&fan_cond);
//    pthread_mutex_unlock(&fan_mutex);
    //开启信号量
//    fan_thread_start_signal_wait();
}



- (IBAction)sendImgClick:(id)sender {
//    fan_thread_init_queue();
//
//    return;
    NSString *bPath=[[NSBundle mainBundle]pathForResource:@"hua" ofType:@"jpg"];
    NSData *data=[NSData dataWithContentsOfFile:bPath];
    
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
            
        }else{
//            NSLog(@"文件类型不支持");
            [self refreshLog:@"文件类型不支持,请联系管理员"];
        }
    }
}

- (IBAction)jsonButtonClick:(id)sender {
    NSString *message=self.jsonTextField.stringValue;
    
    
//    NSData *data=[message dataUsingEncoding:NSUTF8StringEncoding];
//    NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    
}

- (IBAction)commandButtonClick:(id)sender {
    NSString *type=self.typeTextField.stringValue;
    NSString *message=self.commandTextField.stringValue;
    UInt16 sType=[type intValue];
   
    

}
@end
