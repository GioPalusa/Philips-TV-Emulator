#ifndef MT5891_AMBILIGHT_MEASURE_H
#define MT5891_AMBILIGHT_MEASURE_H
#include <stdbool.h>
#include <stdint.h>

#define MT5891_AMB_MEASURE_BASE UINT64_C(0xf0027b00)
#define MT5891_AMB_MEASURE_SIZE 16u
#define MT5891_AMB_COLUMNS 32u
#define MT5891_AMB_ROWS 20u
typedef void (*MT5891AmbMeasureIRQ)(void *opaque, bool asserted);

typedef struct MT5891AmbMeasure {
    uint16_t samples[3][MT5891_AMB_ROWS][MT5891_AMB_COLUMNS];
    uint8_t configuration[8];
    uint8_t status;
    unsigned row, next_row, column;
    bool irq_enabled, irq_asserted;
    MT5891AmbMeasureIRQ irq;
    void *opaque;
} MT5891AmbMeasure;

void mt5891_amb_measure_init(MT5891AmbMeasure *, MT5891AmbMeasureIRQ, void *);
void mt5891_amb_measure_enable_irq(MT5891AmbMeasure *, bool enabled);
bool mt5891_amb_measure_step_row(MT5891AmbMeasure *);
void mt5891_amb_measure_ack(MT5891AmbMeasure *, uint8_t pulse);
uint32_t mt5891_amb_measure_read(MT5891AmbMeasure *, uint32_t offset, unsigned size);
void mt5891_amb_measure_write(MT5891AmbMeasure *, uint32_t offset, uint32_t value,
                             unsigned size);
/* Explicit test input, in raw measurement units; does not sample video. */
void mt5891_amb_measure_fixture(MT5891AmbMeasure *);
/* Explicit constant raw R,G,B input. Decimal or 0x-prefixed hexadecimal,
 * comma separated, each 0..65535. Invalid input leaves all samples unchanged.
 */
bool mt5891_amb_measure_fixture_rgb16(MT5891AmbMeasure *, const char *spec);
#endif
