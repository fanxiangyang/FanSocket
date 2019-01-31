#include <stdio.h>
#include "FanSocketC.h"

int main(void){
    int32_t a=100;
    printf("Hello Word\n");
    int port = 9632;
    fan_startSocketServer(&port);

    return 0;
}