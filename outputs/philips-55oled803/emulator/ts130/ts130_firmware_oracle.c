#include <stdint.h>
#define WORD(a) (*(volatile uint32_t *)(a))
#define BYTE(a) (*(volatile uint8_t *)(a))
#define PID(i) (*(volatile uint16_t *)(0x7d3d2eac+2*(i)))
static volatile unsigned calls, failalloc;
static uint32_t allocator(uint32_t size) { ++calls;return size!=131072 || failalloc ? 0 : 0x7d180013; }
static void print(const char *s) {register unsigned r0 asm("r0")=4;register const char *r1 asm("r1")=s;asm volatile("svc 0x123456" : "+r"(r0) : "r"(r1) : "memory");}
static void quit(unsigned status) {unsigned args[2]={0x20026,status};register unsigned r0 asm("r0")=0x20;register unsigned *r1 asm("r1")=args;asm volatile("svc 0x123456" : : "r"(r0),"r"(r1) : "memory");for(;;);}
#define CHECK(x) do { if(!(x)){print("FAIL: " #x "\n");quit(1);} }while(0)
static uint32_t call(uint32_t off,uint32_t arg){return ((uint32_t(*)(uint32_t))(0x7d005000+off))(arg);}
void main(void) {
 /* Replace only the heap allocator entry with a test allocator; all three
  * control handlers run original firmware bytes. No original MMIO is mapped. */
 WORD(0x7d09a240)=0xe51ff004;WORD(0x7d09a244)=(uint32_t)allocator;
 failalloc=1;CHECK(call(0x5b310,0)==0);CHECK(BYTE(0x7d3d2e9c)==0);
 failalloc=0;CHECK(call(0x5b310,0)==1);CHECK(calls==2);CHECK(BYTE(0x7d3d2e9c)==1);
 CHECK(WORD(0x7d3d2e98)==0x7d180040);CHECK(WORD(0x7d3d30b4)==0x7d1a0040);
 CHECK(WORD(0x7d3d2ea4)==0x7d3d2cc0);CHECK(WORD(0x7d3d30ac)==0x7d3d2cc0);CHECK(WORD(0x7d3d30bc)==0x7d3d2cc0);
 CHECK(WORD(0x7d3d2cb4)==0x7d3d2e52);CHECK(WORD(0x7d3d2ea0)==0x7d3d2f80);CHECK(WORD(0x7d3d30b8)==0x7d3d3080);
 for(unsigned i=0;i<96;i++){CHECK(PID(i)==65535);CHECK(call(0x5b8a8,i+1)==1);}
 CHECK(call(0x5b8a8,100)==0);CHECK(BYTE(0x7d3d2e94)==96);
 for(unsigned i=0;i<96;i++)CHECK(PID(i)==i+1);
 CHECK(call(0x5b8a8,0xfff)==1);CHECK(BYTE(0x7d3d2e94)==0);for(unsigned i=0;i<96;i++)CHECK(PID(i)==65535);
 CHECK(call(0x5b8a8,0xffff)==1);CHECK(BYTE(0x7d3d2e94)==1);
 WORD(0x7d3d30ac)=0x7d3d2cf0;WORD(0x7d3d30bc)=0x7d3d2d10;WORD(0x7d3d2e90)=39;BYTE(0x7d3d2e8c)=1;
 CHECK(call(0x5b92c,0x87)==1);CHECK(WORD(0x7d3d30ac)==WORD(0x7d3d2ea4));CHECK(WORD(0x7d3d30bc)==WORD(0x7d3d2ea4));
 CHECK(WORD(0x7d3d2e90)==0);CHECK(BYTE(0x7d3d2e8c)==0);CHECK(BYTE(0x7d3d2e94)==1);
 WORD(0x7d3d30ac)=0x7d3d2cf4;BYTE(0x7d180040)=0x5a;
 CHECK(call(0x5b310,0)==1);CHECK(calls==2);CHECK(WORD(0x7d3d30ac)==0x7d3d2cf4);CHECK(BYTE(0x7d180040)==0x5a);CHECK(BYTE(0x7d3d2e94)==0);
 print("PASS: original TS130 firmware init allocation failure/success/repeat; 96 PID capacity/overflow; 0xfff clear; 0xffff ordinary PID; reset ignores argument, preserves PID state, resets parser cursors.\n");quit(0);
}
__attribute__((naked,section(".start"))) void _start(void){asm volatile("ldr sp, =0x403ff000\nbl main\nb .");}
