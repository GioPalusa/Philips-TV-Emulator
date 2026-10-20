/* Philips TPM171E TS130 control subset, recovered from stock tzbp firmware.
 * Intentionally no packet parser, descrambler, cryptography or general TEE.
 * Include after qemu/osdep.h (g_try_malloc0/g_free); standalone tests supply
 * the same allocator interface. Routing must be opt-in and limited to the
 * MediaTek SMC service 0x545a3330. See demux/README.md for evidence and limits.
 */
#define PHILIPS_TS130_RING_SIZE (128u * 1024u)
#define PHILIPS_TS130_PID_CAPACITY 96u
#define PHILIPS_TS130_SCRATCH_SIZE 402u
#define PHILIPS_TS130_STAGING_SIZE 256u

typedef struct PhilipsTs130State {
    uint8_t *ring;
    bool initialized;
    uint16_t pids[PHILIPS_TS130_PID_CAPACITY];
    uint8_t pid_count;
    uint32_t partial_length;
    uint8_t parser_flag;
    /* Original pointers are represented by offsets into owned storage;
     * secure-world addresses are never exposed to the normal-world guest. */
    uint32_t ring_read_offset, ring_write_offset;
    uint32_t scratch_read_offset, scratch_write_offset;
    uint8_t scratch[PHILIPS_TS130_SCRATCH_SIZE];
    uint8_t staging[PHILIPS_TS130_STAGING_SIZE];
} PhilipsTs130State;

typedef bool (*PhilipsTs130ReadGuest)(void *opaque, uint32_t physical_address,
                                    void *buffer, size_t length);

static void philips_ts130_clear_pids(PhilipsTs130State *s)
{
    for (unsigned i = 0; i < PHILIPS_TS130_PID_CAPACITY; ++i) {
        s->pids[i] = UINT16_MAX;
    }
    s->pid_count = 0;
}

static void philips_ts130_reset(PhilipsTs130State *s)
{
    g_free(s->ring);
    memset(s, 0, sizeof(*s));
}

/* Returns false for commands this subset does not implement. In that case,
 * state, output and guest memory remain untouched and the caller retains its
 * existing unsupported-service result. Handled firmware failures return 10.
 * Payload bounds below deliberately restrict the emulator entry boundary;
 * the original firmware relies on a trusted in-kernel caller instead.
 */
static bool philips_ts130_handle(PhilipsTs130State *s, uint32_t command,
                                uint32_t payload_pa, uint32_t payload_size,
                                PhilipsTs130ReadGuest read_guest, void *opaque,
                                int32_t *smc_result)
{
    uint8_t data[2];
    if (command != 0x400d && command != 0x400f && command != 0x4010) {
        return false;
    }
    *smc_result = 10;
    if (command == 0x400d) {
        if (payload_pa || payload_size) {
            return true;
        }
        if (!s->initialized) {
            uint8_t *ring = g_try_malloc0(PHILIPS_TS130_RING_SIZE);
            if (!ring) {
                return true;
            }
            s->ring = ring;
            s->ring_read_offset = s->ring_write_offset = 0;
            s->scratch_read_offset = s->scratch_write_offset = 0;
            s->initialized = true;
        }
        /* Repeat init preserves all buffer bytes/cursors, as stock does. */
        philips_ts130_clear_pids(s);
        s->partial_length = 0;
        s->parser_flag = 0;
    } else {
        size_t need = command == 0x400f ? 2 : 1;
        if (!s->initialized || !payload_pa || payload_size < need ||
            payload_size > 64 || payload_pa > UINT32_MAX - (need - 1) ||
            !read_guest || !read_guest(opaque, payload_pa, data, need)) {
            return true;
        }
        if (command == 0x400f) {
            uint16_t pid = data[0] | ((uint16_t)data[1] << 8);
            if (pid == 0x0fff) {
                philips_ts130_clear_pids(s);
            } else {
                if (s->pid_count == PHILIPS_TS130_PID_CAPACITY) {
                    return true;
                }
                s->pids[s->pid_count++] = pid;
            }
        } else {
            /* The recovered reset routine ignores the payload byte. */
            s->scratch_read_offset = s->scratch_write_offset = 0;
            s->partial_length = 0;
            s->parser_flag = 0;
        }
    }
    *smc_result = 0;
    return true;
}
