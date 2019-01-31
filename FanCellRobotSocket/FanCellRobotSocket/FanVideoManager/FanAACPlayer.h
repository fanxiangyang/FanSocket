//
//  FanAACPlayer.h
//  FanVideoEcode
//
//  Created by 向阳凡 on 2018/5/26.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 *1.注意设置kAQBufSize（1024刚好能时时播放）的大小（音频缓冲区），128，程序崩溃，128KB 大概是10秒后听到声音
 *
 *
 */



@interface FanAACPlayer : NSObject

//播放编码后的音频格式AAC  pcm
-(void)fan_playAudioWithData:(NSData*)data length:(ssize_t)length;
//当有数据播放时，中间暂停，如果没有数据，点击会崩溃
-(void)fan_stop;
//停止，并销毁对象，需要重新创建
-(void)fan_audioPause;
-(void)fan_audioStart;


@end
