# [FanSocket](https://github.com/fanxiangyang/FanSocket) （纯C语言版or+[GCDAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket)）
(一个TCP,UDP,C语言的服务器，Mac版服务器，iOS版客户端)

### 1.介绍文件目录

* `Classes`  原生C语言Socket-Server的TCP项目文件夹
* `FanServerSocketC` Mac版窗口调用 `Classes` C语言程序项目

* `FanServerSocket`Mac版窗口+GCDAsyncSocket(服务器TCP+UDP)
* `FanCellRobotSocket`Mac版窗口+GCDAsyncSocket(客户端TCP+UDP)

### 2.注意事项
* Classes里面有完整的C语言TCP项目，makefile文件可以编译;而且包含了线程队列[简书:Pthread多线程](https://www.jianshu.com/p/6fcd478635e2)


* FanServerSocketC项目只是用窗口调用C语言为了调试和展示用

* FanServerSocket项目和FanCellRobotSocket项目里面不但包含了TCP+UPD，还有音视频的编解码操作
* 里面处理数据解析的FanDataTool和FanToolBox 都是我的另外一个项目[FanKit](https://github.com/fanxiangyang/FanKit)
* FanCellRobotSocket项目里面还有心跳包+断开重新连接的逻辑


### 3 TCP通信协议 
Socket TCP 协议（一般不分包<=20MB）
head+body=8(字节)+value数据
1-2 字节 =  协议类型
3-4 字节 =  index 下标编号保留使用
5-8 字节 =  数据长度
9-- 字节 =  value数据

注意：拼包按照byte字节处理，可以处理10-20MB内容，大了另外走拼包协议

### 4.更新说明
目前demo版还缺好多，而且有些功能都是注释的，比如tcp，upd，最好单独调试，后期会长期更新 

### 5.部分代码
C语言TCP+线程队列，互斥条件等
```
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

```
C语言 TCP 服务器端封装
```
 ///每包数据大小
#define FAN_PACKSIZE 1024
extern int fan_port;//端口号

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

```
GCDAsyncSocket部分封装

```
+(instancetype)defaultManager;
#pragma mark -  Socket
-(void)startSocket:(NSInteger)port;
-(void)startSocket:(NSInteger)port openNetServer:(BOOL)open;
-(void)stopSocket;

//发送全部客户端
-(void)sendToAllMessage:(NSString *)message;

-(void)sendMessage:(NSString *)message socket:(GCDAsyncSocket *)socket;
-(void)sendJson:(NSString *)message socket:(GCDAsyncSocket *)socket;
-(void)sendCommand:(NSString *)message socketType:(UInt16)socketType socket:(GCDAsyncSocket *)socket;
-(void)sendMessage:(NSString *)message socket:(GCDAsyncSocket *)socket withTimeout:(NSTimeInterval)timout tag:(long)tag;
-(void)sendFile:(NSData *)data fileType:(SocketType)fileType socket:(GCDAsyncSocket *)socket;
//发送socket命令类型，没有数据长度的
-(void)sendCommandSocketType:(UInt16)socketType socket:(GCDAsyncSocket *)socket;
#pragma mark -  NSNetService

-(void)startNetService:(int)port;
- (void)stopNetService;
```


Like(喜欢)
==============
#### 有问题请直接在文章下面留言,喜欢就给个Star(小星星)吧！ 
#### Email:fqsyfan@gmail.com
