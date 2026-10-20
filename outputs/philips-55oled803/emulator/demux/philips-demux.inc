/*
 * MT5891 FTI control handshakes observed in stock dtv_driver.ko:
 * _DMX_EnableFTI (0x3c3964), _DMX_ResetFTuP (0x3c38c8),
 * _DMX_Reset (0x3c4b1c).
 *
 * This models an idle demux control plane and instruction RAM loading port,
 * not execution of the FTI microcontroller, transport decoding, DMA, or IRQs.
 * _DMX_LoadIMem (0x3c4c08) provides the RAM transaction format. With no packet
 * work in flight, halt requests complete synchronously. Unmodeled register
 * accesses remain visible to the board's missing-MMIO trace.
 */
#include "system/reset.h"

#define PTV_DMX_FTI_CONTROL 0x17000
#define PTV_DMX_IMEM_COMMAND 0x1700c
#define PTV_DMX_IMEM_DATA 0x17010
#define PTV_DMX_FTU_CONTROL 0x170c0
#define PTV_DMX_FTI_COMMAND UINT32_C(0xc0000000)
#define PTV_DMX_FTI_STATUS UINT32_C(0x30000000)
#define PTV_DMX_FTU_HALT UINT32_C(0x80000000)
#define PTV_DMX_FTU_HALTED UINT32_C(0x40000000)

static struct {
    uint32_t fti;
    uint32_t ftu;
    uint32_t command;
    uint32_t data;
    /* Full 16-bit word address field; actual silicon capacity is unknown. */
    uint32_t imem[65536];
} philips_demux;

static uint32_t *philips_demux_register(hwaddr offset, unsigned size)
{
    if ((size != 1 && size != 2 && size != 4) ||
        (offset & 3) + size > 4) {
        return NULL;
    }
    switch (offset & ~UINT64_C(3)) {
    case PTV_DMX_FTI_CONTROL:
        return &philips_demux.fti;
    case PTV_DMX_FTU_CONTROL:
        return &philips_demux.ftu;
    case PTV_DMX_IMEM_COMMAND:
        return &philips_demux.command;
    case PTV_DMX_IMEM_DATA:
        return &philips_demux.data;
    default:
        return NULL;
    }
}

static bool philips_demux_read(hwaddr offset, unsigned size, uint64_t *value)
{
    uint32_t *reg = philips_demux_register(offset, size);
    if (!reg) {
        return false;
    }
    *value = (*reg >> (8 * (offset & 3))) &
             ((UINT64_C(1) << (8 * size)) - 1);
    return true;
}

static bool philips_demux_write(hwaddr offset, unsigned size, uint64_t value)
{
    uint32_t *reg = philips_demux_register(offset, size);
    uint32_t mask, merged, status;
    unsigned shift = 8 * (offset & 3);
    if (!reg) {
        return false;
    }
    mask = ((UINT64_C(1) << (8 * size)) - 1) << shift;
    merged = (*reg & ~mask) | (((uint32_t)value << shift) & mask);
    if (reg == &philips_demux.ftu) {
        /* Halt ack is device-owned. It stays asserted until halt is released,
         * including the driver's reset pulse and interrupt-queue drain. */
        merged &= ~PTV_DMX_FTU_HALTED;
        if (merged & PTV_DMX_FTU_HALT) {
            merged |= PTV_DMX_FTU_HALTED;
        }
    } else if (reg == &philips_demux.fti) {
        status = *reg & PTV_DMX_FTI_STATUS;
        /* Start (00), halt (01), and reset (10) are evidenced. Reset returns
         * to halted state and retains the instruction RAM just uploaded.
         * Command 11 retains prior status instead of inventing a reply. */
        if ((mask & PTV_DMX_FTI_COMMAND) &&
            ((merged & PTV_DMX_FTI_COMMAND) == UINT32_C(0x40000000) ||
             (merged & PTV_DMX_FTI_COMMAND) == UINT32_C(0x80000000))) {
            status = UINT32_C(0x10000000);
        } else if ((mask & PTV_DMX_FTI_COMMAND) &&
                   !(merged & PTV_DMX_FTI_COMMAND)) {
            status = 0;
        }
        merged = (merged & ~PTV_DMX_FTI_STATUS) | status;
    } else if (reg == &philips_demux.command &&
               offset == PTV_DMX_IMEM_COMMAND && size == 4) {
        /* Execute only the two full-word transactions emitted by LoadIMem.
         * Unsupported encodings retain their command bits, hence cannot
         * masquerade as a successfully completed operation. */
        unsigned index = merged >> 16;
        if ((merged & 0xffff) == 0x201) {
            philips_demux.imem[index] = philips_demux.data;
            merged &= ~UINT32_C(0xf00);
        } else if ((merged & 0xffff) == 0x101) {
            philips_demux.data = philips_demux.imem[index];
            merged &= ~UINT32_C(0xf00);
        }
    }
    *reg = merged;
    return true;
}

static void philips_demux_reset(void *opaque)
{
    (void)opaque;
    memset(&philips_demux, 0, sizeof(philips_demux));
}

static void philips_demux_init(void)
{
    philips_demux_reset(NULL);
    qemu_register_reset(philips_demux_reset, NULL);
}
