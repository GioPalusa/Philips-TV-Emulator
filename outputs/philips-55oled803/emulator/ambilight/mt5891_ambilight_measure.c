#include "mt5891_ambilight_measure.h"
#include <string.h>

static void update_irq(MT5891AmbMeasure *s)
{
    bool asserted = s->irq_enabled && (s->status & 0x80);
    if (asserted != s->irq_asserted) {
        s->irq_asserted = asserted;
        if (s->irq) {
            s->irq(s->opaque, asserted);
        }
    }
}

void mt5891_amb_measure_init(MT5891AmbMeasure *s, MT5891AmbMeasureIRQ irq, void *opaque)
{
    memset(s, 0, sizeof(*s));
    s->irq = irq;
    s->opaque = opaque;
}

void mt5891_amb_measure_enable_irq(MT5891AmbMeasure *s, bool enabled)
{
    s->irq_enabled = enabled;
    update_irq(s);
}

bool mt5891_amb_measure_step_row(MT5891AmbMeasure *s)
{
    if (s->status & 0x80) {
        return false; /* Do not silently overwrite an unconsumed row. */
    }
    s->row = s->next_row;
    s->next_row = (s->next_row + 1) % MT5891_AMB_ROWS;
    s->column = 0;
    s->status |= 0x80;
    update_irq(s);
    return true;
}

void mt5891_amb_measure_ack(MT5891AmbMeasure *s, uint8_t pulse)
{
    s->status &= ~(pulse & 0x80);
    update_irq(s);
}

uint32_t mt5891_amb_measure_read(MT5891AmbMeasure *s, uint32_t offset, unsigned size)
{
    uint8_t bytes[16] = {0};
    uint32_t result = 0;
    if ((size != 1 && size != 2 && size != 4) || offset > 16 - size) {
        return 0;
    }
    memcpy(bytes, s->configuration, sizeof(s->configuration));
    unsigned col = s->column < MT5891_AMB_COLUMNS ? s->column : MT5891_AMB_COLUMNS - 1;
    unsigned meta = s->row | (col << 5);
    bytes[8] = meta;
    bytes[9] = meta >> 8;
    if (s->column < MT5891_AMB_COLUMNS && (s->status & 0x80)) {
        for (unsigned channel = 0; channel < 3; ++channel) {
            uint16_t value = s->samples[channel][s->row][s->column];
            bytes[10 + channel * 2] = value;
            bytes[11 + channel * 2] = value >> 8;
        }
    }
    for (unsigned i = 0; i < size; ++i) {
        result |= (uint32_t)bytes[offset + i] << (i * 8);
    }
    /* Observed guest consumes channel0, metadata, then packed channels1/2.
     * Advancing only after the final packed read is an explicit model
     * hypothesis to validate against real hardware.
     */
    if (offset == 12 && size == 4 && s->column < MT5891_AMB_COLUMNS &&
        (s->status & 0x80)) {
        ++s->column;
    }
    return result;
}

void mt5891_amb_measure_write(MT5891AmbMeasure *s, uint32_t offset,
                             uint32_t value, unsigned size)
{
    if ((size != 1 && size != 2 && size != 4) || offset > 8 - size) {
        return;
    }
    for (unsigned i = 0; i < size; ++i) {
        s->configuration[offset + i] = value >> (i * 8);
    }
}

void mt5891_amb_measure_fixture(MT5891AmbMeasure *s)
{
    for (unsigned row = 0; row < MT5891_AMB_ROWS; ++row) {
        for (unsigned col = 0; col < MT5891_AMB_COLUMNS; ++col) {
            s->samples[0][row][col] = 0x1000 + row * 32 + col;
            s->samples[1][row][col] = 0x2000 + row * 32 + col;
            s->samples[2][row][col] = 0x3000 + row * 32 + col;
        }
    }
}

bool mt5891_amb_measure_fixture_rgb16(MT5891AmbMeasure *s, const char *spec)
{
    uint16_t rgb[3];
    if (!spec) {
        return false;
    }
    for (unsigned channel = 0; channel < 3; ++channel) {
        unsigned base = 10, value = 0, digits = 0;
        if (spec[0] == '0' && (spec[1] == 'x' || spec[1] == 'X')) {
            base = 16;
            spec += 2;
        }
        while (*spec) {
            unsigned digit;
            if (*spec >= '0' && *spec <= '9') {
                digit = *spec - '0';
            } else if (*spec >= 'a' && *spec <= 'f') {
                digit = *spec - 'a' + 10;
            } else if (*spec >= 'A' && *spec <= 'F') {
                digit = *spec - 'A' + 10;
            } else {
                break;
            }
            if (digit >= base || value > (65535u - digit) / base) {
                return false;
            }
            value = value * base + digit;
            ++digits;
            ++spec;
        }
        if (!digits || (channel < 2 ? *spec != ',' : *spec != '\0')) {
            return false;
        }
        rgb[channel] = value;
        if (channel < 2) {
            ++spec;
        }
    }
    for (unsigned channel = 0; channel < 3; ++channel) {
        for (unsigned row = 0; row < MT5891_AMB_ROWS; ++row) {
            for (unsigned col = 0; col < MT5891_AMB_COLUMNS; ++col) {
                s->samples[channel][row][col] = rgb[channel];
            }
        }
    }
    return true;
}
