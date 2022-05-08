#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/param.h"
#include "kernel/fs.h"


int castest(int size){
    int i;
    int pid = 0;
    for(i=0; i<size; i++){
        // printf("%d\n",fork());
        pid  += fork();
    }
    if(pid==0){
        for(int i=0; i<4; i++){
            fprintf(1, "number of pros in cpu: %d is: %d\n", i, cpu_process_count(i));
        }
    }
    else{
        for(int i=0;i<100000000;i++){
            continue;
        }
    }
    return 0;
}


int main (int argc, char *argv[]){
    castest(5);
    // for(int i=0; i<4; i++){
    //         fprintf(1, "number of pros in cpu: %d is: %d\n", i, cpu_process_count(i));
    // }
    exit(0);
}
