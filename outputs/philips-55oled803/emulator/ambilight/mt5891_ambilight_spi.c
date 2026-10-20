#include "mt5891_ambilight_spi.h"
#include <string.h>

static uint32_t load_bytes(const uint8_t *bytes, unsigned size)
{
    uint32_t result = 0;
    for (unsigned i = 0; i < size; ++i) {
        result |= (uint32_t)bytes[i] << (8 * i);
    }
    return result;
}

static bool access_valid(uint32_t offset, unsigned size)
{
    return (size == 1 || size == 2 || size == 4) &&
           offset <= MT5891_AMB_SPI_SIZE - size;
}

void mt5891_amb_spi_init(MT5891AmbSpi *s, MT5891AmbSpiSink sink, void *opaque)
{
    memset(s, 0, sizeof(*s));
    s->registers[0x4c] = 0x20; /* driver polls bit 5 for send completion */
    s->sink = sink;
    s->opaque = opaque;
}

uint32_t mt5891_amb_spi_read(MT5891AmbSpi *s, uint32_t offset, unsigned size)
{
    if (!access_valid(offset, size)) {
        return 0;
    }
    return load_bytes(s->registers + offset, size);
}

void mt5891_amb_spi_write(MT5891AmbSpi *s, uint32_t offset,
                         uint32_t value, unsigned size)
{
    if (!access_valid(offset, size)) {
        return;
    }
    /* Exact observed path: write zero at 0x00 before streaming FIFO bytes. */
    if (offset == 0 && value == 0) {
        s->count = 0;
        s->overflow = false;
    }
    if (offset == 8) {
        /* STR writes the byte loaded by LDRB; upper three bytes are not data. */
        if (s->count < sizeof(s->fifo)) {
            s->fifo[s->count++] = (uint8_t)value;
        } else {
            s->overflow = true;
        }
    }
    for (unsigned i = 0; i < size; ++i) {
        s->registers[offset + i] = (uint8_t)(value >> (i * 8));
    }
    if (offset <= 0x4c && offset + size > 0x4c &&
        (s->registers[0x4c] & 1)) {
        unsigned m = (load_bytes(s->registers + 0x40, 2) >> 4) & 255;
        unsigned n = (load_bytes(s->registers + 0x42, 2) >> 4) & 255;
        bool complete = !s->overflow && m != 0 && n != 0 &&
                        s->count == (size_t)m * n;
        ++s->sequence;
        if (s->sink) {
            s->sink(s->opaque, s->sequence, s->fifo, s->count, m, n, complete);
        }
        /* Synchronous transfer is our implementation choice, not measured
         * hardware timing. Preserve configuration, self-clear start, signal
         * completion and release the driver-visible FIFO busy/occupancy field.
         */
        s->registers[0x4c] = (s->registers[0x4c] & ~1u) | 0x20;
        s->registers[4] = 0;
        s->registers[5] &= ~3u;
    }
}
