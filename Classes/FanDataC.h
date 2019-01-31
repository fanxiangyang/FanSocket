//
//  FanDataC.h
//  FanServerSocket
//
//  Created by 向阳凡 on 2019/1/25.
//  Copyright © 2019 向阳凡. All rights reserved.
//

#ifndef FanDataC_h
#define FanDataC_h

#include <stdio.h>
//#include <stdlib.h>
//#include <string.h>
#include "FanConfigC.h"


#pragma mark - socket字节编码
//判断系统是否是大端还是小端
int fan_isLittleEndian(void);

//整型编码成字节
char * fan_pack_int8(int val);
char * fan_pack_int16(int val,int bigEndian);
char * fan_pack_int32(int val, int bigEndian);
char * fan_pack_float32(float val,int bigEndian);

//字节数组编码成整型
int8_t fan_unpack_int8( char *data);
int16_t fan_unpack_int16( char *data,int bigEndian);
int32_t fan_unpack_int32( char *data,int bigEndian);
float fan_unpack_float32( char *data,int bigEndian);



#endif /* FanDataC_h */
