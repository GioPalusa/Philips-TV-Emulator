#include "mt5891_ambilight_measure.h"
#include <assert.h>
#include <stdio.h>

static unsigned raises, lowers;
static void irq(void *opaque, bool asserted)
{
    (void)opaque;
    if (asserted) ++raises; else ++lowers;
}
int main(void)
{
    static MT5891AmbMeasure s;
    mt5891_amb_measure_init(&s, irq, NULL);
    mt5891_amb_measure_fixture(&s);
    mt5891_amb_measure_enable_irq(&s, true);
    for (unsigned row = 0; row < 20; ++row) {
        assert(mt5891_amb_measure_step_row(&s));
        assert(!mt5891_amb_measure_step_row(&s));
        assert(s.status == 0x80);
        assert((mt5891_amb_measure_read(&s, 8, 1) & 31) == row);
        for (unsigned col = 0; col < 32; ++col) {
            unsigned position = row * 32 + col;
            assert(mt5891_amb_measure_read(&s, 10, 2) == 0x1000 + position);
            assert((mt5891_amb_measure_read(&s, 8, 2) >> 5) == col);
            assert(mt5891_amb_measure_read(&s, 12, 4) ==
                   ((0x3000 + position) << 16 | (0x2000 + position)));
        }
        assert(mt5891_amb_measure_read(&s, 12, 4) == 0);
        mt5891_amb_measure_ack(&s, 0x80);
        assert(!s.irq_asserted);
    }
    assert(raises == 20 && lowers == 20);
    assert(mt5891_amb_measure_step_row(&s));
    assert(s.row == 0);
    assert(mt5891_amb_measure_fixture_rgb16(&s, "0xff00,32768,255"));
    assert(mt5891_amb_measure_read(&s, 10, 2) == 0xff00);
    assert(mt5891_amb_measure_read(&s, 12, 4) == 0x00ff8000);
    const char *invalid[] = {
        "", "1,2", "1,2,3,4", "-1,0,0", "65536,0,0",
        "0x10000,0,0", "0x,0,0", "1,2,3x", "a,0,0", "1, 2,3",
        "99999999999999999999999,0,0", NULL
    };
    for (unsigned i = 0; i < sizeof(invalid) / sizeof(invalid[0]); ++i) {
        assert(!mt5891_amb_measure_fixture_rgb16(&s, invalid[i]));
        /* Invalid configuration is atomic: the previous fixture survives. */
        assert(mt5891_amb_measure_read(&s, 10, 2) == 0xff00);
    }
    mt5891_amb_measure_ack(&s, 0x80);
    assert(mt5891_amb_measure_step_row(&s));
    assert(mt5891_amb_measure_read(&s, 10, 2) == 0xff00);
    assert(mt5891_amb_measure_read(&s, 12, 4) == 0x00ff8000);
    puts("Measurement register sequence tests passed (synthetic raw samples)");
    return 0;
}
