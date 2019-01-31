//
//  FanSocketC.m
//  FanServerSocket
//
//  Created by 向阳凡 on 2018/5/12.
//  Copyright © 2018年 向阳凡. All rights reserved.
//

#import "FanSocketC.h"
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <string.h>

@implementation FanSocketC

//底层C语言的套接字
-(void)startC{
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));//初始化socket
    server_addr.sin_len = sizeof(struct sockaddr_in);
    server_addr.sin_family = AF_INET;//Address families AF_INET互联网地址簇
    server_addr.sin_port = htons(6000);
    server_addr.sin_addr.s_addr =INADDR_ANY; //inet_addr("127.0.0.1");
    bzero(&(server_addr.sin_zero),8);
    
    //创建socket
    int server_socket = socket(AF_INET, SOCK_STREAM, 0);//SOCK_STREAM 有连接
    if (server_socket == -1) {
        perror("socket error");
        return;
    }
    int reuseOn = 1;
    int status = setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &reuseOn, sizeof(reuseOn));
    
    //绑定socket：将创建的socket绑定到本地的IP地址和端口，此socket是半相关的，只是负责侦听客户端的连接请求，并不能用于和客户端通信
    int bind_result = bind(server_socket, (struct sockaddr *)(&server_addr), sizeof(server_addr));
    if (bind_result == -1) {
        perror("bind error");
        return;
    }
    
    //listen侦听 第一个参数是套接字，第二个参数为等待接受的连接的队列的大小，在connect请求过来的时候,完成三次握手后先将连接放到这个队列中，直到被accept处理。如果这个队列满了，且有新的连接的时候，对方可能会收到出错信息。
    if (listen(server_socket, 5) == -1) {
        perror("listen error");
        return ;
    }
    struct sockaddr_in client_address;
    socklen_t address_len;
    int client_socket = accept(server_socket, (struct sockaddr *)&client_address, &address_len);
    //返回的client_socket为一个全相关的socket，其中包含client的地址和端口信息，通过client_socket可以和客户端进行通信。
    if (client_socket == -1) {
        perror("accept error");
        return ;
    }
    
    char recv_msg[1024];
    char reply_msg[1024];
    
    while (1) {
        bzero(recv_msg, 1024);
        bzero(reply_msg, 1024);
        
        printf("请输入:");
        scanf("%s",reply_msg);
        send(client_socket, reply_msg, 1024, 0);//发送
        //接收数据长度，超过1024要拼包
        long byte_num = recv(client_socket,recv_msg,1024,0);
        
        recv_msg[byte_num] = '\0';
        printf("接收数据:%s\n",recv_msg);
        
    }
    
}

@end
