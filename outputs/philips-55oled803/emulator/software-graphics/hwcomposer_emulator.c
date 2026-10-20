/* Development-only HWC1.1 framebuffer composer. All layers are rendered by
 * SurfaceFlinger/GLES; this HAL waits for and posts the real client target. */
#define LOG_TAG "EmulatorFramebufferHWC"
#ifdef HWC_UNIT_TEST
#include "test_platform.h"
#else
#include <hardware/hwcomposer.h>
#include <hardware/gralloc.h>
#include <hardware/fb.h>
#include <sync/sync.h>
#include <log/log.h>
#include <linux/fb.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#endif
#include <errno.h>
#include <pthread.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

struct emulator_hwc {
    hwc_composer_device_1_t device;
    framebuffer_device_t *fb;
    pthread_mutex_t lock;
    pthread_t thread;
    const hwc_procs_t *callbacks;
    int stop, vsync_enabled, blanked;
    int64_t period;
};

static struct emulator_hwc *state(hwc_composer_device_1_t *d)
{
    return (struct emulator_hwc *)d;
}

static int prepare(hwc_composer_device_1_t *d, size_t n,
                   hwc_display_contents_1_t **displays)
{
    (void)d;
    if (!displays && n) return -EINVAL;
    for (size_t i = 0; i < n; i++) {
        if (!displays[i]) continue;
        if (i != HWC_DISPLAY_PRIMARY) return -ENODEV;
        for (size_t j = 0; j < displays[i]->numHwLayers; j++) {
            hwc_layer_1_t *layer = &displays[i]->hwLayers[j];
            layer->hints = 0;
            if (layer->compositionType != HWC_FRAMEBUFFER_TARGET)
                layer->compositionType = HWC_FRAMEBUFFER;
        }
    }
    return 0;
}

static int present(hwc_composer_device_1_t *d, size_t n,
                   hwc_display_contents_1_t **displays)
{
    struct emulator_hwc *s = state(d);
    buffer_handle_t target = NULL;
    int result = 0;
    if (!displays && n) return -EINVAL;
    for (size_t i = 0; i < n; i++) {
        hwc_display_contents_1_t *list = displays[i];
        if (!list) continue;
        list->retireFenceFd = -1;
        if (i != HWC_DISPLAY_PRIMARY) result = -ENODEV;
        for (size_t j = 0; j < list->numHwLayers; j++) {
            hwc_layer_1_t *layer = &list->hwLayers[j];
            layer->releaseFenceFd = -1;
            int is_target = i == HWC_DISPLAY_PRIMARY &&
                            layer->compositionType == HWC_FRAMEBUFFER_TARGET;
            if (is_target) {
                if (target) result = -EINVAL;
                target = layer->handle;
            }
            if (layer->acquireFenceFd >= 0) {
                int fd = layer->acquireFenceFd;
                /* No source layers are read by this HAL. The client target
                 * must be complete before its buffer is handed to fb->post. */
                if (is_target && sync_wait(fd, 3000) < 0)
                    result = errno ? -errno : -EIO;
                close(fd);
                layer->acquireFenceFd = -1;
            }
        }
    }
    if (result) return result;
    if (!n || !displays[HWC_DISPLAY_PRIMARY]) return 0;
    if (!target) return -EINVAL;
    if (s->fb->compositionComplete) {
        result = s->fb->compositionComplete(s->fb);
        if (result) return result;
    }
    /* Framebuffer HAL owns scanout locking until the buffer is released by a
     * later post. HWC1.1 permits no explicit fence for that synchronous API. */
    result = s->fb->post(s->fb, target);
    if (result) ALOGE("framebuffer post failed: %d", result);
    return result;
}

static int event_control(hwc_composer_device_1_t *d, int display,
                         int event, int enabled)
{
    if (display != HWC_DISPLAY_PRIMARY || event != HWC_EVENT_VSYNC ||
        (enabled != 0 && enabled != 1)) return -EINVAL;
    struct emulator_hwc *s = state(d);
    pthread_mutex_lock(&s->lock);
    s->vsync_enabled = enabled;
    pthread_mutex_unlock(&s->lock);
    return 0;
}

static int blank(hwc_composer_device_1_t *d, int display, int value)
{
    if (display != HWC_DISPLAY_PRIMARY || (value != 0 && value != 1))
        return -EINVAL;
    struct emulator_hwc *s = state(d);
    int result;
    if (s->fb->enableScreen) {
        result = s->fb->enableScreen(s->fb, !value);
    } else {
        int fd = open("/dev/graphics/fb0", O_RDWR | O_CLOEXEC);
        if (fd < 0) fd = open("/dev/fb0", O_RDWR | O_CLOEXEC);
        if (fd < 0) return -errno;
        result = ioctl(fd, FBIOBLANK, value ? FB_BLANK_POWERDOWN : FB_BLANK_UNBLANK);
        if (result < 0) result = -errno;
        close(fd);
    }
    if (!result) {
        pthread_mutex_lock(&s->lock);
        s->blanked = value;
        pthread_mutex_unlock(&s->lock);
    }
    return result;
}

static int query(hwc_composer_device_1_t *d, int what, int *value)
{
    if (!value) return -EINVAL;
    switch (what) {
    case HWC_BACKGROUND_LAYER_SUPPORTED: *value = 0; return 0;
    case HWC_VSYNC_PERIOD: *value = state(d)->period; return 0;
    case HWC_DISPLAY_TYPES_SUPPORTED: *value = 1 << HWC_DISPLAY_PRIMARY; return 0;
    default: return -EINVAL;
    }
}

static void register_procs(hwc_composer_device_1_t *d, const hwc_procs_t *p)
{
    struct emulator_hwc *s = state(d);
    pthread_mutex_lock(&s->lock);
    s->callbacks = p;
    pthread_mutex_unlock(&s->lock);
}

static int configs(hwc_composer_device_1_t *d, int display, uint32_t *out,
                   size_t *count)
{
    (void)d;
    if (display != HWC_DISPLAY_PRIMARY) return -ENODEV;
    if (!count || (*count && !out)) return -EINVAL;
    if (*count) out[0] = 0;
    *count = 1;
    return 0;
}

static int attributes(hwc_composer_device_1_t *d, int display, uint32_t config,
                      const uint32_t *attrs, int32_t *out)
{
    struct emulator_hwc *s = state(d);
    if (display != HWC_DISPLAY_PRIMARY) return -ENODEV;
    if (config || !attrs || !out) return -EINVAL;
    for (unsigned i = 0; i < 32; i++) {
        switch (attrs[i]) {
        case HWC_DISPLAY_NO_ATTRIBUTE: return 0;
        case HWC_DISPLAY_VSYNC_PERIOD: out[i] = s->period; break;
        case HWC_DISPLAY_WIDTH: out[i] = s->fb->width; break;
        case HWC_DISPLAY_HEIGHT: out[i] = s->fb->height; break;
        case HWC_DISPLAY_DPI_X: out[i] = s->fb->xdpi * 1000; break;
        case HWC_DISPLAY_DPI_Y: out[i] = s->fb->ydpi * 1000; break;
        default: return -EINVAL;
        }
    }
    return -EINVAL;
}

static void dump(hwc_composer_device_1_t *d, char *buf, int size)
{
    if (size > 0) snprintf(buf, size,
        "Development framebuffer composer: %ux%u, period=%lld ns; "
        "client GLES composition, framebuffer HAL post, guest-clock VSync\n",
        state(d)->fb->width, state(d)->fb->height, (long long)state(d)->period);
}

static int64_t monotonic_ns(void)
{
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    return (int64_t)now.tv_sec * 1000000000LL + now.tv_nsec;
}

static void *vsync_thread(void *opaque)
{
    struct emulator_hwc *s = opaque;
    int64_t next = monotonic_ns();
    for (;;) {
        next += s->period;
        int64_t now = monotonic_ns();
        if (next < now) next = now + s->period;
        struct timespec time = {next / 1000000000LL, next % 1000000000LL};
        int result;
        do { result = clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &time, NULL); }
        while (result == EINTR);
        pthread_mutex_lock(&s->lock);
        int stop = s->stop;
        const hwc_procs_t *p = s->callbacks;
        int enabled = s->vsync_enabled && !s->blanked;
        pthread_mutex_unlock(&s->lock);
        if (stop) return NULL;
        if (enabled && p && p->vsync) p->vsync(p, HWC_DISPLAY_PRIMARY, monotonic_ns());
    }
}

static int close_device(hw_device_t *device)
{
    struct emulator_hwc *s = (struct emulator_hwc *)device;
    pthread_mutex_lock(&s->lock);
    s->stop = 1;
    pthread_mutex_unlock(&s->lock);
    pthread_join(s->thread, NULL);
    framebuffer_close(s->fb);
    pthread_mutex_destroy(&s->lock);
    free(s);
    return 0;
}

static int open_device(const hw_module_t *module, const char *name,
                       hw_device_t **out)
{
    if (!out || !name || strcmp(name, HWC_HARDWARE_COMPOSER)) return -EINVAL;
    *out = NULL;
    const hw_module_t *gralloc;
    int result = hw_get_module(GRALLOC_HARDWARE_MODULE_ID, &gralloc);
    if (result) return result;
    struct emulator_hwc *s = calloc(1, sizeof(*s));
    if (!s) return -ENOMEM;
    result = framebuffer_open(gralloc, &s->fb);
    if (result) { free(s); return result; }
    if (!s->fb->post || !s->fb->width || !s->fb->height ||
        !(s->fb->fps >= 1.0f && s->fb->fps <= 1000.0f)) {
        framebuffer_close(s->fb); free(s); return -EINVAL;
    }
    s->period = (int64_t)(1000000000.0 / s->fb->fps + 0.5);
    pthread_mutex_init(&s->lock, NULL);
    s->device.common.tag = HARDWARE_DEVICE_TAG;
    s->device.common.version = HWC_DEVICE_API_VERSION_1_1;
    s->device.common.module = (hw_module_t *)module;
    s->device.common.close = close_device;
    s->device.prepare = prepare;
    s->device.set = present;
    s->device.eventControl = event_control;
    s->device.blank = blank;
    s->device.query = query;
    s->device.registerProcs = register_procs;
    s->device.dump = dump;
    s->device.getDisplayConfigs = configs;
    s->device.getDisplayAttributes = attributes;
    result = pthread_create(&s->thread, NULL, vsync_thread, s);
    if (result) {
        framebuffer_close(s->fb); pthread_mutex_destroy(&s->lock); free(s);
        return -result;
    }
    *out = &s->device.common;
    ALOGI("Software framebuffer composer opened %ux%u at %.3f Hz",
          s->fb->width, s->fb->height, s->fb->fps);
    return 0;
}

static hw_module_methods_t methods = { .open = open_device };
__attribute__((visibility("default"))) hwc_module_t HAL_MODULE_INFO_SYM = {
    .common = {
        .tag = HARDWARE_MODULE_TAG,
        .module_api_version = HWC_MODULE_API_VERSION_0_1,
        .hal_api_version = HARDWARE_HAL_API_VERSION,
        .id = HWC_HARDWARE_MODULE_ID,
        .name = "Development software framebuffer composer",
        .author = "Philips emulator development",
        .methods = &methods,
    },
};
