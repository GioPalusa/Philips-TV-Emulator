static void (*registered_reset)(void *);
static void qemu_register_reset(void (*fn)(void *), void *opaque)
{ (void)opaque; registered_reset=fn; }
