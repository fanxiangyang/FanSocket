//
//  FanOpenGLView.h
//  FanVideoEcode
//
//  Created by 向阳凡 on 2018/5/25.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
//本例子采用OpenGL2.0版本

@interface FanOpenGLView : UIView

- (void)fan_setupGL;//初始化设置
- (void)fan_displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;//解码每一帧信息


@end
