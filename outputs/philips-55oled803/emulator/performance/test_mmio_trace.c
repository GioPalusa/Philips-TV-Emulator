#include "philips-mmio-trace.h"
#include <assert.h>
#include <stdio.h>
#include <time.h>

static PhilipsTraceTable table;
static uint64_t old_addresses[PHILIPS_TRACE_LIMIT], old_counts[PHILIPS_TRACE_LIMIT];
static unsigned old_used;
static uint64_t old_access(uint64_t address)
{
    for (unsigned i = 0; i < old_used; i++) {
        if (old_addresses[i] == address) return ++old_counts[i];
    }
    if (old_used < PHILIPS_TRACE_LIMIT) old_addresses[old_used++] = address;
    return 0;
}
static double seconds(void)
{
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    return now.tv_sec + now.tv_nsec / 1e9;
}
int main(void)
{
    bool first = false;
    /* Repeated colliding and unaligned accesses, capacity, and old counts. */
    for (unsigned i = 0; i < PHILIPS_TRACE_LIMIT; i++) {
        uint64_t a = UINT64_C(0xf0000000) + i * 257;
        PhilipsTraceEntry *e = philips_trace_access(&table, a, &first);
        assert(e && first && e->count == old_access(a));
    }
    assert(!philips_trace_access(&table, UINT64_C(0xf8000001), &first));
    for (unsigned i = 0; i < PHILIPS_TRACE_LIMIT; i++) {
        uint64_t a = UINT64_C(0xf0000000) + i * 257;
        PhilipsTraceEntry *e = philips_trace_access(&table, a, &first);
        assert(e && !first && e->count == old_access(a));
    }
    /* Diagnostic table microbenchmark, not a guest-rendering benchmark. */
    volatile uint64_t checksum = 0;
    unsigned random = 7;
    double start = seconds();
    for (unsigned i = 0; i < 1000000; i++) {
        random = random * 1664525U + 1013904223U;
        checksum += old_access(old_addresses[PHILIPS_TRACE_LIMIT - 256 + (random >> 24)]);
    }
    double linear = seconds() - start;
    random = 7;
    start = seconds();
    for (unsigned i = 0; i < 1000000; i++) {
        random = random * 1664525U + 1013904223U;
        checksum += philips_trace_access(&table,
            old_addresses[PHILIPS_TRACE_LIMIT - 256 + (random >> 24)], &first)->count;
    }
    double hashed = seconds() - start;
    printf("PASS: first/repeated/collision/capacity semantics; checksum=%llu\n"
           "1M hot accesses at 8192 entries: linear %.6fs, hash %.6fs (%.1fx)\n",
           (unsigned long long)checksum, linear, hashed, linear / hashed);
    return 0;
}
