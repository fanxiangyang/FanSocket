//
//  ViewController.h
//  FanCellRobotSocket
//
//  Created by 向阳凡 on 2018/5/9.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *hostTextField;
@property (weak, nonatomic) IBOutlet UITextField *portTextField;

- (IBAction)scanClick:(id)sender;
- (IBAction)loginClick:(id)sender;
- (IBAction)logoutClick:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *sendTextField;
- (IBAction)sendClick:(id)sender;
@property (weak, nonatomic) IBOutlet UIImageView *showImageView;
- (IBAction)sendImgClick:(id)sender;
- (IBAction)sendFileClick:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
- (IBAction)openCamerClick:(id)sender;

@end

