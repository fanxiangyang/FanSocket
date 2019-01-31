//
//  ViewController.h
//  FanServerSocket
//
//  Created by 向阳凡 on 2018/5/9.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController
- (IBAction)startClick:(id)sender;
- (IBAction)stopClick:(id)sender;
- (IBAction)sendClick:(id)sender;
- (IBAction)cleanLogBtnClick:(id)sender;

@property (weak) IBOutlet NSTextView *logTextView;
@property (weak) IBOutlet NSTextField *sendTextField;
@property (weak) IBOutlet NSTextField *portTextField;
@property (weak) IBOutlet NSImageView *sImageView;
@property (weak) IBOutlet NSTextField *jsonTextField;
@property (weak) IBOutlet NSTextField *typeTextField;
@property (weak) IBOutlet NSTextField *commandTextField;

- (IBAction)sendImgClick:(id)sender;
- (IBAction)sendFileClick:(id)sender;
- (IBAction)jsonButtonClick:(id)sender;
- (IBAction)commandButtonClick:(id)sender;

@end

