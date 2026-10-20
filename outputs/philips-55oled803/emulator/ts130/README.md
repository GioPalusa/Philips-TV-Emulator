# MediaTek TS130 control services

2026-10-20 — Philips 55OLED803/12, firmware 107.1.143.0. This is a limited emulator implementation derived from the supplied TrustZone firmware. No physical TV changes were made.

## Why this exists

The demux control-register model lets the stock driver complete its FTI halt and microcode upload. Its next dependency is MediaTek SMC service `0x545a3330`, command `0x400d`. The generic QEMU PSCI handler rejects that vendor call. In the demux-only trial, MtkRmServer fell from 81.38% CPU to 0%, but native `dtv_svc` then consumed 76.06% CPU after demux initialization aborted. Removing the first polling loop alone therefore did not solve the vendor-service stall.

The actual `tzbp` partition was extracted from the locally reconstructed stock eMMC image and decompressed using the LZHS implementation from [epk2extract](https://github.com/openlgtv/epk2extract/tree/2b6af078b56dbedb89efc0f4943036150f1ecae9). The output is 1,003,520 bytes and its checksum is `0x14`, matching the header. It contains ARM code loaded at `0x7d005000`. See `evidence.json` for hashes and precise function ranges. Firmware binaries are not included in this package.

## Observed service behavior

| Command | Stock routine address | Behavior |
| --- | --- | --- |
| `0x400d` | `0x7d060310` | On first call, allocate 128 KiB, align internal pointers, initialize ring/scratch pointers and set the initialized flag. Every call fills 96 PID slots with `0xffff`, clears PID count, partial length and parser flag. Repeated calls preserve allocation, buffer bytes and existing cursor values. Allocation failure returns false. |
| `0x400f` | `0x7d0608a8` | Read a little-endian 16-bit PID from the request. `0x0fff` clears the PID list. Otherwise append up to 96 entries; a full list fails. `0xffff` is accepted as an ordinary value; no extra PID validity filter is imposed. |
| `0x4010` | `0x7d06092c` | Ignore the supplied byte. Reset the two scratch cursors, partial length and parser flag. Preserve PID list/count and ring buffer. |
| `0x400e` | `0x7d060450` | Packet processing exists in stock firmware but is **not implemented** by this model. |

The firmware dispatcher at file offset `0x5eea4` selects these routines; its common result path at `0x5f564` converts a true internal result to SMC return `0`, and false to `10`. These control routines themselves perform no device MMIO or cryptography.

The normal-world `dtv_driver.ko` wrappers confirm the request ABI: `BSP_AllocAlignedDmaMemory` returns a physical address; `VIRTUAL` is used separately for CPU access/cache synchronization. `_TZ_CTL` sends the physical buffer address in `r2`, command in `r1`, and buffer length in `r3`. PID and reset requests allocate and send 64 bytes. Init sends address and length zero. Only the first two bytes (PID) or first byte (reset) are used.

## Implementation and boundaries

`philips-ts130.inc` owns a 128 KiB buffer, PID list and parser cursor/state fields. Internal secure-world pointers are represented as offsets into owned buffers. It returns success after performing the observed state changes. It does not load a complete TEE, handle secure storage or DRM, execute demux microcode, or parse transport-stream packets.

Initialize `PhilipsTs130State` to zero. Call `philips_ts130_reset` on machine reset/shutdown to free the buffer and clear state. Route only AArch32 MediaTek service `0x545a3330`, with commands `0x400d`, `0x400f`, `0x4010`, and only behind the explicit experimental profile flag. Unknown commands return `false` without modifying the output/result or state so existing unsupported handling remains in control.

The guest-memory callback is:

```c
bool read_guest(void *opaque, uint32_t physical_address,
                void *buffer, size_t length);
```

The board adapter must validate normal guest RAM and use the QEMU address-space API. It must not trigger MMIO accesses by accepting an arbitrary payload address. Calls must be serialized across vCPUs because the state is shared.

Additional emulator boundary restrictions are deliberate: init requires a null payload; PID/reset require prior initialization, a readable non-null payload, sufficient length no greater than 64 bytes, and no address wrap. Invalid requests return `10`. These restrictions are tighter than the original trusted kernel-to-TEE calling convention. Buffers are zero allocated in the host implementation; the stock allocator's initial contents are unspecified. The three control operations do not expose those contents.

## Verification

1. `test_ts130.c`: native implementation tests under AddressSanitizer and UndefinedBehaviorSanitizer passed. Covers allocation failure, first/repeated init, 96 PID slots and overflow, clear sentinel, ordinary `0xffff` PID, reset state, preserved data/cursors, invalid memory/length/wrap, and unsupported commands.
2. `ts130_firmware_oracle.c`: executed the **original three ARM routines** in a separate bare-metal QEMU process. Only the allocator entry was redirected to a test allocator, first returning null, then deliberately unaligned memory. The observed aligned pointers, return values, state changes and edge cases match the model. Original buffer and PID storage remained in emulated RAM. This is not an execution of the full secure monitor or TV operating system.
3. REA Hopper was attempted on an ELF wrapper of the raw firmware. It returned an invalid-request error, then provider-unavailable. Exact GNU ARM disassembly and the original-code execution above supplied the usable evidence. No REA decompilation result is claimed. A Unicorn attempt failed before guest execution because its macOS library issued an unsupported `CTR_EL0` read; the successful oracle uses QEMU instead.

From the repository root:

```sh
cc -std=c11 -Wall -Wextra -Werror -fsanitize=address,undefined \
  outputs/philips-55oled803/emulator/ts130/test_ts130.c \
  -o work/philips-rm/test_ts130
work/philips-rm/test_ts130

arm-none-eabi-gcc -Os -marm -mcpu=cortex-a9 -ffreestanding \
  -fno-builtin -nostdlib -Wl,-Ttext=0x40010000,-e,_start \
  outputs/philips-55oled803/emulator/ts130/ts130_firmware_oracle.c \
  -o work/philips-rm/ts130_firmware_oracle.elf

outputs/philips-55oled803/emulator/qemu-system-aarch64-55oled803 \
  -M virt -cpu cortex-a53,aarch64=off -m 880M -nic none \
  -display none -monitor none -serial none \
  -semihosting-config enable=on,target=native \
  -kernel work/philips-rm/ts130_firmware_oracle.elf \
  -device loader,file=work/philips-rm/tz.bin,addr=0x7d005000,force-raw=on
```

The oracle requires the locally extracted firmware with the hash in `evidence.json`. Its allocator hook modifies only its private emulated-memory copy. Integration into the stock Android boot and resulting CPU/latency improvements require a separate runtime trial; these tests do not establish complete TV functionality or TV-equivalent performance.

## Board routing integration

Set `PHILIPS_TS130_CONTROL=1` together with `PHILIPS_DEMUX_CONTROL=1` to
exercise the experimental subset. The board installs its callback only in that
profile. It recognizes AArch32 service `0x545a3330` and the three implemented
commands before generic PSCI routing. BQL serializes shared state across CPUs.
Payload reads accept normal guest RAM and reject MMIO/RAM devices and wrapped
addresses. Board reset frees the private parser buffer and clears the state.

`test_smc_routing.py` builds a small ARM assembly guest and executes real SMC
instructions in a separate QEMU process. With the flag absent, all vendor
calls retain unsupported results. With it enabled, initialization/PID/reset
succeed after state changes, reset before initialization and MMIO payloads
return 10, unimplemented packet processing stays unsupported, and standard
PSCI version still returns 1.1 in both cases. This verifies routing and bounds;
full Android service readiness remains a separate runtime test.

```sh
python3 outputs/philips-55oled803/emulator/ts130/test_smc_routing.py \
  --binary work/philips-emulator/qemu-11.1.2/build/qemu-system-aarch64
```
