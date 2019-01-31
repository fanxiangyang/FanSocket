//
//  FanSocketC.h
//  FanServerSocket
//
//  Created by 向阳凡 on 2019/1/25.
//  Copyright © 2019 向阳凡. All rights reserved.
//

#ifndef FanSocketC_h
#define FanSocketC_h

#include <stdio.h>

#include "FanConfigC.h"

//#include <netinet/in.h>
//#include <sys/socket.h>
//#include <arpa/inet.h>
//#include <string.h>
//#include "FanDataC.h"

 ///每包数据大小
#define FAN_PACKSIZE 1024
extern int fan_port;//端口号

//extern pthread_t fan_thread_list[1024];


//底层C语言的套接字
//线程启动和停止
int fan_startThreadSocketServer(int port);
int fan_stopThreadSocketServer(void);

//主线程启动
int * fan_startSocketServer(int *port_id);
int fan_stopSocketServer(void);
//接收客户端消息
void* fan_recvMessage(int *fd);

//解析数据
void fan_analysisMessage(char *recv_msg,int byte_num);
//完整一包数据处理
void fan_getMessage(void);


//不需要队列的处理接收消息
void  fan_recvMessageNow(FanMessage *message);


void fan_test();
void * test1(int *a);
void * test2(FanMessage *message);
#endif /* FanSocketC_h */


