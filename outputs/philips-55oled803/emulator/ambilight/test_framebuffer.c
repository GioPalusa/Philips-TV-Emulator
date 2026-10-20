#include "mt5891_ambilight_framebuffer.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

static uint8_t ram[65536];
static unsigned reads;
static uint32_t fail_at = UINT32_MAX;

static bool read_ram(void *opaque, uint32_t address, void *dst, size_t count)
{
    (void)opaque;
    ++reads;
    assert(count <= 4096 * 4);
    if (address >= fail_at || (uint64_t)address + count > sizeof(ram)) {
        return false;
    }
    memcpy(dst, ram + address, count);
    return true;
}

static void le16(uint8_t *p, unsigned v)
{
    p[0] = v; p[1] = v >> 8;
}
static void le32(uint8_t *p, uint32_t v)
{
    p[0] = v; p[1] = v >> 8; p[2] = v >> 16; p[3] = v >> 24;
}
static void descriptor(unsigned width, unsigned height, unsigned pitch)
{
    memset(ram, 0, sizeof(ram));
    ram[16 + 3] = 14 << 4;
    le32(ram + 16 + 4, 256 >> 4);
    le16(ram + 16 + 8, pitch >> 4);
    ram[16 + 11] = 0x24; /* R byte2, G byte1, B byte0. */
    le16(ram + 16 + 36, width);
    le16(ram + 16 + 38, height);
}

int main(void)
{
    uint16_t out[3][20][32], before[3][20][32];
    descriptor(128, 80, 528);
    for (unsigned y = 0; y < 80; ++y) {
        for (unsigned x = 0; x < 128; ++x) {
            uint8_t *p = ram + 256 + y * 528 + x * 4;
            p[0] = (x % 4) + 4 * (y % 4); /* Cell mean floors to7. */
            p[1] = (y / 4) * 12;
            p[2] = (x / 4) * 8;
            p[3] = 255; /* Alpha must not contaminate RGB. */
        }
    }
    assert(mt5891_amb_framebuffer_sample(1, 16, read_ram, NULL, out));
    assert(reads == 81); /* One header and80 bounded scanline reads. */
    for (unsigned y = 0; y < 20; ++y) {
        for (unsigned x = 0; x < 32; ++x) {
            assert(out[0][y][x] == (x * 8) << 8);
            assert(out[1][y][x] == (y * 12) << 8);
            assert(out[2][y][x] == 7 << 8);
        }
    }
    ram[16 + 11] = 0x06; /* Swap red/blue byte selectors. */
    assert(mt5891_amb_framebuffer_sample(1, 16, read_ram, NULL, out));
    assert(out[0][19][31] == 7 << 8);
    assert(out[2][19][31] == 248 << 8);
    memcpy(before, out, sizeof(out));
    fail_at = 256 + 40 * 528;
    assert(!mt5891_amb_framebuffer_sample(1, 16, read_ram, NULL, out));
    assert(!memcmp(out, before, sizeof(out))); /* No partial frame commit. */
    fail_at = UINT32_MAX;
    ram[16 + 15] = 0x10;
    assert(!mt5891_amb_framebuffer_sample(1, 16, read_ram, NULL, out));
    ram[16 + 15] = 0;
    ram[16 + 3] = 13 << 4;
    assert(!mt5891_amb_framebuffer_sample(1, 16, read_ram, NULL, out));
    ram[16 + 3] = 14 << 4;
    le16(ram + 16 + 8, 16 >> 4);
    assert(!mt5891_amb_framebuffer_sample(1, 16, read_ram, NULL, out));
    le16(ram + 16 + 8, 528 >> 4);
    le32(ram + 16 + 4, 0x0fffffff);
    assert(!mt5891_amb_framebuffer_sample(1, 16, read_ram, NULL, out));
    reads = 0;
    assert(!mt5891_amb_framebuffer_sample(0, 16, read_ram, NULL, out));
    assert(reads == 0);
    descriptor(1, 1, 16);
    ram[256] = 3; ram[257] = 2; ram[258] = 1; ram[259] = 255;
    assert(mt5891_amb_framebuffer_sample(1, 16, read_ram, NULL, out));
    assert(out[0][19][31] == 256 && out[1][19][31] == 512 &&
           out[2][19][31] == 768);
    puts("Framebuffer sampler tests passed: grid, selectors, stride, bounds, atomic failure.");
}
