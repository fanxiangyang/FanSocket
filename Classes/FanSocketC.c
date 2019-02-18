//
//  FanSocketC.c
//  FanServerSocket
//
//  Created by 向阳凡 on 2019/1/25.
//  Copyright © 2019 向阳凡. All rights reserved.
//

#include "FanSocketC.h"


int fan_isPack=1;//是否是一个完整包 -1=头不全 0=body不全 1=完整包
//服务器描述符(默认<=0)+临时客户端
int server_socket;//服务器socket ID
int client_socket;//只能连接一个的时候，做判断
int client_sockfd[FD_SETSIZE];//客户端数组
int fan_port=9632;//端口号
char fan_buffer_head[8];//处理头不全时缓存头
int fan_buffer_head_length=0;//处理头不全时缓存头长度
//int fan_connected=0;//断开服务器
//FanMessage *fan_message=NULL;
//用来处理每包数据
FanMessage fan_message;
//char *allData;
pthread_t fan_server_pid;//服务器线程编号

//FanMessage *fan_data_list[1024];
//pthread_t fan_thread_list[1024];



int threadIndex=0;
void test(){
//    FanMessage message;
//    message.type=1;
//    message.index=2;
//    message.length=12;
//    printf("结构体长度:%lu\n",sizeof(message));
//    char *msg=&message;
//    printf("%lu\n",msg[4]);
    
//    printf("结构体长度:%lu\n",sizeof(fan_message));
//    char *msg=&fan_message;
//    printf("%lu\n",msg[2]);
//
    
//    fan_thread_queue_init();
}


#pragma mark - 服务器开启和关闭
int fan_startThreadSocketServer(int port){
    //线程并发
    fan_port=port;
//    pthread_create(&fan_server_pid, NULL, (void *)fan_startSocketServer, (void *)&p);
//    if(pthread_join(fan_server_pid, NULL)==0){
//        //socket服务线程执行完成，或停止
//
//    }
    pthread_attr_t attr;
    pthread_attr_init (&attr);
    //线程默认是PTHREAD_CREATE_JOINABLE，需要pthread_join来释放线程的
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    //线程并发
    pthread_create(&fan_server_pid, &attr, (void *)fan_startSocketServer, (void *)&fan_port);
    pthread_attr_destroy (&attr);
    
    return 0;
}
int fan_stopThreadSocketServer(void){
    
    //return=0:调用成功。ESRCH：线程不存在。EINVAL：信号不合法。
    int kill_ret=pthread_kill(fan_server_pid, 0);//测试线程是否存在
    if(kill_ret==0){
        //关闭线程
        pthread_cancel(fan_server_pid);
//        pthread_exit(fan_startSocketServer);
        fan_stopSocketServer();
    }
    
    return 0;
}

//底层C语言的套接字(想加入线程执行，线程调用)
int * fan_startSocketServer(int *port_id){
    int stop_id =-1;
    int *stop=&stop_id;
    
    int port = *port_id;
    fan_port=port;
    
    
    test();
    fan_stopSocketServer();
    
    
    client_socket=-1;
    server_socket=-1;
    /*声明服务器地址和客户链接地址*/
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));//初始化socket
    server_addr.sin_len = sizeof(struct sockaddr_in);
    server_addr.sin_family = AF_INET;//Address families AF_INET互联网地址簇
    server_addr.sin_port = htons(port);
    //表明可接受任意IP地址
    server_addr.sin_addr.s_addr =INADDR_ANY; //inet_addr("127.0.0.1");
    bzero(&(server_addr.sin_zero),8);
    /*(2) 设置服务器sockaddr_in结构*/
    //    bzero(&server_addr , sizeof(server_addr));

    ///*(1) 初始化监听套接字listenfd -1错误*/
    server_socket = socket(AF_INET, SOCK_STREAM, 0);//SOCK_STREAM 有连接
    if (server_socket < 0) {
        perror("socket error");
        return stop;
    }

    /*套接字选项*/
    int reuseOn = 1;
    /*(3) 绑定套接字和端口（每次启动，允许程序程序绑定同一个端口）*/
    setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &reuseOn, sizeof(reuseOn));
    
    
    //设置超时
    int nNetTimeout=5;//1秒
    //发送时限
//    setsockopt(server_socket,SOL_SOCKET,SO_SNDTIMEO,(char *)&nNetTimeout,sizeof(int));
    setsockopt(server_socket, SOL_SOCKET, SO_RCVTIMEO, &nNetTimeout, sizeof(nNetTimeout));


    //绑定socket：将创建的socket绑定到本地的IP地址和端口，此socket是半相关的，只是负责侦听客户端的连接请求，并不能用于和客户端通信
    int bind_result = bind(server_socket, (struct sockaddr *)(&server_addr), sizeof(server_addr));
    if (bind_result < 0) {
        perror("bind error");
        return stop;
    }

    //4.listen侦听 第一个参数是套接字，第二个参数为等待接受的连接的队列的大小，在connect请求过来的时候,完成三次握手后先将连接放到这个队列中，直到被accept处理。如果这个队列满了，且有新的连接的时候，对方可能会收到出错信息。
    if (listen(server_socket, 5) < 0) {//==-1
        perror("listen error");
        return stop;
    }
    
    
    /*(5) 首先初始化客户端描述符集*/
    int i = 0;
    for(i=0; i<FD_SETSIZE; ++i)
    {
        client_sockfd[i] = -1;
    }//for
    /*(6) 接收客户链接*/
    while(1)
    {
        struct sockaddr_in client_address;
        socklen_t client_len=sizeof(client_address);
        /*接收客户端的请求*/
         //返回的client_socket为一个全相关的socket，其中包含client的地址和端口信息，通过client_socket可以和客户端进行通信。
        int clint_skt;
        if((clint_skt = accept(server_socket , (struct sockaddr *)&client_address , &client_len)) < 0)
        {
            perror("accept error.\n");
            return stop;
        }//if
        
        
      
        if (client_socket>0) {
            printf("accept more than 1 \n");
            char msg[]="brain已经被别人连接！";
            char *message = fan_createMessage(0, 0, (int)strlen(msg), msg);
            send(clint_skt , message , strlen(msg)+8 , 0);
            close(clint_skt);
            continue;
        
        }
        
        client_socket=clint_skt;
        
        printf("连接到客户端【%d】: %s:%d\n",client_socket,inet_ntoa(client_address.sin_addr),client_address.sin_port);

        /*查找空闲位置，设置客户链接描述符*/
        for(i=0; i<FD_SETSIZE; ++i)
        {
            if(client_sockfd[i] < 0)
            {
                client_sockfd[i] = client_socket; /*将处理该客户端的链接套接字设置在该位置*/
                break;
            }
        }
        
        //连接数超过1024
        if(i == FD_SETSIZE)
        {
            perror("连接超过最大数量\n");
            return stop;
        }//if
        
    
        pthread_t pid;
        if(pthread_create(&pid , NULL , (void *)fan_recvMessage, (void *)&client_socket)==-1){
            printf("创建线程失败");
            char msg[]="客户端接收线程失败，请重新连接！";
            char *message = fan_createMessage(0, 0, (int)strlen(msg), msg);
            send(clint_skt , message , strlen(msg)+8 , 0);
            close(clint_skt);
        }
        
    }//while
//    close(server_socket);
    return stop;
}
int fan_stopSocketServer(){
    if (server_socket>=0) {
        int i = 0;
        for(i=0; i<FD_SETSIZE; ++i)
        {
            if(client_sockfd[i]>=0){
                close(client_sockfd[i]);
                client_sockfd[i]=-1;
            }
        }//for
        close(server_socket);
    }
    server_socket=-1;
    client_socket=-1;
    fan_isPack=1;
    fan_buffer_head_length=0;
    memset(fan_buffer_head, 0, 8);//初始化socket
    return 1;
}
#pragma mark - 接收客户端信息，处理业务逻辑

/*处理客户请求的线程*/
void* fan_recvMessage(int *fd)
{
    int sockfd = *fd;//客户端描述符
    /*声明消息变量*/
//    Message message;
//    memset(&message , 0 , sizeof(message));
    while(1)
    {
        /*声明消息缓冲区*/
        char recv_msg[FAN_PACKSIZE];
        
        //    memset(recv_msg , 0 , 1024);
        bzero(recv_msg, FAN_PACKSIZE);
        
//        printf("客户端【%d】开始接收数据\n",sockfd);
        
        //接收用户发送的消息
        long byte_num  = recv(sockfd , recv_msg , sizeof(recv_msg), 0);
//        printf("接收长度:%ld\n",byte_num);
        if(byte_num <= 0)
        {
            //关闭当前描述符，并清空描述符数组
            fflush(stdout);
            close(sockfd);
            *fd = -1;
            printf("客户端【%d】退出\n",sockfd);
            
            //        printf("来自%s的退出请求！\n", inet_ntoa(message.sendAddr.sin_addr));
            return NULL;
        }else{
//            char *msg=(char *)malloc(FAN_PACKSIZE);
//            char msg[FAN_PACKSIZE];
//            bzero(msg, FAN_PACKSIZE);
//            memcpy(msg, recv_msg, FAN_PACKSIZE);
//            fan_analysisMessage(msg,(int)byte_num);
//
            
            fan_analysisMessage(recv_msg,(int)byte_num);

//            recv_msg[byte_num] = '\0';
//            char head[8];
//            memcpy(head, recv_msg, 8);
//            printf("接收二Head:%s\n",head);
//            printf("接收Body:%s\n",recv_msg+8);
            
        }//else
        
    }
    return NULL;
}

void fan_analysisMessage(char *recv_msg,int byte_num){
//    printf("||||||||:%s\n",recv_msg+8);
    if (fan_isPack==-1) {
        int current_length=8-fan_buffer_head_length;
        if (byte_num>=current_length) {
            memcpy(fan_buffer_head+fan_buffer_head_length, recv_msg, current_length);
            fan_getMessageHead(fan_buffer_head);
            memset(fan_buffer_head, 0, 8);
            fan_buffer_head_length=0;
            if (fan_message.length==byte_num-current_length) {
                //有body数据
                if(byte_num>current_length){
                    fan_getMessageBody(recv_msg+current_length, 0,byte_num-current_length);
                }
                //完整包
                fan_isPack=1;
                fan_getMessage();
                
            }else if(fan_message.length<byte_num-current_length){
                //超过一个完整包
                fan_getMessageBody(recv_msg+current_length, 0,fan_message.length);
                //完整包
                int l=fan_message.length;
                fan_isPack=1;
                fan_getMessage();
                //递归循环
                fan_analysisMessage(recv_msg+current_length+l, byte_num-current_length-l);
                
            }else if(fan_message.length>byte_num-current_length){
                fan_isPack=0;
                //不够一包
                fan_getMessageBody(recv_msg+current_length, 0,byte_num-current_length);
            }
        }else{
            memcpy(fan_buffer_head+fan_buffer_head_length, recv_msg, byte_num);
            fan_buffer_head_length+=byte_num;
        }
        
        
        
    }else if (fan_isPack==1) {
        if (byte_num>=8) {
            char head[8];
            memcpy(head, recv_msg, 8);
            fan_getMessageHead(head);
            if (fan_message.length==byte_num-8) {
                 if(byte_num>8){
                     fan_getMessageBody(recv_msg+8, 0,byte_num-8);
                 }
                //完整包
                
                fan_isPack=1;
                fan_getMessage();
                

            }else if(fan_message.length<byte_num-8){
                //超过一个完整包
                fan_getMessageBody(recv_msg+8, 0,fan_message.length);
                //完整包
                int l=fan_message.length;
                fan_isPack=1;
                fan_getMessage();
                //递归循环
                fan_analysisMessage(recv_msg+8+l, byte_num-8-l);
                
            }else if(fan_message.length>byte_num-8){
                fan_isPack=0;
                //不够一包
                fan_getMessageBody(recv_msg+8, 0,byte_num-8);
            }
        }else {
            //数据包错误(如果出现这个错误，我就要弄一个全局的存起来)
//            printf("---------数据包头不完整----------\n");
//            exit(-1);
            memset(fan_buffer_head, 0, 8);
            memcpy(fan_buffer_head, recv_msg, byte_num);
            fan_buffer_head_length=byte_num;
            fan_isPack=-1;
        }
    }else{
        int st=fan_message.length-fan_message.clength;
        if (st==byte_num) {
            //刚好一包
            fan_getMessageBody(recv_msg, 0,1);
            //完整包
            fan_isPack=1;
            fan_getMessage();
            
        }else if(st>byte_num){
            //不够一包
            fan_getMessageBody(recv_msg, 0,byte_num);
        }else if(st<byte_num){
            //多了一包
            fan_getMessageBody(recv_msg, 0,st);
            //完整包
            fan_isPack=1;
            fan_getMessage();
            
            //递归循环
            fan_analysisMessage(recv_msg+st, byte_num-st);
        }
    }
    
//    free(recv_msg);
}



void fan_getMessage(void){
    FanMessage *message=(FanMessage *)malloc(sizeof(FanMessage));
    memset(message, 0, sizeof(FanMessage));
    message->type=fan_message.type;
    message->index=fan_message.index;
    message->length=fan_message.length;
    message->clength=fan_message.clength;
    message->data=(char *)malloc(message->length);
    memset(message->data, 0, sizeof(message->length));
    memcpy(message->data, fan_message.data, message->length);
    free(fan_message.data);
    fan_message.data=NULL;
    memset(&fan_message, 0, sizeof(fan_message));
    fan_isPack=1;
    //发送一包给线程队列
    
    message->data[message->length]='\0';
    printf("Head:%d,length=%d\n",message->type,message->length);
    printf("Body:%s\n",message->data);
    
    if (message->type<1000) {
        //直接执行，跳转另外一个函数执行
        fan_recvMessageNow(message);
    }
    

    //线程
    pthread_t pid;
    threadIndex++;

//    int a=threadIndex;
    
    
//    pthread_create(&pid1, NULL, (void *)test1, (void *)&a);

    //设置线程属性
    pthread_attr_t attr;
    pthread_attr_init (&attr);
    //线程默认是PTHREAD_CREATE_JOINABLE，需要pthread_join来释放线程的
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    //线程并发
    int rc=pthread_create(&pid, &attr, (void *)test2, (void *)message);
    pthread_attr_destroy (&attr);
    if (rc!=0) {
        //创建线程失败
        printf("创建线程失败\n");
        return;
    }
    
  
//    fan_thread_list[threadIndex-1]=pid;
 
    //return=0:线程存活。ESRCH：线程不存在。EINVAL：信号不合法。
//    int kill_ret=pthread_kill(pid, 0);//测试线程是否存在
//    printf("线程状态：%d\n",kill_ret);
//    if(kill_ret==0){
//        //关闭线程
//        pthread_cancel(pid);
//        fan_thread_start_signal();
//    }
    
    
    //线程退出或返回时，才执行回调，可以释放线程资源（有串行的作用）
//    if(pthread_join(pid, NULL)==0){
//        //线程执行完成
//        printf("线程执行完成：%d\n",threadIndex);
//        if (message!=NULL) {
//            printf("线程执行完成了\n");
//        }
//    }

    
//    fan_test();
}
int fan_index[10];
void fan_test(){
    int i=0;
    for (i=0; i<20; i++) {
        fan_index[i]=i;
        pthread_t pid;
        pthread_attr_t attr;
        pthread_attr_init (&attr);
        //线程默认是PTHREAD_CREATE_JOINABLE，需要pthread_join来释放线程的
        pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
        //线程并发
        int rc=pthread_create(&pid, &attr, (void *)test1, (void *)(fan_index+i));
        pthread_attr_destroy (&attr);
        if (rc!=0) {
            //创建线程失败
            printf("创建线程失败\n");
            return;
        }
        
    }
   
    
    
}
void * test1(int  *a){
    int i=*a;
    //改变线程优先级
    fan_thread_setpriority(i);
    printf("-------:%d\n",*a);
    return NULL;
}
void * test2(FanMessage *message){
    //先执行代码发送逻辑，与下位机通信，收到回复后，打开信号量，执行下一包
//    sleep(2);
    //改变线程优先级
//    fan_thread_setpriority(threadIndex);
//    printf("线程接收数据:%s\n",message->data);

    
    
    printf("线程等待队列:%s\n",message->data);
    if(fan_thread_start_wait()==-2){
        //清空所有
        return NULL;
    }

    printf("发送给下位机:%s\n",message->data);

    //等待3秒后，重新开启下一个
    if(fan_thread_start_timedwait(3)==-2){
        //清空所有
        return NULL;
    }
    fan_thread_start_signal();


    printf("等待3秒后或者下位机返回数据了发送下一条\n");

    //线程停止时会自动释放资源，不需要手动处理
    free(message->data);
    free(message);
    message=NULL;
    
    return NULL;
}


void  fan_recvMessageNow(FanMessage *message){
    //直接处理这个结果
    
    
//    free(message->data);
//    free(message);
//    message=NULL;
}


#pragma makr - 创建发送消息

char * fan_createMessage(int type,int index,int length,char *data){
    char *msg=(char *)malloc(8+length);
    char *typeP=fan_pack_int16(type, 0);
    memcpy(msg, typeP, 2);
    char *indexP=fan_pack_int16(index, 0);
    memcpy(msg+2, indexP, 2);
    char *lengthP=fan_pack_int16(length, 0);
    memcpy(msg+4, lengthP, 4);
    memcpy(msg+8, data, length);
    free(typeP);
    free(indexP);
    free(lengthP);
//    free(data);
    typeP=NULL;
    indexP=NULL;
    lengthP=NULL;
    data=NULL;
    return msg;
}
char * fan_createFanMessage(FanMessage message){
    char *msg=(char *)malloc(8+message.length);
    char *typeP=fan_pack_int16(message.type, 0);
    memcpy(msg, typeP, 2);
    char *indexP=fan_pack_int16(message.index, 0);
    memcpy(msg+2, indexP, 2);
    char *lengthP=fan_pack_int16(message.length, 0);
    memcpy(msg+4, lengthP, 4);
    memcpy(msg+8, message.data, message.length);
    free(typeP);
    free(indexP);
    free(lengthP);
    free(message.data);
    typeP=NULL;
    indexP=NULL;
    lengthP=NULL;
    message.data=NULL;
    return msg;
}
