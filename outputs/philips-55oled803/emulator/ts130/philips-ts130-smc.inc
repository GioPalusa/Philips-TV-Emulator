/* Board adapter for the independently checked stock TS130 control subset. */
#include "philips-ts130.inc"
#include "system/address-spaces.h"

static PhilipsTs130State philips_ts130;

static bool philips_ts130_read_guest(void *opaque, uint32_t pa,
                                    void *buffer, size_t length)
{
    MemoryRegionSection section;
    bool valid;
    if (!length || length > 64 || length > 0x100000000ULL - pa) {
        return false;
    }
    /* The vendor wrapper supplies a DMA physical address. Do not permit its
     * malformed payload to issue MMIO or access host/secure memory. */
    section = memory_region_find(get_system_memory(), pa, length);
    valid = section.mr && memory_region_is_ram(section.mr) &&
            !memory_region_is_ram_device(section.mr) &&
            int128_get64(section.size) >= length;
    if (valid) {
        memcpy(buffer, (uint8_t *)memory_region_get_ram_ptr(section.mr) +
               section.offset_within_region, length);
    }
    if (section.mr) {
        memory_region_unref(section.mr);
    }
    return valid;
}

static bool philips_ts130_smc(ARMCPU *cpu)
{
    CPUARMState *env = &cpu->env;
    int32_t result;
    if (is_a64(env) || env->regs[0] != 0x545a3330 ||
        !philips_ts130_handle(&philips_ts130, env->regs[1], env->regs[2],
                             env->regs[3], philips_ts130_read_guest, NULL,
                             &result)) {
        return false;
    }
    fprintf(stderr, "[mt5891-ts130] control=%04x result=%d initialized=%d pids=%u\n",
            env->regs[1], result, philips_ts130.initialized,
            philips_ts130.pid_count);
    env->regs[0] = result;
    return true;
}

static void philips_ts130_board_reset(void *opaque)
{
    philips_ts130_reset(&philips_ts130);
}

static void philips_ts130_board_init(void)
{
    CPUState *cs;
    if (g_strcmp0(getenv("PHILIPS_TS130_CONTROL"), "1")) {
        return;
    }
    CPU_FOREACH(cs) {
        ARM_CPU(cs)->vendor_smc_handler = philips_ts130_smc;
    }
    qemu_register_reset(philips_ts130_board_reset, NULL);
}
