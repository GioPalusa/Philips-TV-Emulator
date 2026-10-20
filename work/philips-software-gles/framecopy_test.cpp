// Exercise the actual ARM Subzero framebuffer-copy JIT with guard pages.
#include "Main/FrameBuffer.hpp"
#include "Reactor/Routine.hpp"
#include <sys/mman.h>
#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

static int check(int width, int height, int padding, bool inverted) {
    const int pitch=width*4+padding;
    const size_t bytes=size_t(pitch)*height;
    const size_t rounded=(bytes+4095)&~size_t(4095);
    void *sm=mmap(0,rounded+8192,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    void *dm=mmap(0,rounded+8192,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(sm==MAP_FAILED || dm==MAP_FAILED) return 2;
    mprotect((char*)sm+4096,rounded,PROT_READ|PROT_WRITE);
    mprotect((char*)dm+4096,rounded,PROT_READ|PROT_WRITE);
    uint8_t *src=(uint8_t*)sm+4096+rounded-bytes;
    uint8_t *dst=(uint8_t*)dm+4096+rounded-bytes;
    memset(src,0x5a,bytes); memset(dst,0xcc,bytes);
    for(int y=0;y<height;y++) for(int x=0;x<width;x++)
        ((uint32_t*)(src+y*pitch))[x]=0xff000000u|((y&255)<<16)|((x&255)<<8)|((x+y)&255);
    sw::BlitState state={}; state.width=width;state.height=height;
    state.sourceFormat=state.destFormat=sw::FORMAT_A8B8G8R8;
    state.sourceStride=inverted?-pitch:pitch;state.destStride=pitch;
    printf("FRAMECOPY begin %dx%d pitch=%d inverse=%d\n",width,height,pitch,int(inverted));
    sw::Routine *routine=sw::FrameBuffer::copyRoutine(state);
    auto function=(void(*)(void*,void*,void*))routine->getEntry();
    function(dst,src+(inverted?(height-1)*pitch:0),nullptr);
    for(int y=0;y<height;y++) {
        if(memcmp(dst+y*pitch,src+(inverted?height-y-1:y)*pitch,width*4))return 3;
        for(int p=width*4;p<pitch;p++)if(dst[y*pitch+p]!=0xcc)return 4;
    }
    delete routine;munmap(sm,rounded+8192);munmap(dm,rounded+8192);
    puts("FRAMECOPY PASS");return 0;
}
int main(){setvbuf(stdout,nullptr,_IONBF,0); for(bool inverse:{false,true}){
    int r=check(64,63,16,inverse);if(r)return r;
    r=check(1920,1080,0,inverse);if(r)return r;
}puts("FRAMECOPY ALL PASS");return 0;}
