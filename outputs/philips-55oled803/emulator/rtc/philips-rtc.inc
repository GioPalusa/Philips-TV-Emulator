/* SPDX-License-Identifier: GPL-2.0-or-later */
/*
 * MT5891 PDWNC calendar subset, reconstructed from the stock 3.10.79 driver.
 * This registers a real ticking/read-write RTC for Linux alarmtimer's backend.
 * Power-state wakeup and alarm interrupt delivery are not modeled here yet.
 * Keep this limitation explicit; CPU hrtimer delivery while running is kernel work.
 */
#include "system/rtc.h"
#include "qemu/timer.h"
#include "qemu/cutils.h"

static struct {
    uint8_t regs[0x4c];
    uint8_t key_stage;
    bool unlocked;
    int64_t epoch;
    int64_t start_ns;
    int64_t displayed_second;
} philips_rtc;

static unsigned philips_rtc_bcd(unsigned value)
{
    return ((value / 10) << 4) | (value % 10);
}

static unsigned philips_rtc_unbcd(unsigned value)
{
    return ((value >> 4) * 10) + (value & 15);
}

static void philips_rtc_refresh(void)
{
    int64_t second;
    time_t stamp;
    struct tm tm;

    if (philips_rtc.regs[0x3c] & 1) {
        return;
    }
    second = philips_rtc.epoch +
        (qemu_clock_get_ns(QEMU_CLOCK_VIRTUAL) - philips_rtc.start_ns) /
        NANOSECONDS_PER_SECOND;
    if (second == philips_rtc.displayed_second) {
        return;
    }
    stamp = second;
    gmtime_r(&stamp, &tm);
    philips_rtc.regs[0x00] = philips_rtc_bcd((tm.tm_year + 1900) % 100);
    philips_rtc.regs[0x04] = philips_rtc_bcd(tm.tm_mon + 1);
    philips_rtc.regs[0x08] = philips_rtc_bcd(tm.tm_mday);
    philips_rtc.regs[0x0c] = philips_rtc_bcd(tm.tm_wday);
    philips_rtc.regs[0x10] = philips_rtc_bcd(tm.tm_hour);
    philips_rtc.regs[0x14] = philips_rtc_bcd(tm.tm_min);
    philips_rtc.regs[0x18] = philips_rtc_bcd(tm.tm_sec);
    philips_rtc.regs[0x44] = philips_rtc_bcd(tm.tm_year % 4);
    philips_rtc.displayed_second = second;
}

static void philips_rtc_commit(void)
{
    struct tm tm = { 0 }, checked;
    time_t stamp;
    tm.tm_year = philips_rtc_unbcd(philips_rtc.regs[0x00]) + 100;
    tm.tm_mon = philips_rtc_unbcd(philips_rtc.regs[0x04] & 0x1f) - 1;
    tm.tm_mday = philips_rtc_unbcd(philips_rtc.regs[0x08] & 0x3f);
    tm.tm_hour = philips_rtc_unbcd(philips_rtc.regs[0x10] & 0x3f);
    tm.tm_min = philips_rtc_unbcd(philips_rtc.regs[0x14] & 0x7f);
    tm.tm_sec = philips_rtc_unbcd(philips_rtc.regs[0x18] & 0x7f);
    stamp = mktimegm(&tm);
    gmtime_r(&stamp, &checked);
    if (checked.tm_year == tm.tm_year && checked.tm_mon == tm.tm_mon &&
        checked.tm_mday == tm.tm_mday && checked.tm_hour == tm.tm_hour &&
        checked.tm_min == tm.tm_min && checked.tm_sec == tm.tm_sec) {
        philips_rtc.epoch = stamp;
        philips_rtc.start_ns = qemu_clock_get_ns(QEMU_CLOCK_VIRTUAL);
    }
    philips_rtc.displayed_second = INT64_MIN;
    philips_rtc_refresh();
}

static bool philips_rtc_read(hwaddr off, unsigned size, uint64_t *value)
{
    /* Stock probe uses this oscillator calibration to validate preserved time. */
    if (off == 0x28108 && size == 4) {
        *value = 12000000;
        return true;
    }
    if (off < 0x28700 || off + size > 0x2874c || !size || size > 4) {
        return false;
    }
    philips_rtc_refresh();
    *value = 0;
    for (unsigned i = 0; i < size; i++) {
        *value |= (uint64_t)philips_rtc.regs[off - 0x28700 + i] << (i * 8);
    }
    return true;
}

static bool philips_rtc_write(hwaddr off, unsigned size, uint64_t value)
{
    if (off < 0x28700 || off + size > 0x2874c || !size || size > 4) {
        return false;
    }
    philips_rtc_refresh();
    for (unsigned i = 0; i < size; i++) {
        unsigned reg = off - 0x28700 + i;
        uint8_t byte = value >> (i * 8);
        if (reg == 0x48) {
            if (byte == 0x87) {
                philips_rtc.key_stage = 1;
                philips_rtc.unlocked = false;
            } else if (byte == 0x78 && philips_rtc.key_stage == 1) {
                philips_rtc.key_stage = 2;
                philips_rtc.unlocked = true;
            } else {
                philips_rtc.key_stage = 0;
                philips_rtc.unlocked = false;
            }
            philips_rtc.regs[reg] = byte;
        } else if (philips_rtc.unlocked) {
            uint8_t old = philips_rtc.regs[reg];
            philips_rtc.regs[reg] = reg == 0x3c ? byte | 0x40 : byte;
            if (reg == 0x3c && (old & 1) && !(byte & 1)) {
                philips_rtc_commit();
            }
        }
    }
    return true;
}

static void philips_rtc_reset(void *opaque)
{
    struct tm tm;
    memset(&philips_rtc, 0, sizeof(philips_rtc));
    qemu_get_timedate(&tm, 0);
    philips_rtc.epoch = mktimegm(&tm);
    philips_rtc.start_ns = qemu_clock_get_ns(QEMU_CLOCK_VIRTUAL);
    philips_rtc.regs[0x3c] = 0x40; /* RTC present/enabled fuse status */
    philips_rtc.displayed_second = INT64_MIN;
    philips_rtc_refresh();
}

static void philips_rtc_init(void)
{
    philips_rtc_reset(NULL);
    qemu_register_reset(philips_rtc_reset, NULL);
}
