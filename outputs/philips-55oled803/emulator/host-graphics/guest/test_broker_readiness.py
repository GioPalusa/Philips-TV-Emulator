#!/usr/bin/env python3
"""Compile actual broker helpers with only MMIO/send/close replaced by test I/O.

The Android main/initialization is not compiled. Reply scheduling and buffering
are compiled directly from hostgpu_broker.c, including legacy fallback.
"""
from pathlib import Path
import argparse, subprocess, tempfile
p=argparse.ArgumentParser();p.add_argument('--output',type=Path);a=p.parse_args()
source=Path(__file__).with_name('hostgpu_broker.c').read_text().split('int main(',1)[0]
source=source.replace('static int command(', 'static int unused_mmio_command(',1)
source=source.replace('close(c->fd)','test_close(c->fd)').replace('ssize_t n=send(', 'ssize_t n=test_send(')
prelude='''#include <stdint.h>
#include <stddef.h>
#include <sys/types.h>
#include <assert.h>
#ifndef MSG_NOSIGNAL
#define MSG_NOSIGNAL 0
#endif
static int command(int,int,const void*,size_t,void*);
static int test_close(int);
static ssize_t test_send(int,const void*,size_t,int);
'''
harness=r'''
static int reads,closes,host_closes,block_send,read_mode;
static char sent[128];static size_t sent_size;
static int command(int op,int host,const void*input,size_t length,void*out) {
    assert(host==64 || host==1);
    if(op==OP_CLOSE){host_closes++;return 0;}
    assert(op==OP_READ && length==CHUNK && !input);reads++;
    if(read_mode==1)return -EAGAIN;
    if(reads==1){memcpy(out,"TAIL",4);return 4;}
    return 0;
}
static int test_close(int fd){assert(fd==42);closes++;return 0;}
static ssize_t test_send(int fd,const void*bytes,size_t n,int flags){
    assert(fd==42);(void)flags;
    if(block_send){block_send=0;errno=EAGAIN;return -1;}
    if(n>2)n=2;memcpy(sent+sent_size,bytes,n);sent_size+=n;return n;
}
int main(void){
    uint32_t registers[10]={0};ctrl=registers;
    assert(host_readiness(0)==UINT64_MAX && registers[CMD]==0);
    assert(host_readiness(1)==0 && registers[CMD]==OP_READINESS);
    registers[READY_LOW]=1;registers[READY_HIGH]=0x80000000;
    assert(host_readiness(1)==((UINT64_C(1)<<63)|1));
    registers[STATUS]=(uint32_t)-EAGAIN;assert(host_readiness(1)==UINT64_MAX);
    registers[STATUS]=(uint32_t)-EIO;assert(host_readiness(1)==UINT64_MAX);
    Client c={.fd=42,.host=64,.rx_len=6};memcpy(c.rx,"queued",6);
    block_send=1;service_host_reply(&c,0);assert(reads==0 && c.rx_off==0);
    service_host_reply(&c,0);assert(reads==0 && c.rx_off==2);
    service_host_reply(&c,UINT64_C(1)<<63);assert(reads==0 && c.rx_off==4);
    service_host_reply(&c,UINT64_C(1)<<63);assert(reads==0 && c.rx_off==6);
    service_host_reply(&c,0);assert(reads==0 && closes==0);
    service_host_reply(&c,1);assert(reads==0); /* host64 requires bit63 */
    service_host_reply(&c,UINT64_C(1)<<63);assert(reads==1 && c.rx_off==2 && closes==0);
    service_host_reply(&c,UINT64_C(1)<<63);assert(reads==1 && c.rx_off==4 && closes==0);
    service_host_reply(&c,UINT64_C(1)<<63);assert(reads==2 && closes==1 && host_closes==1 && c.fd==-1 && c.host==-1);
    assert(sent_size==10 && !memcmp(sent,"queuedTAIL",10));
    c=(Client){.fd=42,.host=1};read_mode=1;
    service_host_reply(&c,0);assert(reads==2);
    service_host_reply(&c,UINT64_MAX);assert(reads==3 && c.fd==42); /* legacy EAGAIN */
    puts("PASS broker: absent/failed readiness fallback, bit63 mapping, no idle reads, partial-send EAGAIN, queued bytes then final host bytes then EOF without loss, legacy EAGAIN");
}
'''
with tempfile.TemporaryDirectory(prefix='phgpu-broker-test-') as tmp:
    c=Path(tmp)/'test.c';binary=Path(tmp)/'test';c.write_text(prelude+source+harness)
    subprocess.run(['cc','-std=c11','-O2','-Wall','-Wextra','-Wno-unused-function','-Wno-unused-variable','-fsanitize=address,undefined',str(c),'-o',str(binary)],check=True)
    result=subprocess.check_output([str(binary)],text=True)
    if a.output:a.output.write_text(result)
    print(result,end='')
