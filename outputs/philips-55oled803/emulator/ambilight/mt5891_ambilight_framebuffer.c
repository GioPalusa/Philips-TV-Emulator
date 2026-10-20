#include "mt5891_ambilight_framebuffer.h"
#include <string.h>

static uint16_t amb_fb_le16(const uint8_t *p)
{
    return (uint16_t)p[0] | ((uint16_t)p[1] << 8);
}

static uint32_t amb_fb_le32(const uint8_t *p)
{
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

bool mt5891_amb_framebuffer_sample(uint32_t control, uint32_t header_address,
    MT5891AmbFramebufferRead read_ram, void *opaque,
    uint16_t output[3][MT5891_AMB_ROWS][MT5891_AMB_COLUMNS])
{
    uint8_t header[48], scanline[4096 * 4];
    uint16_t grid[3][MT5891_AMB_ROWS][MT5891_AMB_COLUMNS];
    if (!(control & 1) || !header_address || !read_ram || !output ||
        !read_ram(opaque, header_address, header, sizeof(header))) {
        return false;
    }
    uint32_t bitmap = (amb_fb_le32(header + 4) & 0x0fffffff) << 4;
    unsigned format = header[3] >> 4;
    unsigned pitch = (amb_fb_le16(header + 8) & 0x7ff) << 4;
    unsigned width = amb_fb_le16(header + 36) & 0x1fff;
    unsigned height = amb_fb_le16(header + 38) & 0xfff;
    unsigned selectors[3] = {
        (header[11] >> 4) & 3, (header[11] >> 2) & 3, header[11] & 3
    };
    if (format != 14 || (header[15] & 0x10) || !width || !height ||
        width > 4096 || height > 2160 || pitch < width * 4 ||
        (uint64_t)bitmap + (uint64_t)pitch * height > UINT32_MAX) {
        return false;
    }
    for (unsigned cell_y = 0; cell_y < MT5891_AMB_ROWS; ++cell_y) {
        unsigned sums[3][MT5891_AMB_COLUMNS] = {{0}};
        for (unsigned sample_y = 0; sample_y < 4; ++sample_y) {
            unsigned y = ((uint64_t)(cell_y * 8 + sample_y * 2 + 1) *
                          height) / (MT5891_AMB_ROWS * 8);
            if (!read_ram(opaque, bitmap + y * pitch, scanline, width * 4)) {
                return false;
            }
            for (unsigned cell_x = 0; cell_x < MT5891_AMB_COLUMNS; ++cell_x) {
                for (unsigned sample_x = 0; sample_x < 4; ++sample_x) {
                    unsigned x = ((uint64_t)(cell_x * 8 + sample_x * 2 + 1) *
                                  width) / (MT5891_AMB_COLUMNS * 8);
                    for (unsigned c = 0; c < 3; ++c) {
                        sums[c][cell_x] += scanline[x * 4 + selectors[c]];
                    }
                }
            }
        }
        for (unsigned c = 0; c < 3; ++c) {
            for (unsigned cell_x = 0; cell_x < MT5891_AMB_COLUMNS; ++cell_x) {
                grid[c][cell_y][cell_x] = (sums[c][cell_x] / 16) << 8;
            }
        }
    }
    memcpy(output, grid, sizeof(grid));
    return true;
}
