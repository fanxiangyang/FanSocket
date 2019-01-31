//
//  FanDataC.c
//  FanServerSocket
//
//  Created by 向阳凡 on 2019/1/25.
//  Copyright © 2019 向阳凡. All rights reserved.
//

#include "FanDataC.h"


#pragma mark - socket字节编码
//判断系统是否是大端还是小端
int fan_isLittleEndian(void)
{
    int32_t i = 1;
    char* b = (char*)&i;
    return b[0] == 1;
}

char * fan_pack_int8(int val)
{
    char *myByteArray=(char *)malloc(1);
    memset(myByteArray,0,1);
    myByteArray[0]=val & 0xff;
    return myByteArray;
}

char * fan_pack_int16(int val,int bigEndian)
{
    char *myByteArray=(char *)malloc(2);
    memset(myByteArray,0,2);
    if(bigEndian)
    {
        myByteArray[1]=val & 0xff;
        myByteArray[0]=(val>>8) & 0xff;
    }else{
        myByteArray[0]=val & 0xff;
        myByteArray[1]=(val>>8) & 0xff;
    }
    
    return myByteArray;
}

char * fan_pack_int32(int val, int bigEndian)
{
    char *myByteArray=(char *)malloc(4);
    memset(myByteArray,0,4);
    if(bigEndian)
    {
        myByteArray[3]=val & 0xff;
        myByteArray[2]=(val>>8) & 0xff;
        myByteArray[1]=(val>>16) & 0xff;
        myByteArray[0]=(val>>24) & 0xff;
    }else{
        myByteArray[0]=val & 0xff;
        myByteArray[1]=(val>>8) & 0xff;
        myByteArray[2]=(val>>16) & 0xff;
        myByteArray[3]=(val>>24) & 0xff;
    }
    return myByteArray;
}

char * fan_pack_float32(float val,int bigEndian)
{
    float valf=val;
    char *myByteArray=(char *)malloc(4);
    memset(myByteArray,0,4);
    char *temp=(char *)(&valf);
    if(bigEndian)
    {
        myByteArray[3]=temp[0];
        myByteArray[2]=temp[1];
        myByteArray[1]=temp[2];
        myByteArray[0]=temp[3];
    }else{
        myByteArray[3]=temp[3];
        myByteArray[2]=temp[2];
        myByteArray[1]=temp[1];
        myByteArray[0]=temp[0];
    }
    return myByteArray;
}



int8_t fan_unpack_int8(char *data)
{
    char *by=(char *)malloc(1);
    memcpy(by, data, 1);
    int8_t ret=by[0] & 0xff;
    free(by);
    return ret;
}
int16_t fan_unpack_int16(char *data,int bigEndian)
{
    char *by=(char *)malloc(2);
    memcpy(by, data, 2);
    int16_t ret=ret=((by[1] & 0xFF) << 8) + (by[0] & 0xff);
    if (bigEndian) {
        ret=((by[0] & 0xFF) << 8) + (by[1] & 0xff);
    }
    free(by);
    return ret;
}
int32_t fan_unpack_int32(char *data,int bigEndian)
{
    char *by=(char *)malloc(4);
    memcpy(by, data, 4);
    int32_t ret=(by[3] << 24) + ((by[2] & 0xFF) << 16) + ((by[1] & 0xFF) << 8) + (by[0] & 0xFF);
    if (bigEndian) {
        ret = ((by[0] & 0xFF) << 24) + ((by[1] & 0xFF) << 16) + ((by[2] & 0xFF) << 8) + (by[3] & 0xff);
    }
    free(by);
    return ret;
}
float fan_unpack_float32(char *data,int bigEndian)
{
    char *by=(char *)malloc(4);
    memcpy(by, data, 4);
    float valf=0.0;
   char *temp=(char *)(&valf);
    if(bigEndian)
    {
        temp[3]=by[0];
        temp[2]=by[1];
        temp[1]=by[2];
        temp[0]=by[3];
    }else{
        temp[3]=by[3];
        temp[2]=by[2];
        temp[1]=by[1];
        temp[0]=by[0];
    }
    free(by);
    return valf;
}


