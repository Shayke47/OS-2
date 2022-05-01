#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/param.h"
#include "kernel/fs.h"


int castest(int size){
    int i;
    for(i=0; i<size; i++){
        printf("%d\n",fork());
    }
    return 0;
}


int main (int argc, char *argv[]){
    castest(5);
    return 0;
}
