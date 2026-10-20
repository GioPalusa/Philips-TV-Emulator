#ifndef MT5891_AMBILIGHT_FRAMEBUFFER_H
#define MT5891_AMBILIGHT_FRAMEBUFFER_H
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "mt5891_ambilight_measure.h"

typedef bool (*MT5891AmbFramebufferRead)(void *opaque, uint32_t address,
                                        void *destination, size_t count);
/*
 * Approximate measurements of the raw OSD plane-2 first region, not final
 * panel composition. Supports only the observed uncompressed format14 and
 * byte selectors. 4x4 samples per cell; averaged RGB8 is shifted left8.
 * Destination is unchanged on failure. Reader must reject non-RAM ranges.
 */
bool mt5891_amb_framebuffer_sample(uint32_t control, uint32_t header_address,
    MT5891AmbFramebufferRead read_ram, void *opaque,
    uint16_t output[3][MT5891_AMB_ROWS][MT5891_AMB_COLUMNS]);
#endif
