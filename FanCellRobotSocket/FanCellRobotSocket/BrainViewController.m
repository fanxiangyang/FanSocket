//
//  BrainViewController.m
//  FanCellRobotSocket
//
//  Created by 向阳凡 on 2018/9/3.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import "BrainViewController.h"
#import "FanSocketManager.h"

@interface BrainViewController ()

@end

@implementation BrainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor=[UIColor whiteColor];
    NSArray *arr=@[@"亮灯",@"旋转",@"伺服",@"返回"];
    for (int i=0; i<4; i++) {
        UIButton *btn=[UIButton buttonWithType:UIButtonTypeSystem];
        [btn setFrame:CGRectMake(20+i*(20+100),100, 100, 30)];
        btn.backgroundColor=[UIColor darkGrayColor];
        [btn setTitle:arr[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal];
        btn.tag=100+i;
        [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
}
-(void)btnClick:(UIButton *)btn{
    switch (btn.tag-100) {
        case 0:
        {
            [[FanSocketManager defaultManager]sendCommandSocketType:1000];
        }
            break;
        case 1:
        {
            [[FanSocketManager defaultManager]sendCommandSocketType:1006];
        }
            break;
        case 2:
        {
            
        }
            break;
        case 3:
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
            break;
        default:
            break;
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
