#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <assert.h>
typedef uint64_t hwaddr;
static int64_t fake_ns;
static void (*reset_callback)(void *);
static void qemu_register_reset(void(*fn)(void*),void*unused){reset_callback=fn;}
int64_t qemu_clock_get_ns(int clock){assert(clock==0);return fake_ns;}
void qemu_get_timedate(struct tm*t,time_t offset){time_t s=1709164799+offset;gmtime_r(&s,t);} // 2024-02-28 23:59:59 UTC
/* Same calendar arithmetic as QEMU util/cutils.c. */
time_t mktimegm(struct tm*t){int y=t->tm_year+1900,m=t->tm_mon+1,d=t->tm_mday;if(m<3){m+=12;y--;}return 86400ULL*(d+(153*m-457)/5+365*y+y/4-y/100+y/400-719469)+3600*t->tm_hour+60*t->tm_min+t->tm_sec;}
#include "philips-rtc.inc"
static uint64_t rd(unsigned r){uint64_t v;assert(philips_rtc_read(0x28700+r,1,&v));return v;}
static void wr(unsigned r,unsigned v){assert(philips_rtc_write(0x28700+r,1,v));}
static void unlock(void){wr(0x48,0x87);wr(0x48,0x78);}
static void set(unsigned year,unsigned mon,unsigned day,unsigned hour,unsigned min,unsigned sec){unlock();wr(0x3c,0x43);wr(0,year);wr(4,mon);wr(8,day);wr(0x10,hour);wr(0x14,min);wr(0x18,sec);wr(0x3c,0x42);wr(0x48,0);}
int main(void){uint64_t v;philips_rtc_init();assert(reset_callback==philips_rtc_reset);
 assert(rd(0x3c)==0x40&&rd(0)==0x24&&rd(4)==2&&rd(8)==0x28&&rd(0x10)==0x23&&rd(0x14)==0x59&&rd(0x18)==0x59);
 assert(philips_rtc_read(0x28108,4,&v)&&v==12000000);assert(!philips_rtc_read(0x28044,4,&v));assert(!philips_rtc_write(0x28108,4,0));
 wr(0x18,0x11);assert(rd(0x18)==0x59);wr(0x48,0x78);wr(0x18,0x11);assert(rd(0x18)==0x59); // locked/unorderedkey
 fake_ns+=1000000000;assert(rd(8)==0x29&&rd(0x10)==0&&rd(0x14)==0&&rd(0x18)==0&&rd(0xc)==4); // leapday Thurs
 unlock();wr(0x3c,0x43);fake_ns+=300000000000LL;assert(rd(0x18)==0);wr(0x18,0x55);wr(0x3c,0x42);wr(0x48,0);assert(rd(0x18)==0x55);fake_ns+=5000000000;assert(rd(0x18)==0&&rd(0x14)==1);
 set(0x25,2,0x28,0x23,0x59,0x59);fake_ns+=1000000000;assert(rd(4)==3&&rd(8)==1&&rd(0x18)==0); // ordinaryyear
 set(0x24,0x12,0x31,0x23,0x59,0x59);fake_ns+=1000000000;assert(rd(0)==0x25&&rd(4)==1&&rd(8)==1&&rd(0x10)==0); // yearrollover
 set(0x00,2,0x28,0x23,0x59,0x59);fake_ns+=1000000000;assert(rd(8)==0x29); // leapcentury2000
 assert(philips_rtc_read(0x28700,4,&v)&&v==0);assert(philips_rtc_read(0x28704,2,&v)&&v==2); // buslanes
 unlock();wr(0x3c,0);assert(rd(0x3c)==0x40); // presentbitreadonly
 reset_callback(NULL);assert(rd(0)==0x24&&rd(8)==0x28);puts("RTC_MODEL_PASS: presence, oscillator, BCD, 24h, leap/day/year rollover, freeze/set/resume, unlock, bus lanes, reset");return 0;}
