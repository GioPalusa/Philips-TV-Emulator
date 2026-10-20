#define _POSIX_C_SOURCE 200809L
#include <time.h>
#include <signal.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
int main(void){
 struct sigevent event={0};event.sigev_notify=SIGEV_NONE;timer_t timer;
 if(timer_create((clockid_t)9,&event,&timer)){printf("RTC_ALARM_CREATE_FAIL errno=%d %s\n",errno,strerror(errno));return 1;}
 struct itimerspec setting={{0,0},{0,250000000}},remaining={0};
 if(timer_settime(timer,0,&setting,0)){printf("RTC_ALARM_SET_FAIL errno=%d %s\n",errno,strerror(errno));timer_delete(timer);return 2;}
 timer_gettime(timer,&remaining);printf("RTC_ALARM_CREATED remaining=%ld.%09ld\n",(long)remaining.it_value.tv_sec,remaining.it_value.tv_nsec);
 struct timespec pause={0,500000000};while(nanosleep(&pause,&pause)&&errno==EINTR){}
 if(timer_gettime(timer,&remaining)){printf("RTC_ALARM_GET_FAIL errno=%d\n",errno);timer_delete(timer);return 3;}
 timer_delete(timer);
 if(remaining.it_value.tv_sec||remaining.it_value.tv_nsec){printf("RTC_ALARM_NOT_EXPIRED\n");return 4;}
 puts("RTC_ALARM_PASS CLOCK_BOOTTIME_ALARM create/set/awake-expiry/delete");return 0;
}
