#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static bool fail_alloc;
static unsigned allocations, reads;
static void *g_try_malloc0(size_t size){allocations++;return fail_alloc?NULL:calloc(1,size);}
#define g_free free
#include "philips-ts130.inc"
static uint8_t guest[64];
static bool read_guest(void *opaque,uint32_t pa,void *buffer,size_t length){
    (void)opaque; reads++;if(pa!=0x12340000 || length>sizeof(guest))return false;
    memcpy(buffer,guest,length);return true;
}
static int32_t command(PhilipsTs130State *s,uint32_t cmd,uint32_t pa,uint32_t n){
    int32_t r=-2;assert(philips_ts130_handle(s,cmd,pa,n,read_guest,NULL,&r));return r;
}
static int32_t pid(PhilipsTs130State *s,uint16_t p){guest[0]=p;guest[1]=p>>8;return command(s,0x400f,0x12340000,64);}
int main(void){
    PhilipsTs130State s={0};int32_t r=0x123;unsigned before;
    assert(!philips_ts130_handle(&s,0x400e,0,0,NULL,NULL,&r));assert(r==0x123);
    assert(!philips_ts130_handle(&s,0x4005,0,0,NULL,NULL,&r));assert(!s.initialized);
    assert(pid(&s,1)==10 && reads==0); /* Additional emulator boundary guard. */
    fail_alloc=true;assert(command(&s,0x400d,0,0)==10 && !s.initialized && !s.ring);
    fail_alloc=false;assert(command(&s,0x400d,0,0)==0 && s.initialized && s.ring);
    assert(allocations==2);for(unsigned i=0;i<96;i++){assert(s.pids[i]==0xffff);assert(pid(&s,i+1)==0);}
    assert(s.pid_count==96);assert(pid(&s,100)==10);for(unsigned i=0;i<96;i++)assert(s.pids[i]==i+1);
    assert(pid(&s,0xfff)==0 && s.pid_count==0);for(unsigned i=0;i<96;i++)assert(s.pids[i]==0xffff);
    assert(pid(&s,0xffff)==0 && s.pid_count==1 && s.pids[0]==0xffff);
    s.scratch_read_offset=48;s.scratch_write_offset=80;s.partial_length=39;s.parser_flag=1;guest[0]=0x87;
    assert(command(&s,0x4010,0x12340000,64)==0);assert(!s.scratch_read_offset&&!s.scratch_write_offset&&!s.partial_length&&!s.parser_flag&&s.pid_count==1);
    s.scratch_read_offset=52;s.ring[0]=0x5a;
    assert(command(&s,0x400d,0,0)==0 && allocations==2);assert(s.scratch_read_offset==52 && s.ring[0]==0x5a && !s.pid_count);
    before=reads;assert(command(&s,0x400f,UINT32_MAX,64)==10);assert(command(&s,0x400f,0,64)==10);assert(command(&s,0x400f,0x12340000,1)==10);assert(command(&s,0x400f,0x12340000,65)==10);assert(reads==before);
    assert(command(&s,0x400f,0x12340004,64)==10 && !s.pid_count);
    assert(command(&s,0x400d,1,0)==10 && s.scratch_read_offset==52);
    philips_ts130_reset(&s);assert(!s.initialized&&!s.ring&&!s.pid_count);philips_ts130_reset(&s);
    puts("PASS: TS130 model state matches original ARM oracle scenarios; invalid payload/read/allocation and unsupported commands rejected.");return 0;
}
