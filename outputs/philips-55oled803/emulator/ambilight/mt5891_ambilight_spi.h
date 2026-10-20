/* Observed MT5891 local-dimming SPI software-send path.
 * dtv_driver.ko SHA256: 7c9beee7c57ce276357eb4ee8a031ea3c8e5eebd42230df5b073ae557633bea9
 * Standalone core: the QEMU wrapper supplies MMIO mapping and a transfer sink.
 */
#ifndef MT5891_AMBILIGHT_SPI_H
#define MT5891_AMBILIGHT_SPI_H
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MT5891_AMB_SPI_BASE UINT64_C(0xf0029400)
#define MT5891_AMB_SPI_SIZE 0x50u
#define MT5891_AMB_SPI_CAPACITY 65536u

typedef void (*MT5891AmbSpiSink)(void *opaque, uint64_t sequence,
                               const uint8_t *bytes, size_t count,
                               unsigned m, unsigned n, bool complete);
typedef struct MT5891AmbSpi {
    uint8_t registers[MT5891_AMB_SPI_SIZE];
    uint8_t fifo[MT5891_AMB_SPI_CAPACITY];
    size_t count;
    bool overflow;
    uint64_t sequence;
    MT5891AmbSpiSink sink;
    void *opaque;
} MT5891AmbSpi;

void mt5891_amb_spi_init(MT5891AmbSpi *, MT5891AmbSpiSink, void *);
uint32_t mt5891_amb_spi_read(MT5891AmbSpi *, uint32_t offset, unsigned size);
void mt5891_amb_spi_write(MT5891AmbSpi *, uint32_t offset, uint32_t value,
                         unsigned size);
#endif
