MYNAME = makefile
CC = gcc
objects = FanConfigC.o FanDataC.o FanSocketC.o Main.o
server: $(objects)
	cc -g -o server $(objects) -lpthread




#比较稳健的clean做法，表示clean是一个伪目标(make clean)
.PHONY: clean

#前面-的意思是：也许某些文件出现问题，忽略，继续执行
clean:
	-rm server $(objects) 
