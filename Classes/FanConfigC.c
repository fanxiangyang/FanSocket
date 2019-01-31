//
//  FanConfigC.c
//  FanServerSocket
//
//  Created by 向阳凡 on 2019/1/26.
//  Copyright © 2019 向阳凡. All rights reserved.
//

#include "FanConfigC.h"



int fan_getMessageHead(char *head){
    fan_message.type=fan_unpack_int16(head, 0);
    fan_message.index=fan_unpack_int16(head+2, 0);
    fan_message.length=fan_unpack_int32(head+4, 0);
    if (fan_message.length==0) {
        return 1;
    }else{
        //5144521
//        printf("类型：%d===== 字节：%lld\n",fan_message.type,(long long)fan_message.length);
        
//        free(fan_message.data);
//        fan_message.data=NULL;
        fan_message.data=(char *)malloc(fan_message.length);
    }
    return 0;
}

int fan_getMessageBody(char *data,int location,int length){
//    fan_message.data=realloc(fan_message.data, fan_message.clength+length);

//    printf("追加数据: %d",length);
    memcpy(fan_message.data+fan_message.clength, data+location, length);
    
    fan_message.clength+=length;
    
    if (fan_message.length==fan_message.clength) {
        //完整一包数据啊
        return 1;
    }

    return 0;
}



/*全局的队列互斥条件*/
pthread_cond_t fan_cond=PTHREAD_COND_INITIALIZER;
pthread_cond_t fan_cond_wait=PTHREAD_COND_INITIALIZER;

/*全局的队列互斥锁*/
pthread_mutex_t fan_mutex = PTHREAD_MUTEX_INITIALIZER;
//pthread_mutex_t fan_mutex_wait = PTHREAD_MUTEX_INITIALIZER;
int fan_thread_status=1;//0=等待 1=执行
int fan_thread_clean_status;//0=默认  1=清空所有

//开启线程等待
int fan_thread_start_wait(void){
    pthread_mutex_lock(&fan_mutex);
    fan_thread_clean_status=0;
    while (fan_thread_status==0) {
        pthread_cond_wait(&fan_cond, &fan_mutex);
        if (fan_thread_clean_status==1) {
            break;
        }
    }
    if (fan_thread_clean_status==1) {
        pthread_mutex_unlock(&fan_mutex);
        return -2;
    }
    if (fan_thread_status==1) {
        fan_thread_status=0;
        pthread_mutex_unlock(&fan_mutex);
    }else{
        pthread_mutex_unlock(&fan_mutex);
    }
    return 0;
}
//正常的超时后继续打开下一个信号量
int fan_thread_start_timedwait(int sec){
    int rt=0;
    pthread_mutex_lock(&fan_mutex);
    struct timeval now;
    struct timespec outtime;
    gettimeofday(&now, NULL);
    outtime.tv_sec = now.tv_sec + sec;
    outtime.tv_nsec = now.tv_usec * 1000;
    
    int result = pthread_cond_timedwait(&fan_cond_wait, &fan_mutex, &outtime);
    if (result!=0) {
        //线程等待超时
        rt=-1;
    }
    if (fan_thread_clean_status==1) {
        rt = -2;
    }
    pthread_mutex_unlock(&fan_mutex);
    return rt;
}
//启动线程，启动信号量
int fan_thread_start_signal(void){
    int rs=pthread_mutex_trylock(&fan_mutex);
    if(rs!=0){
        pthread_mutex_unlock(&fan_mutex);
    }
    fan_thread_status=1;
    pthread_cond_signal(&fan_cond);
//    pthread_cond_broadcast(&fan_cond);//全部线程
    pthread_mutex_unlock(&fan_mutex);
    return 0;
}
//开启等待时间的互斥信号量
int fan_thread_start_signal_wait(void){
    int rs=pthread_mutex_trylock(&fan_mutex);
    if(rs!=0){
        pthread_mutex_unlock(&fan_mutex);
    }
//    fan_thread_status=1;
    pthread_cond_signal(&fan_cond_wait);
    //    pthread_cond_broadcast(&fan_cond);//全部线程
    pthread_mutex_unlock(&fan_mutex);
    return 0;
}
//暂停下一个线程
int fan_thread_end_signal(void){
    pthread_mutex_lock(&fan_mutex);
    fan_thread_status=0;
    pthread_cond_signal(&fan_cond);
    pthread_mutex_unlock(&fan_mutex);
    return 0;
}
//初始化互斥锁（动态创建）
int fan_thread_queue_init(void){
    pthread_mutex_init(&fan_mutex, NULL);
    pthread_cond_init(&fan_cond, NULL);
    return 0;
}
//释放互斥锁和信号量
int fan_thread_free(void)
{
    pthread_mutex_destroy(&fan_mutex);
    pthread_cond_destroy(&fan_cond);
    return 0;
}

//清空所有的队列
int fan_thread_clean_queue(void){
    //    int i=0;
    //    for (i=0; i<1024; i++) {
    //        pthread_t pid=fan_thread_list[i];
    //        int kill_ret=pthread_kill(pid, 0);//测试线程是否存在
    //        printf("线程状态：%d\n",kill_ret);
    //        if(kill_ret==0){
    //            //关闭线程
    //            pthread_cancel(pid);
    //            fan_thread_start_signal();
    //        }
    //    }
    pthread_mutex_lock(&fan_mutex);
    fan_thread_clean_status=1;
    pthread_cond_broadcast(&fan_cond);
    pthread_cond_broadcast(&fan_cond_wait);
    pthread_mutex_unlock(&fan_mutex);
    return 0;
}
//恢复队列
int fan_thread_init_queue(void){
    pthread_mutex_lock(&fan_mutex);
    fan_thread_clean_status=0;
    fan_thread_status=1;
    pthread_cond_signal(&fan_cond);
    pthread_mutex_unlock(&fan_mutex);
    return 0;
}
//设置线程的优先级，必须在子线程
int fan_thread_setpriority(int priority){
    struct sched_param sched;
    bzero((void*)&sched, sizeof(sched));
//    const int priority1 = (sched_get_priority_max(SCHED_RR) + sched_get_priority_min(SCHED_RR)) / 2;
    sched.sched_priority=priority;
    //SCHED_OTHER(正常,非实时)SCHED_FIFO(实时，先进先出)SCHED_RR(实时、轮转法)
    pthread_setschedparam(pthread_self(), SCHED_RR, &sched);
    return 0;
}
