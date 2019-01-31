//
//  FanConfigC.h
//  FanServerSocket
//
//  Created by 向阳凡 on 2019/1/26.
//  Copyright © 2019 向阳凡. All rights reserved.
//

#ifndef FanConfigC_h
#define FanConfigC_h

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <netinet/in.h>
#include <arpa/inet.h>

#include <sys/socket.h>
#include <sys/select.h>//select
#include <sys/time.h>//select
#include <unistd.h>//close
#include <ctype.h>
#include <pthread.h>



#include "FanDataC.h"


/*定义服务器 -- 客户端 消息传送结构体*/
//typedef struct _FanMessage{
//    char type[2];
//    char index[2];
//    char length[4];
//    char *data;
//}FanMessage;
typedef struct _FanMessage{
    int16_t type; //0-4
    int16_t index;//5-8
    int32_t length;//9-12
    int32_t clength;//13-16 当前的字符长度
    char *data;//17-24
}FanMessage;//结构体对齐，所以都是4个字节=24个字节


//定义在FanConfigC
extern int fan_getMessageHead(char *head);
extern int fan_getMessageBody(char *data,int location,int length);


//定义在FanSocketC
extern FanMessage fan_message;
extern char * fan_createMessage(int type,int index,int length,char *data);
extern char * fan_createFanMessage(FanMessage message);



/*全局的队列互斥条件*/
extern pthread_cond_t fan_cond;
extern pthread_cond_t fan_cond_wait;
/*全局的队列互斥锁*/
extern pthread_mutex_t fan_mutex;
//extern pthread_mutex_t fan_mutex_wait;

extern int fan_thread_status;//0=等待 1=执行 -1=清空所有
extern int fan_thread_clean_status;//0=默认  1=清空所有

//开启线程等待  return=-2一定要处理
extern int fan_thread_start_wait(void);
//正常的超时后继续打开下一个信号量 return=-2一定要处理
int fan_thread_start_timedwait(int sec);
//启动线程，启动信号量
extern int fan_thread_start_signal(void);
//启动等待信号量
extern int fan_thread_start_signal_wait(void);
//暂停线程
extern int fan_thread_end_signal(void);
//初始化互斥锁
extern int fan_thread_queue_init(void);
//释放互斥锁信号量
extern int fan_thread_free(void);

//让队列里面全部执行完毕，而不是关闭线程；
extern int fan_thread_clean_queue(void);
//每次关闭清空后，等待1-2秒，要恢复状态，不然线程添加
extern int fan_thread_init_queue(void);
//设置线程的优先级，必须在子线程
extern int fan_thread_setpriority(int priority);









#endif /* FanConfigC_h */
