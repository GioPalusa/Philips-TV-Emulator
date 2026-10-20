#include "mt5891_ambilight_spi.h"
#include <assert.h>
#include <stdio.h>

static unsigned transfers;
static void capture(void *opaque, uint64_t seq, const uint8_t *bytes,
                    size_t count, unsigned m, unsigned n, bool complete)
{
    (void)opaque;
    assert(seq == ++transfers);
    assert(m == 2 && n == 4);
    if (seq == 1) {
        assert(count == 8 && complete);
        for (unsigned i = 0; i < 8; ++i) {
            assert(bytes[i] == i + 1);
        }
    } else {
        assert(count == 1 && !complete);
    }
}
int main(void)
{
    static MT5891AmbSpi spi;
    mt5891_amb_spi_init(&spi, capture, NULL);
    assert(mt5891_amb_spi_read(&spi, 0x4c, 1) & 0x20);
    mt5891_amb_spi_write(&spi, 0x40, 2 << 4, 2);
    mt5891_amb_spi_write(&spi, 0x42, 4 << 4, 2);
    mt5891_amb_spi_write(&spi, 0, 0, 4);
    for (unsigned i = 1; i <= 8; ++i) {
        mt5891_amb_spi_write(&spi, 8, i, 4);
    }
    mt5891_amb_spi_write(&spi, 0x4c, 1, 1);
    assert(transfers == 1);
    assert(mt5891_amb_spi_read(&spi, 0x4c, 1) == 0x20);
    assert(mt5891_amb_spi_read(&spi, 4, 2) == 0);
    mt5891_amb_spi_write(&spi, 0, 0, 4);
    mt5891_amb_spi_write(&spi, 8, 99, 4);
    mt5891_amb_spi_write(&spi, 0x4c, 1, 1);
    assert(transfers == 2);
    puts("SPI software-send ABI tests passed");
    return 0;
}
