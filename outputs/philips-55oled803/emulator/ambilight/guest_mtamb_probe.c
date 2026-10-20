/*
 * Freestanding ARM Linux diagnostic for the isolated emulator.
 * Default: read mode only. --synthetic-mode8: run mode 8 for two seconds,
 * then restore the original mode. Never deployed to the physical TV.
 * --enable-mode8: explicit development profile, leaves mode8 enabled.
 *
 * ABI evidence: libmtal.so MTAMB_SetMode 0x1f0dc and GetMode 0x1f170;
 * GetMode passes a pointer to a 32-bit pointer, not the result buffer itself.
 */
typedef unsigned int u32;
typedef signed int i32;

static i32 syscall3(u32 number, u32 a, u32 b, u32 c)
{
    register u32 r0 __asm__("r0") = a;
    register u32 r1 __asm__("r1") = b;
    register u32 r2 __asm__("r2") = c;
    register u32 r7 __asm__("r7") = number;
    __asm__ volatile("svc #0" : "+r"(r0) : "r"(r1), "r"(r2), "r"(r7) : "memory");
    return (i32)r0;
}

static void print(const char *s)
{
    u32 length = 0;
    while (s[length]) ++length;
    syscall3(4, 1, (u32)s, length);
}

static void hex(u32 value)
{
    char text[12] = "0x00000000\n";
    const char *digits = "0123456789abcdef";
    for (u32 i = 0; i < 8; ++i) text[2+i] = digits[(value >> (28-i*4)) & 15];
    syscall3(4, 1, (u32)text, 11);
}

static int equal(const char *a, const char *b)
{
    while (*a && *a == *b) { ++a; ++b; }
    return *a == *b;
}

static i32 read_mode(i32 fd, u32 *mode)
{
    u32 pointer = (u32)mode;
    return syscall3(54, fd, 0x40043001, (u32)&pointer);
}

#ifdef MTAMB_DIAGNOSTIC_STATUS
/* Read-only diagnostics, independently verified against libmtal.so:
 * GetBrightness 0x20608, GetFreeze 0x20f98, GetMeasuredPixel 0x203ac,
 * GetProcessedPixel 0x204dc. Scalar getters take pointer-to-pointer;
 * pixel getters take {index, pointer-to-three-u32}.
 */
static void inspect_state(i32 fd)
{
    u32 value = 0, pointer = (u32)&value;
    print("Brightness getter result: ");
    hex((u32)syscall3(54, fd, 0x4004301d, (u32)&pointer));
    print("Brightness value: "); hex(value);
    value = 0;
    print("Freeze getter result: ");
    hex((u32)syscall3(54, fd, 0x4004302e, (u32)&pointer));
    print("Freeze value: "); hex(value);
    u32 rgb[3] = {0xffffffff, 0xffffffff, 0xffffffff};
    u32 argument[2] = {1, (u32)rgb};
    print("Measured pixel 1 getter result: ");
    hex((u32)syscall3(54, fd, 0x40083015, (u32)argument));
    print("Measured pixel 1 RGB raw:\n");
    hex(rgb[0]); hex(rgb[1]); hex(rgb[2]);
    rgb[0] = rgb[1] = rgb[2] = 0xffffffff;
    print("Processed pixel 1 getter result: ");
    hex((u32)syscall3(54, fd, 0x4008301b, (u32)argument));
    print("Processed pixel 1 RGB raw:\n");
    hex(rgb[0]); hex(rgb[1]); hex(rgb[2]);
}
#else
static void inspect_state(i32 fd) { (void)fd; }
#endif

__attribute__((used)) static int probe(u32 argc, char **argv)
{
    int run = argc == 2 && equal(argv[1], "--synthetic-mode8");
    int enable = argc == 2 && equal(argv[1], "--enable-mode8");
    if (argc != 1 && !run && !enable) {
        print("Usage: guest_mtamb_probe [--synthetic-mode8 | --enable-mode8]\n");
        return 2;
    }
    i32 fd = syscall3(5, (u32)"/dev/mtal", 2, 0);
    if (fd < 0) fd = syscall3(5, (u32)"/dev/mtal_system", 2, 0);
    if (fd < 0) {
        print("MTAL open failed: "); hex((u32)fd); return 3;
    }
    u32 original = 0xffffffff;
    i32 result = read_mode(fd, &original);
    if (result < 0 || original == 0xffffffff) {
        print("MTAMB_GetMode failed: "); hex((u32)result);
        syscall3(6, fd, 0, 0); return 4;
    }
    print("Original mode: "); hex(original);
    inspect_state(fd);
    if (run || enable) {
        u32 mode = 8;
        if (enable) {
            print("Development emulator profile: enabling mode 8 persistently for this boot.\n");
        } else {
            print("Synthetic emulator diagnostic: requesting mode 8 for two seconds.\n");
        }
        result = syscall3(54, fd, 0x40043000, (u32)&mode);
        print("SetMode result: "); hex((u32)result);
        if (result >= 0) {
            u32 observed = 0xffffffff;
            i32 read_result = read_mode(fd, &observed);
            print("Mode readback result: "); hex((u32)read_result);
            print("Mode during diagnostic: "); hex(observed);
            if (enable) {
                print("Mode remains enabled until changed by the guest or this emulator boot ends.\n");
                syscall3(6, fd, 0, 0);
                return read_result < 0 || observed != 8 ? 6 : 0;
            }
            struct { i32 seconds, nanoseconds; } delay = {2, 0}, remaining = {0, 0};
            while (syscall3(162, (u32)&delay, (u32)&remaining, 0) == -4) {
                delay = remaining;
            }
            inspect_state(fd);
            result = syscall3(54, fd, 0x40043000, (u32)&original);
            print("Restore original mode result: "); hex((u32)result);
            observed = 0xffffffff;
            read_result = read_mode(fd, &observed);
            print("Restore readback result: "); hex((u32)read_result);
            print("Mode after restore: "); hex(observed);
            if (result < 0) {
                syscall3(6, fd, 0, 0); return 5;
            }
        }
    }
    syscall3(6, fd, 0, 0);
    return result < 0 ? 6 : 0;
}

__asm__(".global _start\n"
        "_start:\n"
        "ldr r0, [sp]\n"
        "add r1, sp, #4\n"
        "bl probe\n"
        "mov r7, #1\n"
        "svc #0\n");
