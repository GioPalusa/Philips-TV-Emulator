/*
 * Optional development-only GLES transport; not an MT5891 hardware model.
 * GPL-2.0-or-later. Included by the Philips virt board implementation.
 *
 * One guest broker serializes transactions. Every host socket is nonblocking:
 * no renderer operation can wait while holding QEMU's global lock.
 * Status values use Linux errno numbers, independent of the host OS.
 */
#include <sys/un.h>
#include <poll.h>
#include "qemu/sockets.h"

#define PHGPU_PAYLOAD_BASE 0xa1000000ULL
#define PHGPU_CONTROL_BASE 0xa1100000ULL
#define PHGPU_CAPACITY (1024 * 1024)
#define PHGPU_CONNECTIONS 64
/* High 16 bits: extension ABI version; low bit 0: OP5 readiness snapshot. */
#define PHGPU_CAPABILITIES 0x00010001u

static struct {
    MemoryRegion payload_region, control_region;
    uint8_t *payload;
    const char *socket_path;
    int fd[PHGPU_CONNECTIONS];
    uint32_t connection, length, command;
    uint64_t readable;
    int32_t status, result;
} phgpu;

static int phgpu_error(void)
{
    return errno == EAGAIN || errno == EWOULDBLOCK ||
           errno == EINPROGRESS || errno == EINTR ? -11 : -5;
}

static void phgpu_command(uint32_t command)
{
    ssize_t result;
    int fd, slot;
    struct sockaddr_un address = { .sun_family = AF_UNIX };
    phgpu.command = command;
    phgpu.status = phgpu.result = 0;
    if (command == 5) {
        /* One serialized broker owns this snapshot. No payload mutation, no
         * waiting under the QEMU global lock, and no connection selector needed.
         * Readable includes EOF/errors so the ordinary READ can close clients.
         */
        struct pollfd fds[PHGPU_CONNECTIONS];
        phgpu.readable = 0;
        for (slot = 0; slot < PHGPU_CONNECTIONS; slot++) {
            fds[slot] = (struct pollfd){ phgpu.fd[slot], POLLIN, 0 };
        }
        int ready = poll(fds, PHGPU_CONNECTIONS, 0);
        if (ready < 0) {
            phgpu.status = phgpu_error();
            return;
        }
        for (slot = 0; slot < PHGPU_CONNECTIONS; slot++) {
            if (fds[slot].revents & (POLLIN | POLLHUP | POLLERR | POLLNVAL)) {
                phgpu.readable |= UINT64_C(1) << slot;
            }
        }
        phgpu.result = ready;
        return;
    }
    if (phgpu.length > PHGPU_CAPACITY) {
        phgpu.status = -22;
        return;
    }
    if (command == 1) {
        /* Forward only the two known goldfish service handshakes. */
        if (!((phgpu.length == sizeof("pipe:opengles") &&
               !memcmp(phgpu.payload, "pipe:opengles", phgpu.length)) ||
              (phgpu.length == sizeof("pipe:GLProcessPipe") &&
               !memcmp(phgpu.payload, "pipe:GLProcessPipe", phgpu.length)))) {
            phgpu.status = -22;
            return;
        }
        for (slot = 0; slot < PHGPU_CONNECTIONS; slot++) {
            if (phgpu.fd[slot] < 0) {
                break;
            }
        }
        if (slot == PHGPU_CONNECTIONS) {
            phgpu.status = -24;
            return;
        }
        fd = qemu_socket(AF_UNIX, SOCK_STREAM, 0);
        if (fd < 0) {
            phgpu.status = phgpu_error();
            return;
        }
        if (fcntl(fd, F_SETFL, O_NONBLOCK) < 0) {
            close(fd);
            phgpu.status = -5;
            return;
        }
#ifdef SO_NOSIGPIPE
        int enabled = 1;
        setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &enabled, sizeof(enabled));
#endif
        pstrcpy(address.sun_path, sizeof(address.sun_path), phgpu.socket_path);
        if (connect(fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
            phgpu.status = phgpu_error();
            close(fd);
            return;
        }
        /* A fresh local stream must accept this <=19 byte handshake whole.
         * Retrying a failed OPEN creates a fresh connection.
         */
        result = send(fd, phgpu.payload, phgpu.length,
#ifdef MSG_NOSIGNAL
                      MSG_NOSIGNAL
#else
                      0
#endif
        );
        if (result != phgpu.length) {
            phgpu.status = result < 0 ? phgpu_error() : -5;
            close(fd);
            return;
        }
        phgpu.fd[slot] = fd;
        phgpu.result = slot + 1;
        return;
    }
    if (!phgpu.connection || phgpu.connection > PHGPU_CONNECTIONS ||
        phgpu.fd[phgpu.connection - 1] < 0) {
        phgpu.status = -9;
        return;
    }
    fd = phgpu.fd[phgpu.connection - 1];
    switch (command) {
    case 2:
        result = send(fd, phgpu.payload, phgpu.length,
#ifdef MSG_NOSIGNAL
                      MSG_NOSIGNAL
#else
                      0
#endif
        );
        break;
    case 3:
        result = recv(fd, phgpu.payload, phgpu.length, 0);
        if (result > 0) {
            memory_region_set_dirty(&phgpu.payload_region, 0, result);
        }
        break;
    case 4:
        close(fd);
        phgpu.fd[phgpu.connection - 1] = -1;
        result = 0;
        break;
    default:
        phgpu.status = -22;
        return;
    }
    if (result < 0) {
        phgpu.status = phgpu_error();
    } else {
        phgpu.result = result;
    }
}

static uint64_t phgpu_read(void *opaque, hwaddr address, unsigned size)
{
    switch (address) {
    case 0: return phgpu.command;
    case 4: return (uint32_t)phgpu.status;
    case 8: return phgpu.connection;
    case 12: return phgpu.length;
    case 16: return (uint32_t)phgpu.result;
    case 20: return 0x50484750;
    case 24: return PHGPU_CAPACITY;
    case 28: return PHGPU_CAPABILITIES;
    case 32: return (uint32_t)phgpu.readable;
    case 36: return (uint32_t)(phgpu.readable >> 32);
    default: return 0;
    }
}

static void phgpu_write(void *opaque, hwaddr address, uint64_t value,
                        unsigned size)
{
    switch (address) {
    case 0: phgpu_command(value); break;
    case 8: phgpu.connection = value; break;
    case 12: phgpu.length = value; break;
    }
}

static const MemoryRegionOps phgpu_ops = {
    .read = phgpu_read,
    .write = phgpu_write,
    .endianness = DEVICE_LITTLE_ENDIAN,
    .valid = { .min_access_size = 4, .max_access_size = 4,
               .unaligned = false },
    .impl = { .min_access_size = 4, .max_access_size = 4 },
};

static void philips_hostgpu_init(MemoryRegion *sysmem)
{
    const char *path = getenv("PHILIPS_HOSTGPU_SOCKET");
    if (!path || !path[0]) {
        return;
    }
    if (path[0] != '/' ||
        strlen(path) >= sizeof(((struct sockaddr_un *)0)->sun_path)) {
        error_report("PHILIPS_HOSTGPU_SOCKET must be a short absolute Unix path");
        exit(1);
    }
    phgpu.socket_path = g_strdup(path);
    for (int i = 0; i < PHGPU_CONNECTIONS; i++) {
        phgpu.fd[i] = -1;
    }
    memory_region_init_ram(&phgpu.payload_region, NULL, "philips.hostgpu-payload",
                           PHGPU_CAPACITY, &error_fatal);
    phgpu.payload = memory_region_get_ram_ptr(&phgpu.payload_region);
    memory_region_add_subregion_overlap(sysmem, PHGPU_PAYLOAD_BASE,
                                       &phgpu.payload_region, 20);
    memory_region_init_io(&phgpu.control_region, NULL, &phgpu_ops, NULL,
                          "philips.hostgpu-control", 4096);
    memory_region_add_subregion_overlap(sysmem, PHGPU_CONTROL_BASE,
                                       &phgpu.control_region, 20);
    fprintf(stderr, "[philips hostgpu] optional GLES transport enabled\n");
}
