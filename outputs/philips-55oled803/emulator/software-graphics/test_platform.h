#include <hardware/hwcomposer.h>
#include <hardware/gralloc.h>
#include <hardware/fb.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <time.h>
#include <stdio.h>
#define FBIOBLANK 0x4611
#define FB_BLANK_POWERDOWN 4
#define FB_BLANK_UNBLANK 0
#define ALOGE(...) ((void)0)
#define ALOGI(...) ((void)0)
#ifndef TIMER_ABSTIME
#define TIMER_ABSTIME 1
#endif
int test_sync_wait(int fd, int timeout);
int test_hw_get_module(const char *, const hw_module_t **);
int test_clock_nanosleep(clockid_t, int, const struct timespec *, struct timespec *);
#define sync_wait test_sync_wait
#define hw_get_module test_hw_get_module
#define clock_nanosleep test_clock_nanosleep
