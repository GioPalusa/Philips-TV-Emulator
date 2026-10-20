# Demux initialization bottleneck — development record

Investigation date: 2026-10-20. Target: Philips 55OLED803/12, stock 107.1.143.0 software in the local emulator. No physical TV changes were made.

## Observation and diagnosis

After host GPU rendering and bulk SD-card transfers were working, Android CPU snapshots still showed `/vendor/bin/MtkRmServer` using 39–96% of one guest CPU almost entirely in kernel mode. SurfaceFlinger was about 0.1%; `mmcqd/0` had fallen to about 0.6%. These are samples during startup, not a steady-state benchmark.

Run `ui/runs/20261020-190533-6aac4f/qemu.log` recorded an escalating missing-device poll:

```
[mt5891 polling read] 0xf00170c0 count=536870912 pc=0xbf3c39c4
[mt5891 polling read] 0xf00170c0 count=1073741824 pc=0xbf3c39c4
```

The exact shipped module symbol table maps that PC to `_DMX_EnableFTI+0x60` (module text base `0xbf000000`). The instruction reads demux control `0xf00170c0`; the loop waits for bit 30 to become set after requesting halt by setting bits 31 and 24. Unimplemented MMIO returned zero forever. This is a missing device handshake, not useful CPU work.

Early SELinux `upg_device` denials were considered as an alternative explanation. They appeared only during initialization. The repeated PC and MMIO address identify a concrete later kernel loop; the model does not change SELinux permissions.

## Evidence chain

| Artifact | SHA-256 | Relevant evidence |
| --- | --- | --- |
| `MtkRmServer` | `1546bdfbe453cd773469eaf489772b2bb9a7e8f86a8fe93f69bc32cd7e8779db` | Embedded `.gnu_debugdata` identifies `main` and `MtkRmServiceInit`; initialization calls MTAL and DMX before publishing the service. |
| `libmtal.so` | `b2939a08ac5e342508c3d52359a735fe821db41b8fe17589ab111af651cb514c` | `MTDMX_Init` performs ioctl `0x4004021f` after callback setup. |
| `dtv_driver.ko` | `7940711a633ab2804812edc6bb0bd6200908f7f3fd0927cbbd3664fb438d5a53` | `_DMX_EnableFTI` at 0x3c3964; `_DMX_ResetFTuP` at 0x3c38c8; `_DMX_LoadIMem` at 0x3c4c08; `_DMX_Reset` at 0x3c4b1c. |

REA observations:

- `main`: `ev_9bdf29da9aff4e616c1cae341b5bff4283bcc49726f51bfae7336f16839e5457`
- `MTAL_Init`: `ev_c3cdc9844625d5d7584199fed6eea4d9fc1e7cad7fde26fb8c4fa36a4b50474a`
- `OpenMtalDeviceHandle`: `ev_368aef54eaa1c4ff204ef029559d61534f4f0ef7eda778297d0f8379ffd1e9bf`
- `SC_InitLib`: `ev_e24d06808e219a9a940f88708383fc665d8cbbad98689f44e0d3712e1bcc932a`
- `MTDMX_Init`: `ev_7cacaa96fb8c36b55a807d734e8feed138a89b8d2312bc3414e80dfa82409e2c`

REA/Hopper timed out while starting analysis of the large kernel module. Module instructions were therefore checked directly with GNU ARM `objdump -dr` against its ELF symbols and relocations. Exact command outputs are retained under `work/philips-rm/dmx-ftu-control.asm` `dmx-imem-load.asm`, and `dmx-reset.asm`. The module conclusions are direct disassembly observations, not a claimed successful REA decompilation.

## Modeled behavior

Four register words are modeled. All other demux addresses continue through missing-MMIO diagnostics.

| Physical address | Behavior |
| --- | --- |
| `0xf00170c0` | Halt request bit 31 drives device-owned acknowledgment bit 30. Ack remains set while the driver clears bit 24 and drains queues; releasing bit 31 clears ack. The stock reset pulse does not discard uploaded instruction RAM. |
| `0xf0017000` | Verified FTI command `01` in bits 31:30 transitions status bits 29:28 to `01`; start command `00` clears status. Reset command `10` (stock write `0x8f000000`) enters halted status while preserving uploaded RAM. Command `11` retains prior status. |
| `0xf001700c` | Full-word instruction-memory command: high 16 bits select word; low 16 bits `0x201` writes, `0x101` reads. Successful operations clear busy bits 11:8. Other command encodings are not reported as complete. |
| `0xf0017010` | Instruction-memory data latch. Readback returns the actual word previously uploaded. |

The driver uploads 5600 words, then checks every word before continuing. Storage is backed by a 65536-word array covering the command's 16-bit index field. This capacity follows the observed port field width; silicon RAM capacity is not independently established.

Control completion is synchronous because this model has no packet processing in flight. It does **not** execute FTI microcode, decode transport streams, emulate demux DMA, implement tuners, or synthesize demux interrupts. Real device timing and undocumented command semantics remain unknown.

## Implementation and checks

Source: `philips-demux.inc`; standalone checks: `test_demux.c` and `test-stubs/system/reset.h`.

```
cc -std=c11 -Wall -Wextra -Werror -fsanitize=address,undefined \
  -Iwork/philips-rm/test-stubs work/philips-rm/test_demux.c \
  -o work/philips-rm/test_demux
work/philips-rm/test_demux
```

Result:

```
PASS demux halt/start/reset, 5600-word upload/readback, boundaries, unsupported commands, lanes
```

Tests use distinct data per word, check address 0 versus 0xffff, verify that unknown commands do not appear complete, and ensure unsupported addresses are not intercepted. The tests also verify that guest writes cannot forge device-owned status, including byte writes.

Integration hooks are `philips_demux_read`, `philips_demux_write`, and `philips_demux_init`. The parent task owns board integration, QEMU build and live validation. At the time this report was written, the isolated model passed its checks; a successful complete TV boot and measured speed improvement with this model had not yet been established.

## Chronology

1. Host GLES commands reached ANGLE Metal and passed actual red-clear/green-triangle pixel checks.
2. SD-card transfer profiling found excessive per-byte block-layer work; fixing it removed the previous `mmcqd` CPU hotspot.
3. Remaining startup CPU samples isolated `MtkRmServer`, a userspace process spending time in the vendor kernel driver.
4. Missing-MMIO trace counters identified over one billion reads of the same demux control word.
5. Exact module symbols and disassembly identified the halt acknowledgment loop.
6. A minimal two-register handshake model was written and sanitizer-tested.
7. Following the initialization path exposed the instruction-memory upload/readback requirement; the model was extended to store actual uploaded words rather than fake verification success.
8. The four-register model and tests were handed to the parent task for integration and runtime measurement.

## First integration result: later dependencies exposed

Run `ui/runs/20261020-192007-df77ee` integrated the four-register model. The former FTI halt loop completed (`Normal break FTI`), instruction loading progressed, and the driver reached `Stc Hw init done!` and `Psi Buff init 0x371e0000`. This validates progress past the original busy loop, but not complete demux operation.

`MTDMX_Init` subsequently returned `-1`. Exact code narrows the failure:

1. `_DMX_PSIBufferInit` calls `dlmem_init`, whose inspected implementation always returns `1`.
2. The next and final `_DMX_Init` stage is `_DMX_TS130_Init`.
3. Its first operation is `TZ_DMX_TS130_Init`, invoking SMC with `r0=0x545a3330`, `r1=0x400d`, `r2=r3=0`.
4. `_TZ_CTL` accepts only a zero SMC return as success. QEMU's active internal PSCI implementation does not implement this MediaTek TrustZone service. This launch uses `virtualization=on`, selecting the SMC conduit. `arm_handle_psci_call` rejects the value as an unsupported AArch32 call (its bit30 is set), returning `-1`; the wrapper therefore reports failure.

This is an unsupported secure service, not another demux MMIO completion flag. No success constant or security-service bypass was added. The parent task will keep this demux model opt-in while the dependency remains unresolved.

Separately, at guest time46.766s the kernel panicked in `msdc_irq+0x230`, PC `0xc0395784`, with pending status `r6=0x7008` and a null request pointer. The stack identifies the storage interrupt handler; it is not a demux stack. Storage interrupt ordering/error handling requires its own investigation. The run does not establish that this panic is caused by the demux model.

Current status: the original demux busy loop and instruction-port data transfer are implemented and tested. Full demux initialization and TV-equivalent performance are not achieved.

## Enabling the experimental control plane

The integrated QEMU build keeps this model **disabled by default**. Set
`PHILIPS_DEMUX_CONTROL=1` before launching QEMU or the viewer to exercise it.
The stock path subsequently requires the unimplemented MediaTek secure service
described above, so the option does not establish a working tuner/TV pipeline.
