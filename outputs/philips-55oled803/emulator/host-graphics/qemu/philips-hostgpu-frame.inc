/*
 * Optional measurements of posted guest GLES frames from the host renderer.
 * PHILIPS_HOSTGPU_FRAME points to its fixed-size, read-only shared frame file.
 * This is a graphics translation development path, not Mali hardware emulation.
 * No host LED colors are generated: the output feeds the stock measurement ISR.
 *
 * Include before philips-ambilight-framebuffer.inc. The latter calls
 * philips_hostgpu_frame_sample(output) before trying raw guest OSD RAM.
 * Initialization is lazy; no virt.c initialization hook is required.
 */
#ifndef PHILIPS_HOSTGPU_FRAME_INC
#define PHILIPS_HOSTGPU_FRAME_INC
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>

#define PHILIPS_HOSTGPU_FRAME_SIZE (64u + 1920u * 1080u * 4u)
#define PHILIPS_HOSTGPU_GRID_ROWS 20
#define PHILIPS_HOSTGPU_GRID_COLUMNS 32

typedef struct PhilipsHostGPUFrame {
    int fd;
    const uint8_t *map;
    uint64_t sequence;
    uint64_t frame_count;
    bool cached;
    bool warned;
    bool announced;
    uint16_t grid[3][PHILIPS_HOSTGPU_GRID_ROWS][PHILIPS_HOSTGPU_GRID_COLUMNS];
} PhilipsHostGPUFrame;

static PhilipsHostGPUFrame philips_hostgpu_frame = { .fd = -1 };

static uint32_t philips_hgf_u32(const volatile uint8_t *p)
{
    return (uint32_t)p[0] | (uint32_t)p[1] << 8 |
           (uint32_t)p[2] << 16 | (uint32_t)p[3] << 24;
}

static uint64_t philips_hgf_u64_atomic(const uint8_t *p)
{
    uint64_t value = __atomic_load_n((const uint64_t *)p, __ATOMIC_ACQUIRE);
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    value = __builtin_bswap64(value);
#endif
    return value;
}

/* Return a grid only for a validated stable publication. A busy/changing writer
 * may reuse the previous stable grid. Invalid metadata never reuses that cache.
 * The caller's destination is untouched when this returns false. */
static bool philips_hgf_sample_view(PhilipsHostGPUFrame *state,
                                    const uint8_t *map, size_t length,
                                    uint16_t output[3][20][32])
{
    uint16_t next[3][20][32];
    uint64_t before, after, frame_count;
    const volatile uint8_t *bytes = map;
    if (!map || !output || length != PHILIPS_HOSTGPU_FRAME_SIZE ||
        ((uintptr_t)map & 7)) {
        return false;
    }
    before = philips_hgf_u64_atomic(map + 24);
    if (philips_hgf_u32(bytes) != UINT32_C(0x55475048) ||
        philips_hgf_u32(bytes + 4) != 1 ||
        philips_hgf_u32(bytes + 8) != 1920 ||
        philips_hgf_u32(bytes + 12) != 1080 ||
        philips_hgf_u32(bytes + 16) != 7680 ||
        philips_hgf_u32(bytes + 20) != 1) {
        return false;
    }
    if (before & 1) {
        if (state->cached) {
            memcpy(output, state->grid, sizeof(state->grid));
        }
        return state->cached;
    }
    frame_count = philips_hgf_u64_atomic(map + 32);
    if (!before || !frame_count) {
        return false;
    }
    if (state->cached && before == state->sequence &&
        frame_count == state->frame_count) {
        memcpy(output, state->grid, sizeof(state->grid));
        return true;
    }
    /* At most 10,240 pixel locations / 30,720 color-byte loads per new frame;
     * no 8 MiB image copy or scanline allocation while holding the QEMU lock. */
    for (unsigned row = 0; row < 20; ++row) {
        for (unsigned column = 0; column < 32; ++column) {
            unsigned sums[3] = { 0, 0, 0 };
            for (unsigned sy = 0; sy < 4; ++sy) {
                unsigned y = ((row * 8 + sy * 2 + 1) * 1080) / (20 * 8);
                for (unsigned sx = 0; sx < 4; ++sx) {
                    unsigned x = ((column * 8 + sx * 2 + 1) * 1920) / (32 * 8);
                    size_t offset = 64 + (size_t)y * 7680 + x * 4;
                    for (unsigned c = 0; c < 3; ++c) {
                        sums[c] += bytes[offset + c];
                    }
                }
            }
            for (unsigned c = 0; c < 3; ++c) {
                next[c][row][column] = (sums[c] / 16) << 8;
            }
        }
    }
#ifdef PHILIPS_HOSTGPU_TEST_BEFORE_COMMIT
    PHILIPS_HOSTGPU_TEST_BEFORE_COMMIT(map);
#endif
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    after = philips_hgf_u64_atomic(map + 24);
    if (before != after || (after & 1)) {
        if (state->cached) {
            memcpy(output, state->grid, sizeof(state->grid));
        }
        return state->cached;
    }
    memcpy(state->grid, next, sizeof(next));
    state->sequence = after;
    state->frame_count = frame_count;
    state->cached = true;
    memcpy(output, next, sizeof(next));
    return true;
}

static void philips_hgf_close(PhilipsHostGPUFrame *state)
{
    if (state->map) {
        munmap((void *)state->map, PHILIPS_HOSTGPU_FRAME_SIZE);
    }
    if (state->fd >= 0) {
        close(state->fd);
    }
    state->map = NULL;
    state->fd = -1;
    state->cached = false;
}

static bool philips_hostgpu_frame_sample(uint16_t output[3][20][32])
{
    PhilipsHostGPUFrame *state = &philips_hostgpu_frame;
    const char *path = getenv("PHILIPS_HOSTGPU_FRAME");
    struct stat st;
    if (!path || !*path) {
        return false;
    }
    if (!state->map) {
        state->fd = open(path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
        if (state->fd < 0 || fstat(state->fd, &st) || !S_ISREG(st.st_mode) ||
            st.st_size != PHILIPS_HOSTGPU_FRAME_SIZE) {
            philips_hgf_close(state);
            if (!state->warned) {
                fprintf(stderr, "[hostgpu measurements] waiting for a regular version-1 frame file\n");
                state->warned = true;
            }
            return false;
        }
        void *mapping = mmap(NULL, PHILIPS_HOSTGPU_FRAME_SIZE, PROT_READ,
                             MAP_SHARED, state->fd, 0);
        if (mapping == MAP_FAILED) {
            philips_hgf_close(state);
            return false;
        }
        state->map = mapping;
    }
    /* The producer keeps the file size and inode for the entire run. This check
     * catches accidental prior truncation; it cannot make hostile concurrent
     * truncation safe. The shared file is a trusted local renderer interface. */
    if (fstat(state->fd, &st) || st.st_size != PHILIPS_HOSTGPU_FRAME_SIZE) {
        philips_hgf_close(state);
        return false;
    }
    bool valid = philips_hgf_sample_view(state, state->map,
                                         PHILIPS_HOSTGPU_FRAME_SIZE, output);
    if (valid && !state->announced) {
        fprintf(stderr, "[hostgpu measurements] sampling posted guest RGBA frames; approximate 32x20 grid\n");
        state->announced = true;
    }
    return valid;
}
#endif
