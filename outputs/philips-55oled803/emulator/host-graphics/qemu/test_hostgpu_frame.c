#define _DARWIN_C_SOURCE
#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
static int change_sequence;
static void before_commit(const uint8_t *map)
{
    if (change_sequence) {
        __atomic_add_fetch((uint64_t *)(void *)(map + 24), 2, __ATOMIC_SEQ_CST);
    }
}
#define PHILIPS_HOSTGPU_TEST_BEFORE_COMMIT before_commit
#include "philips-hostgpu-frame.inc"

static void put32(uint8_t *p, uint32_t v)
{
    for (unsigned i = 0; i < 4; i++) p[i] = v >> (i * 8);
}
static void put64(uint8_t *p, uint64_t v)
{
    for (unsigned i = 0; i < 8; i++) p[i] = v >> (i * 8);
}
static void header(uint8_t *map)
{
    put32(map, 0x55475048); put32(map + 4, 1);
    put32(map + 8, 1920); put32(map + 12, 1080);
    put32(map + 16, 7680); put32(map + 20, 1);
    put64(map + 24, 2); put64(map + 32, 1);
}
int main(void)
{
    uint8_t *map = calloc(1, PHILIPS_HOSTGPU_FRAME_SIZE);
    assert(map);
    header(map);
    for (unsigned y = 0; y < 1080; ++y) {
        for (unsigned x = 0; x < 1920; ++x) {
            uint8_t *pixel = map + 64 + y * 7680 + x * 4;
            pixel[0] = (x / 60) * 8;
            pixel[1] = (y / 54) * 12;
            pixel[2] = x % 60;
            pixel[3] = 9;
        }
    }
    PhilipsHostGPUFrame state = { .fd = -1 };
    uint16_t grid[3][20][32], old[3][20][32];
    memset(grid, 0xa5, sizeof(grid)); memcpy(old, grid, sizeof(old));
    change_sequence = 1;
    assert(!philips_hgf_sample_view(&state, map, PHILIPS_HOSTGPU_FRAME_SIZE, grid));
    assert(!memcmp(grid, old, sizeof(grid)));
    change_sequence = 0;
    assert(philips_hgf_sample_view(&state, map, PHILIPS_HOSTGPU_FRAME_SIZE, grid));
    for (unsigned y = 0; y < 20; ++y) {
        for (unsigned x = 0; x < 32; ++x) {
            assert(grid[0][y][x] == x * 8 * 256);
            assert(grid[1][y][x] == y * 12 * 256);
            assert(grid[2][y][x] == 29 * 256);
        }
    }
    memcpy(old, grid, sizeof(grid));
    put64(map + 24, 5);
    memset(map + 64, 255, PHILIPS_HOSTGPU_FRAME_SIZE - 64);
    assert(philips_hgf_sample_view(&state, map, PHILIPS_HOSTGPU_FRAME_SIZE, grid));
    assert(!memcmp(grid, old, sizeof(grid))); // Busy writer retains old stable frame.
    put64(map + 24, 6); put64(map + 32, 2);
    change_sequence = 1;
    assert(philips_hgf_sample_view(&state, map, PHILIPS_HOSTGPU_FRAME_SIZE, grid));
    assert(!memcmp(grid, old, sizeof(grid))); // Changed sequence does not commit.
    change_sequence = 0;
    assert(philips_hgf_sample_view(&state, map, PHILIPS_HOSTGPU_FRAME_SIZE, grid));
    assert(grid[0][0][0] == 65280 && grid[2][19][31] == 65280);
    memcpy(old, grid, sizeof(grid));
    const unsigned fields[] = {0, 4, 8, 12, 16, 20};
    for (unsigned i = 0; i < sizeof(fields)/sizeof(fields[0]); ++i) {
        uint32_t original = philips_hgf_u32(map + fields[i]);
        put32(map + fields[i], 0xffffffff);
        assert(!philips_hgf_sample_view(&state, map, PHILIPS_HOSTGPU_FRAME_SIZE, grid));
        assert(!memcmp(grid, old, sizeof(grid)));
        put32(map + fields[i], original);
    }
    put64(map + 32, 0);
    assert(!philips_hgf_sample_view(&state, map, PHILIPS_HOSTGPU_FRAME_SIZE, grid));
    put64(map + 32, 2);
    assert(!philips_hgf_sample_view(&state, map, PHILIPS_HOSTGPU_FRAME_SIZE - 1, grid));
    assert(!philips_hgf_sample_view(&state, map + 1, PHILIPS_HOSTGPU_FRAME_SIZE, grid));
    unsetenv("PHILIPS_HOSTGPU_FRAME");
    assert(!philips_hostgpu_frame_sample(grid));
    char path[] = "/tmp/philips-hostgpu-test-XXXXXX";
    int fd = mkstemp(path); assert(fd >= 0);
    assert(write(fd, map, PHILIPS_HOSTGPU_FRAME_SIZE) == PHILIPS_HOSTGPU_FRAME_SIZE);
    assert(!setenv("PHILIPS_HOSTGPU_FRAME", path, 1));
    assert(philips_hostgpu_frame_sample(grid));
    assert(grid[1][10][10] == 65280);
    assert(!ftruncate(fd, 12));
    assert(!philips_hostgpu_frame_sample(grid));
    philips_hgf_close(&philips_hostgpu_frame);
    close(fd); unlink(path); free(map);
    puts("PASS: RGBA grid, averaging, alpha ignored, seqlock race/cache, invalid metadata, alignment, size, default-off and mmap truncation");
    return 0;
}
