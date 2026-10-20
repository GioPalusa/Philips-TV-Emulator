#define HWC_UNIT_TEST
#include "hwcomposer_emulator.c"
#include <assert.h>
#include <stdatomic.h>
static int posts, post_result, fence_result, waited, closed, screen;
static atomic_int callbacks;
static buffer_handle_t posted;
static int fb_post(framebuffer_device_t *fb, buffer_handle_t b) { (void)fb; posts++; posted=b; return post_result; }
static int fb_close(hw_device_t *d) { (void)d; closed++; return 0; }
static int fb_screen(framebuffer_device_t *d, int enabled) { (void)d; screen=enabled; return 0; }
static framebuffer_device_t mock_fb = {
 .common={.close=fb_close}, .width=1920, .height=1080, .stride=1920,
 .fps=60.0f, .xdpi=160.0f, .ydpi=160.0f, .post=fb_post, .enableScreen=fb_screen
};
static int fb_open(const hw_module_t *m, const char *n, hw_device_t **out) {
 (void)m; assert(!strcmp(n,GRALLOC_HARDWARE_FB0)); *out=&mock_fb.common; return 0;
}
static hw_module_methods_t fb_methods={.open=fb_open};
static hw_module_t fb_module={.methods=&fb_methods};
int test_hw_get_module(const char *n, const hw_module_t **out) {assert(!strcmp(n,"gralloc"));*out=&fb_module;return 0;}
int test_sync_wait(int fd, int timeout) {assert(fd>=0&&timeout==3000);waited++;if(fence_result)errno=ETIME;return fence_result;}
int test_clock_nanosleep(clockid_t clock, int flags, const struct timespec *t, struct timespec *remaining) {
 (void)clock;(void)flags;(void)remaining;
 int64_t delta=(int64_t)t->tv_sec*1000000000+t->tv_nsec-monotonic_ns();
 if(delta<=0)return 0;
 struct timespec delay={delta/1000000000,delta%1000000000};
 return nanosleep(&delay,NULL)?errno:0;
}
static void on_vsync(const hwc_procs_t *p,int display,int64_t timestamp) {(void)p;assert(display==0&&timestamp>0);atomic_fetch_add(&callbacks,1);}
int main(void) {
 hw_device_t *device=NULL;
 assert(open_device(&HAL_MODULE_INFO_SYM.common,"wrong",&device)==-EINVAL);
 assert(open_device(&HAL_MODULE_INFO_SYM.common,HWC_HARDWARE_COMPOSER,&device)==0);
 hwc_composer_device_1_t *d=(void*)device;
 size_t count=0;assert(d->getDisplayConfigs(d,0,NULL,&count)==0&&count==1);
 assert(d->getDisplayConfigs(d,1,NULL,&count)==-ENODEV);
 uint32_t attrs[]={HWC_DISPLAY_WIDTH,HWC_DISPLAY_HEIGHT,HWC_DISPLAY_VSYNC_PERIOD,HWC_DISPLAY_DPI_X,HWC_DISPLAY_NO_ATTRIBUTE};
 int32_t values[4];assert(d->getDisplayAttributes(d,0,0,attrs,values)==0);
 assert(values[0]==1920&&values[1]==1080&&values[2]==16666667&&values[3]==160000);
 hwc_display_contents_1_t *list=calloc(1,sizeof(*list)+2*sizeof(hwc_layer_1_t));
 list->numHwLayers=2;list->hwLayers[0].compositionType=HWC_OVERLAY;
 list->hwLayers[1].compositionType=HWC_FRAMEBUFFER_TARGET;
 list->hwLayers[1].handle=(void*)0x1234;
 hwc_display_contents_1_t *displays[]={list,NULL};
 assert(d->prepare(d,2,displays)==0&&list->hwLayers[0].compositionType==HWC_FRAMEBUFFER);
 int fds[2];assert(pipe(fds)==0);
 list->hwLayers[0].acquireFenceFd=fds[0];list->hwLayers[1].acquireFenceFd=fds[1];
 assert(d->set(d,2,displays)==0&&posts==1&&posted==(void*)0x1234&&waited==1);
 assert(list->hwLayers[0].acquireFenceFd==-1&&list->hwLayers[1].acquireFenceFd==-1);
 assert(fcntl(fds[0],F_GETFD)==-1&&errno==EBADF);assert(fcntl(fds[1],F_GETFD)==-1&&errno==EBADF);
 assert(list->retireFenceFd==-1&&list->hwLayers[0].releaseFenceFd==-1);
 assert(pipe(fds)==0);list->hwLayers[0].acquireFenceFd=fds[0];list->hwLayers[1].acquireFenceFd=fds[1];
 fence_result=-1;assert(d->set(d,2,displays)==-ETIME&&posts==1);fence_result=0;
 assert(fcntl(fds[0],F_GETFD)==-1&&errno==EBADF);assert(fcntl(fds[1],F_GETFD)==-1&&errno==EBADF);
 post_result=-ENOSPC;assert(d->set(d,2,displays)==-ENOSPC&&posts==2);post_result=0;
 assert(d->blank(d,0,1)==0&&screen==0);assert(d->blank(d,0,0)==0&&screen==1);
 hwc_procs_t procs={.vsync=on_vsync};d->registerProcs(d,&procs);
 assert(d->eventControl(d,0,HWC_EVENT_VSYNC,2)==-EINVAL);
 assert(d->eventControl(d,0,HWC_EVENT_VSYNC,1)==0);
 struct timespec delay={0,70000000};nanosleep(&delay,NULL);
 assert(atomic_load(&callbacks)>0);
 assert(d->eventControl(d,0,HWC_EVENT_VSYNC,0)==0);
 assert(device->close(device)==0&&closed==1);
 free(list);puts("PASS: framebuffer attrs, client composition, target post, fence ownership/errors, blank, vsync, close");
}
