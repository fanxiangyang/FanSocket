//
//  FanVideoViewController.m
//  FanCellRobotSocket
//
//  Created by 向阳凡 on 2018/5/24.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import "FanVideoViewController.h"
#import "FanMediaManager.h"

@interface FanVideoViewController ()

@property (nonatomic, strong) UIView *videoView;
@property (nonatomic, strong) FanMediaManager *mediaManager;

@end

@implementation FanVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self configUI];
    _mediaManager=[[FanMediaManager alloc]init];
    _mediaManager.isOpenAudio=YES;

}
-(void)configUI{
    _videoView=[[UIView alloc]initWithFrame:self.view.bounds];
    _videoView.backgroundColor=[UIColor whiteColor];
    _videoView.clipsToBounds=YES;
    _videoView.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_videoView];
    
    [self.view sendSubviewToBack:_videoView];
    
    UIButton  *backButton=[UIButton buttonWithType:UIButtonTypeSystem];
    backButton.frame=CGRectMake(10, 20, 60, 30);
    [backButton setTitle:@"返回" forState:UIControlStateNormal];

    [backButton addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    
    UIButton  *startButton=[UIButton buttonWithType:UIButtonTypeSystem];
    startButton.frame=CGRectMake(20, 60, 100, 30);
    [startButton setTitle:@"启动相机" forState:UIControlStateNormal];
    [startButton addTarget:self action:@selector(startClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startButton];
    
    UIButton  *stopButton=[UIButton buttonWithType:UIButtonTypeSystem];
    stopButton.frame=CGRectMake(150, 60, 100, 30);
    [stopButton setTitle:@"停止" forState:UIControlStateNormal];
    [stopButton addTarget:self action:@selector(stopClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stopButton];
}

-(void)backClick{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}
-(void)startClick{
    if([_mediaManager openCaptureWithShowView:_videoView]){
        //打开相机
        
    }
}
-(void)stopClick{
    [_mediaManager stopVideo];
}


//处理视频方向的
-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    //    NSLog(@"12345");
    if (_mediaManager.captureVideoPreviewLayer) {
        _mediaManager.captureVideoPreviewLayer.frame=self.view.frame;
        //解决视频旋转问题
        _mediaManager.captureVideoPreviewLayer.connection.videoOrientation=[_mediaManager videoOrientationFromCurrentDeviceOrientation];
    }
    
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
