/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef PHILIPS_MMIO_TRACE_H
#define PHILIPS_MMIO_TRACE_H
#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

#define PHILIPS_TRACE_LIMIT 8192
#define PHILIPS_TRACE_SLOTS (2 * PHILIPS_TRACE_LIMIT)
typedef struct PhilipsTraceEntry {
    uint64_t address, count;
} PhilipsTraceEntry;
typedef struct PhilipsTraceTable {
    PhilipsTraceEntry entries[PHILIPS_TRACE_SLOTS];
    unsigned used;
} PhilipsTraceTable;

/* Caller holds QEMU's BQL, as for the previous diagnostic counters.
 * Actual peripheral addresses are nonzero. Keep the original 8192-address
 * limit, first-access count of zero, and subsequent access counts. */
static inline PhilipsTraceEntry *
philips_trace_access(PhilipsTraceTable *table, uint64_t address, bool *first)
{
    if (!address) {
        return NULL;
    }
    uint64_t hash = address ^ (address >> 16);
    unsigned slot = (hash * UINT64_C(11400714819323198485)) >> 50;
    for (;;) {
        PhilipsTraceEntry *entry = &table->entries[slot];
        if (entry->address == address) {
            entry->count++;
            *first = false;
            return entry;
        }
        if (!entry->address) {
            if (!address || table->used == PHILIPS_TRACE_LIMIT) {
                return NULL;
            }
            entry->address = address;
            entry->count = 0;
            table->used++;
            *first = true;
            return entry;
        }
        slot = (slot + 1) & (PHILIPS_TRACE_SLOTS - 1);
    }
}
#endif
