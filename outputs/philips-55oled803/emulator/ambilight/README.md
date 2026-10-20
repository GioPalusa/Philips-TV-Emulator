# Ambilight emulation development

Status: the stock firmware's API and software-driven SPI output boundaries have
been recovered. An initial register model and decoder have been implemented.
QEMU integration has passed the SPI and measurement/VSync tests below. Stock
firmware registers and handles the shared video interrupt. **The stock algorithm
now produces a changing, nonblack SPI response to synthetic red measurement
input.** The response rises while mode 8 runs and decays after restoring mode 0.
These runs use synthetic configuration and input peripherals. A match to the
physical panel remains unverified. The viewer starts empty; its supplied
recording contains actual guest output.

## Verified colored response

In `framework-software`, the development service successfully ran the helper
under the existing `mt_dtv-svc` domain while SELinux remained enforcing. Readback
confirmed mode 0 initially, mode 8 during the two-second diagnostic, then mode 0
after restoration. The service exited successfully.

The captured response contains 62 nonblack frames, sequences 629–690. Peak frame
643 has 17 active wire positions, matching the synthetic 4+9+4 geometry, with
raw RGB `[33286,13784,8934]`. Taking each channel's high byte gives display RGB
`[130,53,34]`. The input was constant raw red `[65280,0,0]`; the resulting warm
color reflects the shipped processing and default tuning, not a direct copy
of the input. Physical brightness and color calibration are unverified.

- Open `viewer.html`, then **Load recorded firmware response** to inspect the
  peak and play or scrub the captured rise and decay.
- `stock-red-response.spi.jsonl` contains the 81-frame excerpt around the
  transition; `stock-red-response-evidence.json` records its hash and conditions.
- `stock-red-peak.pixels.jsonl` is the decoded peak frame.
- `verified-red-capture.js` contains only data derived from that excerpt.

Green and blue comparison runs remain pending. An optional framebuffer sampler
has now passed portable and real-QEMU integration tests; its stock-firmware response
is awaiting an end-to-end run.

## Earlier black-output runs

The `ambilight-probe` and `ambilight-probe2` runs each produced complete 196-byte
packets with seven hardware-0 groups and 28 wire pixels. All RGB channels are
zero; the current-control fields decode as `[112,127,64]`. The guest wrote these
packets through the emulated SPI controller. Neither diagnostic helper executed:
the first deployment was denied access to its destination directory; the second
was denied read access to the source asset. The transfers therefore originated
from ordinary stock-firmware processing, without the proposed mode-8 diagnostic.

Both runs used the explicit synthetic geometry profile, measurement fixture and
VSync fixture. This established firmware execution and transport; the subsequent
mode-8 diagnostic above established a nonblack response.

- `stock-firmware-spi-evidence.json`: counts, conditions and capture hashes.
- `stock-firmware-spi-black.jsonl`: all 596 raw transfers from the second run.
- `stock-first-frame.pixels.jsonl`: the first decoded frame, suitable for loading
  into `viewer.html`; it displays the actual black output in wire order.

## What the firmware actually does

The observed chain is:

`AmbilightManager Binder service → libambilight.so → libmtal.so MTAMB_* → ioctl(/dev/mtal) → kernel/hardware`

The service name and device paths were read from this TV on 2026-10-20. The
native library analysis used:

| Artifact | SHA-256 |
| --- | --- |
| `libambilight.so`, existing TV extraction | `d20570babc64d9dc4d4547f2921bfdf256c7196fec8e3d587d58d653bc1a9525` |
| `/system/vendor/lib/libmtal.so`, copied read-only from TV | `b2939a08ac5e342508c3d52359a735fe821db41b8fe17589ab111af651cb514c` |
| `basic/dtv_driver.ko`, extracted from stock linux_rootfs | `7c9beee7c57ce276357eb4ee8a031ea3c8e5eebd42230df5b073ae557633bea9` |

`OpenMtalDeviceHandle` opens `/dev/mtal` read/write, with `/dev/mtal_system`
as its fallback. Live device entries are symlinks into `/linux_rootfs/dev`.
These names do not establish the hardware bus: they are the driver API.

The driver is `basic/dtv_driver.ko`, a 13,285,104-byte ARM32 relocatable ELF
module in the stock Linux rootfs SquashFS. Its symbols include `mtal_ioctl_mtamb`
and the proprietary Ambilight algorithm. The exact module was extracted
read-only from the installed virtual disk because live ADB cannot read it.

## Recovered pixel ABI

The ABI is ARM32 little endian. The ioctl argument is eight bytes:

```c
struct mtamb_pixel_arg {
    uint32_t pixel;      // observed callers pass 1-based uint8 values
    uint32_t rgb_ptr;    // pointer in guest userspace
};
struct mtamb_rgb {
    uint32_t red;
    uint32_t green;
    uint32_t blue;
};
```

| Operation | ioctl request | Observed library address |
| --- | --- | --- |
| Set static pixel | `0x40083010` | `libmtal.so:0x1fe54` |
| Get static pixel | `0x40083011` | `libmtal.so:0x1feec` |
| Set measured pixel | `0x40083014` | `libmtal.so:0x20314` |
| Set processed pixel | `0x4008301a` | `libmtal.so:0x20444` |
| Get processed pixel | `0x4008301b` | disassembled/decompiled by symbol |

`libambilight.so`'s static-pixel worker at `0x28e24` shifts each application
channel left eight bits before calling `MTAMB_SetStaticPixel`.
`AlCommon_getProcessedPixelArray` at `0x28758` reads one-based pixels and shifts
the three returned 32-bit channels right eight bits. This supports displaying
that API's values using `channel >> 8`; it does not establish panel calibration,
gamma, the hardware's full numeric range, or physical LED order.

The application array storage is 432 bytes (36 RGB triplets). This is a buffer
capacity observation, **not a measurement of this panel's physical LED count**.
`MTAMB_GetConfiguration` uses request `0x4010300f` with four ARM32 pointers.
Actual configuration values still need capture.

The Binder proxy for processed pixels uses transaction `0x1d` (29).
It resets its parcel position to zero and writes the requested count there,
overwriting the beginning of its interface-token parcel. A normal `service call`
command does not reproduce that unusual layout automatically. No guessed Binder
transactions were sent to the TV.

## Components

- `mtamb.py`: callback-based decoder and state at the recovered ioctl boundary.
  Its guest-memory adapter must safely translate guest **virtual** addresses.
  It emits `mtamb-pixel-v1` JSONL records. It keeps static, measured and processed
  streams separate; unknown processed values and unknown requests fail visibly.
- `viewer.html`: loads those records and displays the latest values as numbered
  swatches. This does not assume an unverified physical LED arrangement.
- `test_mtamb.py`: verifies the recovered argument layout, channel conversion,
  round-trip state and rejection of fabricated processed output.
- `static-evidence.json` and `evidence-*.json`: REA/Hopper static observations
  with original evidence IDs and disassembly/pseudocode limitations.
- `mt5891_ambilight_spi.h` / `.c`: independent C core for QEMU MMIO integration.
  The caller maps the register range and supplies a raw-transfer callback.
- `decode_spi.py`: validates and decodes the hardware-0 28-byte SPI group
  format, emitting colors in wire order for the viewer. Other formats fail.
- `driver-evidence.json` and `driver-disassembly.S`: exact module evidence.
  GNU objdump output retains relocations and branch instructions that Hopper's
  procedure view can omit; zero-valued symbols in its pseudocode are not
  reliable variable names for this relocatable module.

Run the focused tests:

```sh
cd /Users/palusa/Documents/Codex/2026-10-20/my/outputs/philips-55oled803/emulator/ambilight
python3 -m unittest discover -p 'test_*.py' -v
```

The tests use synthetic input to check the decoder. They do not prove that
Android, AmbilightManager, the proprietary algorithm or real LEDs ran.

## QEMU hardware integration

The exact module's software path is:

`IMamb_Fms_Execute → amb_computeMeasurements → amb_computeAlgorithms →
amb_computeDriver → amb_getOutputBuffer → IMambR_WriteSPI →
vDrvAmbiLitBatchWriteCmd → vDrvLcdimSpiSendDataSWModeMbyN`.

The last function writes the following register range:

| Address | Evidence-backed behavior |
| --- | --- |
| `0xf0029400` | Write zero before loading FIFO |
| `0xf0029404`, low 10 bits | Driver checks zero to permit FIFO access |
| `0xf0029408` | Each 32-bit write carries one byte, loaded with `LDRB` |
| `0xf0029440`, bits 4–11 | M transfer dimension |
| `0xf0029442`, bits 4–11 | N transfer dimension |
| `0xf002944c`, bit 0 | Software transfer start |
| `0xf002944c`, bit 1 | Software path clears this before transfer |
| `0xf002944c`, bit 5 | Driver polls until set, then reports ready |

Map `MT5891_AMB_SPI_BASE`, length `MT5891_AMB_SPI_SIZE`, and forward offset,
value and access width to the C core. The callback receives actual collected
guest bytes, sequence, M, N, and whether the captured size equals M×N.
Synchronous completion, self-clearing start and initial ready state are explicit
model choices; timing, hardware mode, multi-burst operation and unknown registers
are not yet emulated. Raw payloads must be retained even when decoding fails.

Suggested callback record:

```json
{"schema":"mt5891-ambilight-spi-v1","sequence":1,"complete":true,"data_hex":"..."}
```

`decode_spi.py capture.jsonl > pixels.jsonl` converts recognized hardware-0
packets to the viewer format. `amb_driv_compute` at `0x599f30` writes a four-byte
header beginning `0x96`, followed by four pixels with 16-bit big-endian B,G,R
channels. The four pixels are serialized in reverse order within their group.
The decoder presents **wire order**, retaining current-control header fields
without pretending to model their optical effect. Display conversion uses the
top eight channel bits; gamma, current calibration and wall illumination remain
unmodelled. No claim has yet been made that this specific TV selects hardware
variant 0 at runtime.

The module also includes a hardware-1 bit-packed protocol and an external
NT72334 processor path. Those variants require separate runtime identification
and decoding; they must not be mistaken for hardware-0 packets.

## Video measurement input

`vDrvAmbiLitSysInit` initializes a 32×20 measurement grid. The row ISR reads:

| Address | Observed consumer |
| --- | --- |
| `0xf0027b08` bits 0–4 | Row number |
| `0xf0027b08` bits 5–9 | Per-column metadata |
| `0xf0027b0a`, 16 bits | Channel 0 |
| `0xf0027b0c`, lower/upper 16 bits | Channels 1 / 2 |
| `0xf0034224`, bits 7 / 6 | Row-ready/status flags |
| `0xf003422e`, bits 7 / 6 | Acknowledge pulses |
| `0xf0008035`, bit 2 | Legacy init sets PSCAN enable bit 10; not the registered output handler route |

`_vDrvAmbiLISR` clears BIM interrupt 23. It reads 32 columns into three planar
arrays of 640 unsigned 16-bit samples, then `IMamb_Fms_Execute` consumes those
arrays. The channel conversion and registered interrupt route are established below;
physical sensor scaling and FIFO advancement remain model assumptions. These registers identify the input model needed
to feed video into the original algorithm; generating host colors alone does
not exercise it.

The registered consumer is `_OutputVSyncIsr` (`0x1a4160`), installed for vendor
vector 23 by `VdoMLInit` (`0x1a4424–0x1a4430`). It reads TCON status, consumes
one measurement row on bit 7, and pulses the same acknowledgement register.
It also handles bit 6 through the video output ISR. The vendor-to-Linux IRQ
mapping adds 104; with the emulator GIC mapping this is SPI 95. The separate
legacy `_vDrvAmbiLISR` has no relocation callers in this module. Its init's
PSCAN bit 10 must not be treated as evidence for measurement IRQ routing.

`mt5891_ambilight_measure.{h,c}` implements the observed register reads with a
raw deterministic 3×20×32 fixture. `test_measure.c` checks all 640 sample positions,
acknowledgement and row wrap. The firmware consumes the three raw planes as
red, green and blue respectively. `amb_writeColorGrid` (`0x596228`) shifts each
16-bit sample right by eight before storing its 8-bit color grid. The named
`amb_getRedColorGridNovatek`, `amb_getGreenColorGridNovatek` and
`amb_getBlueColorGridNovatek` accessors identify those three destination planes.
The fixture therefore supplies low-intensity RGB values after that conversion;
this does not establish physical sensor scaling, gamma or panel calibration.
See `measurement-color-disassembly.S`. Advancing the FIFO after the packed
read at `+0x0c` is a model hypothesis. The QEMU wrapper in
`work/philips-ambilight/mt5891_ambilight_measure.inc` is inert unless
`PHILIPS_AMBILIGHT_FIXTURE=1` or `PHILIPS_AMBILIGHT_FRAMEBUFFER=1`; it schedules
one row per millisecond of virtual
time (20 rows × 50 frames/s), stalling when a previous row is still pending.
The model only contributes TCON status bit 7. It preserves bit 6 and other bits,
unless `PHILIPS_VIDEO_VSYNC_FIXTURE=1` is explicitly enabled as well. That second
fixture generates nominal 50 Hz output-VSync events on bit 6, independently of
row backpressure. The two pending sources share IRQ 95 through an OR and have
independent acknowledgements. All other TCON bits remain preserved.

For controlled input experiments, also set
`PHILIPS_AMBILIGHT_FIXTURE_RGB16=65280,0,0` for constant red, `0,65280,0` for
green, or `0,0,65280` for blue. The stock firmware converts these to 8-bit values
by shifting right eight bits. Three decimal or `0x` hexadecimal integers in
`0..65535` are accepted; malformed input aborts startup. The option only applies
when the measurement fixture is explicitly enabled. Without it, the original
deterministic grid is used. These are synthetic measurement inputs, not captured
screen content or direct commands to the emulated LEDs.

`qtest-measure-rgb16.json` records a passing integration test against
`qemu-rgb-fixture`: it checks the opt-in constant values at the actual MMIO
boundary as well as the existing FIFO, VSync and shared IRQ behavior. That test
uses a synthetic ARM loop; the separate stock capture evidence above establishes
firmware execution.

The second fixture is necessary to exercise the ordinary stock processing
schedule: `_OutputVSyncIsr` bit 6 calls `vVdoOutISR`, which releases the video
mainloop semaphore. `DRVCUST_VideoMainloop` calls `IMambP_BackgroundTask` for
modes other than 8; mode 8 instead runs from the separate 20 ms Ambilight thread.
This dependency comes from the driver call graph, not a claim that the display
pipeline has been fully emulated.

## Approximate framebuffer measurements

`mt5891_ambilight_framebuffer.{h,c}` samples the first region of OSD plane 2
from actual guest RAM. It uses the same format-14 descriptor, pitch and RGB byte
selectors as the emulated OSD scanout. Every cell of the 32×20 measurement grid
averages 4×4 evenly spaced samples, then shifts each 8-bit average left eight
bits for the stock measurement consumer. The entire grid is refreshed at row 0;
a frame never contains a mixture of two sampler snapshots.

Enable the explicit development path with:

```sh
PHILIPS_OSD_SCANOUT=1
PHILIPS_AMBILIGHT_FRAMEBUFFER=1
PHILIPS_VIDEO_VSYNC_FIXTURE=1
```

Framebuffer mode rejects simultaneous `PHILIPS_AMBILIGHT_FIXTURE_RGB16` input.
Without either measurement opt-in, the measurement model remains inert. The
framebuffer path uses bounded, RAM-only reads; unsupported formats, compressed
regions, invalid geometry or failed reads produce zero measurements. Changes
between a valid and invalid source are logged. No host-generated LED values
are introduced: measurements enter the stock driver, which runs its algorithm
and writes the captured SPI packets.

This is an **approximation of the measurement hardware**. It samples the raw
first OSD region, without composing video planes or applying display scaling,
mirroring, cropping or later regions. The synthetic 4/9/4 geometry and nominal
50 Hz interrupt timing remain development assumptions. It is not a calibrated
model of the physical TV's light output.

`test_framebuffer.c` passes with address and undefined-behavior sanitizers. It
checks all 640 cells, averaging, padded pitch, swapped byte selectors, a 1×1
frame, invalid descriptors and atomic handling of a failed RAM read.
`qtest_measure_smoke.py --include-framebuffer` adds a real-QEMU test that writes
an OSD descriptor and bitmap into guest RAM, reads the measurement registers,
changes the bitmap, and verifies that the change appears only at the next row 0.
The test passed against `qemu-amb-framebuffer`; the result is saved in
`qtest-measure-framebuffer.json`.
`framebuffer-measurement-evidence.json` records current validation status and
source hashes. End-to-end stock output from changing framebuffer content remains
to be validated separately.

## Posted host-renderer frames

The explicit host graphics profile can additionally set `PHILIPS_HOSTGPU_FRAME`
to its renderer's shared RGBA file. `philips-hostgpu-frame.inc` then supplies the
same measurement grid from posted guest GLES content, before trying the raw OSD
source. It is called only through the existing framebuffer measurement path;
`PHILIPS_AMBILIGHT_FRAMEBUFFER=1` is still required. The resulting samples continue
through the stock driver algorithm and captured SPI transport.

The adapter validates the exact version-1 header, 1920×1080 dimensions, 7680-byte
stride, RGBA8 format and file size. It averages 4×4 sample locations in each of
32×20 cells and ignores alpha. It reads the publication sequence before and after
sampling; an odd or changed sequence does not commit the new grid. The previous
stable grid is retained during concurrent writes. An unchanged publication uses
the cache. Invalid metadata or no published frame permits the existing OSD
fallback.

A new frame needs 10,240 sampled pixel locations and 30,720 color-byte loads;
there is no complete 8 MiB image copy under the QEMU lock. File checks and mmap
page faults can still incur host work. This is an approximation of video
measurement hardware, and the host graphics path translates guest GLES rather
than emulating Mali. The shared file is a trusted local renderer interface and
must keep its size and inode throughout the run. Last-frame retention is not a
freshness guarantee.

Focused ASan/UBSan tests pass for the grid, channel order, averaging, seqlock
change, cached snapshots, format validation, default-off behavior and detected
prior truncation. A read-only probe of the existing renderer file observed a
stable blue frame at sequence 24 / frame count 12. This probe does not execute
the stock Ambilight algorithm. See `hostgpu-frame-evidence.json`; integrated
stock output remains to be validated after the parent QEMU build.

## Verified QEMU capture path

`qtest_spi_smoke.py` has run against the built `qemu-timer-ambi` binary, exercising
the actual mapped FIFO, transfer start and ready registers. The emitted JSONL
contained the exact synthetic bytes and decoded to the expected channel values.
`qtest-spi-smoke.json` records this result. This validates the QEMU capture path;
the test does not boot Android or run the stock Ambilight processing algorithm.

`qtest_measure_smoke.py` exercises the integrated measurement registers using
a one-instruction ARM loop to advance virtual time under TCG.
`qtest-measure-smoke.json` records the passing run on `qemu-vsync-console`:
default-off, measurement-only, and measurement plus VSync. The combined test
verifies actual GIC SPI 95 pending state, independent acknowledgement of both
sources, and continued VSync events while a row is pending. It does not execute
the stock guest interrupt handler.

## NVM support gate and optional development geometry

The stock emulator boot reached `IMamb_Eng_Create` and printed
`Not support Ambilight!`. Exact assembly in `nvm-disassembly.S` shows the gate:
**NVM byte `0x464` equals zero**. The read maps to `mmcblk0p26` (`nvm`);
`DRVCUST_InitQuery64(0x1ff)` returns partition index 25 and `MSDCPART_Read` adds
one. Device-specific NVM was not present in the firmware reconstruction.

| Source | Field |
| --- | --- |
| `0x464`, bits 0–2 | Side segments |
| `0x464`, bits 3–6 | Top segments |
| `0x464`, bit 7 plus `0x465`, bits 0–2 | Bottom segments |
| `0x465`, bits 3–4 | Topology version |
| `0x465`, bits 5–7 | Hardware selection |
| `0x466`, bits 6–7 nonzero | Mirror/flip correction enabled |

`nvm_options.py` decodes only those three supplied hexadecimal bytes. The
compiled architecture table contains 24 tuples. Lookup falls back to index 10,
`[side=4, top=9, bottom=0, topology=1]`, if no tuple matches. Flash tuning data can
replace this table. No table entry has been confirmed as this physical TV's
topology.

`create_synthetic_profile.py SOURCE DESTINATION` creates an independent APFS
clone of the pristine reconstructed disk and writes only `4c 08` at NVM
`0x464..0x465`. It refuses existing outputs, nonempty source NVM, block devices,
and mismatched disk sizes. A manifest explicitly labels the result as a
synthetic development profile. The original image remains unchanged.
This profile must never be flashed onto a physical TV.

Static inspection of `EEPROM_Init`, the MSDC initialization routine, and the
direct Ambilight option read path found no checksum validation or storage erase.
`vApiEepromDefaultInit` writes only a small set of low offsets (`0x6c..0x95`).
Other initialization code can still change NVM at runtime; a successful profile
creation alone does not demonstrate a running Ambilight algorithm.

An isolated boot of the synthetic geometry clone subsequently reached
`IMamb_Fms_SetArchitecture`, selected the expected 4/9/4/0 geometry and enabled
SPI. The log's zero input alignment values do **not** mean the resulting
calibration is zero: `amb_setAlignments` (`0x597f90–0x59801c`) replaces an
all-zero matrix with compiled coefficients and a zero gain with 200. The printed
`nbrOfPhysicalPixels=0` is also not used by the hardware-0 packet serialization;
that path uses the board-map sentinel. Compiled architecture index 10 contains
seven groups of four wire pixels, so this specific development configuration
should emit 196-byte packets when processing executes. These are synthetic
configuration facts, not the physical panel's measured wiring.

## Guest diagnostic

`guest_mtamb_probe.c` is a small freestanding ARM Linux program for the isolated
emulator. Its default operation reads the current mode through the shipped
driver's `MTAMB_GetMode` ioctl. The optional `--synthetic-mode8` argument requests
mode 8 for two seconds, then restores the original mode. Mode 8 uses the stock
driver's separate 20 ms processing thread and can help distinguish video
mainloop scheduling problems from SPI output problems. This program has not
been deployed to the physical TV. A successful build alone is not a successful
runtime test.

The diagnostic also reads the mode back immediately after the change and after
restoration. The first serial transfer attempt did not execute the helper:
incoming characters were lost, including the heredoc terminator. A later paced
console session successfully read `/proc/interrupts`; Linux IRQ 127 had 711
events at approximately 147 guest seconds, after video hardware initialization.
That demonstrates guest execution of the shared measurement/VSync interrupt
handler. It does not yet demonstrate completion of the video mainloop or an
Ambilight SPI transfer.

The ioctl ABI is recovered from `libmtal.so`: SetMode is `0x40043000` with a
pointer to a 32-bit value; GetMode is `0x40043001` with a pointer to a 32-bit
pointer to the result buffer.

The later `renderer-test` run successfully executed the helper from
`/data/local/tmp`, but both MTAL opens returned `-13` (`EACCES`). The stock
SquashFS device metadata explains the shell's lack of access: `dev/mtal` is
mode `0660`, owner UID 1013 and GID 1026; `dev/mtal_system` is mode `0660`,
owner UID/GID 1000. The console runs as UID 2000.

`emulator-probe-service.rc` is an optional development-initramfs fragment.
Its separate service uses the same `/sbin/sh` entry point, root
credentials and `mt_dtv-svc` SELinux domain as the shipped `dtv-svc` service.
It delays 120 guest seconds, prints markers, and invokes the diagnostic using
the existing `/system/etc/emulator-assets/amb-probe` asset. No SELinux policy
change is proposed. This path successfully executed in `framework-software`;
the fragment is not a firmware recovery or physical-TV update.

For a persistent development session, `guest_mtamb_probe_enabled` is the
packaged ARM binary of `guest_mtamb_probe.c`, built with `guest_probe.ld`.
Its explicit `--enable-mode8` option sets mode 8, checks the readback, and exits
without restoring the previous mode. The setting lasts until the guest changes
it or reboots. `emulator-ambilight-enabled.rc` invokes this option after 60 guest
seconds using the same existing service credentials and domain. Install this
fragment instead of the diagnostic fragment, never both. The original
`--synthetic-mode8` diagnostic still restores the previous mode after two
seconds. Persistent mode is intended only for an explicitly selected emulator
development profile, and does not alter the physical TV.

## Remaining integration

1. Complete Android startup and run AmbilightManager.
2. Compare controlled green and blue responses with the verified red response,
   using the explicit measurement fixtures and confirmed modes.
3. Validate changing stock-firmware content through the implemented framebuffer
   sampler. Measurement filtering and output-VSync timing remain
   approximations; final SPI packets must continue to come from the guest driver.
4. Recover this panel's configuration, index ordering, calibration and LED
   transport; validate fixed colors, changing video, mute and standby.

For a full stock-kernel machine, the final device model belongs at the hardware
boundary below the driver. An ioctl shim can help validate the application API
earlier, but it alone cannot demonstrate that the original Ambilight algorithm
or hardware driver works.

## Evidence ledger

| Finding | Evidence | Status |
| --- | --- | --- |
| MTAL device open and fallback | `ev_a144cc1c176758cdf748536d6980c4a55d01300a6b64311a634c45bd5f9f6407` plus string bytes at `0x91863` | Observed static code |
| Set-static ioctl argument layout | `ev_1eeb386afbf35cf313c99b3f0abe6d531de57903ea142ff7454186fa354e96f6` | Observed assembly |
| Static channel conversion and iteration | `ev_26f75c75ffb53a1eb1170b32ee9a1d4f06b5cb3b79af187369f7d7d988064fbf` | Observed assembly |
| Processed channel conversion | `ev_19a5de59dbe705348caf41c1f568e3c09cd4fff789d17ad844b0de589e6d6db5` | Observed assembly |
| Processed ioctl | `ev_b7085fc6f2208a49f809be6c8cedb4c20f27d2a8c71b5e5ff5400338f27546d5` | Observed decompilation |
| Configuration pointer ABI | `ev_ac595d5ff37086bab1bd99df2eef3d7770fec8d8483c0c1ebb8b5d6cb1055907` | Observed assembly |
| Processed Binder transaction and parcel layout | `ev_f9f264b77d1657435543d9e3c81e38a36af94d73c8cae1fc82699a6ad738695c` | Observed assembly |
| SPI FIFO, dimensions, start and ready | `ev_b32ec98547e3706febada0d20d484b0cd15308665d1726dee58b593d72cfda76`; GNU disassembly | Observed static code |
| Stock algorithm to SPI output chain | `ev_9ccda6ceb5eaaf7fbd85d35e7405b2cf04d944dd929e4a405cdada38dc1c1239`; GNU relocations | Observed static code |
| Hardware-0 serialization | `driver-disassembly.S`, `amb_driv_compute`, `0x599ef4–0x599fe0` | Observed static code |
| Empty NVM disables Ambilight; option bit layout and partition | `nvm-disassembly.S`; emulator serial log | Static gate plus observed emulator branch |
| QEMU SPI MMIO capture and packet decoding | `qtest-spi-smoke.json` | Executed with synthetic qtest input |
| Registered measurement ISR route | `_OutputVSyncIsr`, `VdoMLInit`, GNU relocation evidence | Observed static code |
| Actual physical topology, runtime-selected variant, real light output | None yet | Unresolved |

All REA observations are static analysis of shipped artifacts. They do not
record execution. The only live operations were read-only library copies,
service listing and directory listings; TV settings were not changed.
