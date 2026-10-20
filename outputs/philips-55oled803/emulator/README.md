# Philips 55OLED803/12 firmware emulator

Development build, 20 October 2026. **The Android framework has reached `sys.boot_completed=1`, displayed the stock boot animation, and acknowledged virtual Home input.** The stock 2021 Linux kernel executes on all four emulated Cortex-A53 cores. Philips' TV driver and Ambilight engine execute. The launcher and vendor TV services still have startup failures; a usable complete TV interface is not yet verified.

The original graphics blocker is captured in [the graphics diagnostic log](evidence/graphics-diagnostic-console.txt): `libGLES_mali.so` fails `eglInitialize`. A separate development profile uses ARM32 SwiftShader, a framebuffer composer, and an allocator compatibility fix. The allocator now uses shared memory that each graphics process can import, resolving the observed SurfaceFlinger crash from an unmapped framebuffer pointer. Actual guest pixel readback and GLSL triangle tests pass. [Captured boot animation](evidence/android-bootanimation.png) shows real guest output.

## Viewer and virtual remote

```sh
python3 /Users/palusa/Documents/Codex/2026-10-20/my/outputs/philips-55oled803/emulator/ui/server.py
```

Open <http://127.0.0.1:8765>. The viewer shows the actual captured guest framebuffer, Ambilight SPI output, boot status, and a virtual remote: arrows, OK, Back, Home, volume and mute. Remote buttons send Android key events over the guest console and report acknowledgments or timeouts. A successful command alone does not prove a visible response. The screen may remain black while the framework is incomplete.

The local server controls only its own emulator process. The included development profile uses software graphics, scoped JIT permissions for two graphics services, synthetic Ambilight geometry, and the stock measured-input Ambilight algorithm. Framebuffer measurements approximate the raw OSD plane; full panel composition and physical LED calibration are not modeled. Boot and remote acknowledgments are recorded in [first boot evidence](evidence/android-boot-complete.json) and [second boot verification](evidence/android-second-boot.json). See [software graphics](software-graphics/README.md) and [profile manifest](development/manifest.json).

## Run on this Mac

```sh
cd /Users/palusa/Documents/Codex/2026-10-20/my/outputs/philips-55oled803/emulator
python3 run.py --seconds 60
```

For the serial shell, use `python3 run.py --console --seconds 0`. Ctrl-C stops the emulator. The guest shell is Android's existing `shell` user, not root. The runner attaches no network interface. Writes go through the emulated MT5891 MSDC controller into a temporary disk overlay, discarded when QEMU exits. The base image is preserved.

The bundled executable is built for this Apple Silicon Mac and depends on Homebrew libraries. `55oled803-boot.log` receives the console and peripheral diagnostics. A timed run ending successfully means QEMU ran for the requested time; it does not certify Android boot completion. Confirm completion inside the guest with `getprop sys.boot_completed`.

## Ambilight development mode

The stock update lacks this TV's unique NVM configuration. With empty NVM, the stock Ambilight driver disables itself. A separate development image can use a geometry entry recovered from the firmware's own fallback table:

```sh
python3 ambilight/create_synthetic_profile.py stock-emmc-107.1.143.0.img development-ambilight.img
python3 run.py --disk development-ambilight.img --ambilight-fixture \
  --ambilight-log ambilight-capture.jsonl --console --seconds 0
```

This geometry is **synthetic**, not a measured copy of the 55OLED803/12 panel configuration. The helper makes an independent APFS clone and changes only two NVM bytes; a manifest records the change. The fixture supplies a deterministic 32 × 20 measurement grid and nominal 50 Hz video timing. The firmware's own Ambilight code runs against those inputs.

The SPI peripheral captures guest transfers at `0xf0029400`. Decode a nonempty capture with:

```sh
python3 ambilight/decode_spi.py ambilight-capture.jsonl > ambilight-pixels.jsonl
```

Open `ambilight/viewer.html` and load the decoded JSONL. The viewer starts empty. Its indexed colors represent SPI wire order; the physical LED placement and calibration remain unverified. An empty capture means no firmware LED output was observed. Synthetic MMIO tests are labeled separately from firmware execution. See [Ambilight evidence and tests](ambilight/README.md).

## Hardware model

| Component | Implemented behavior and limits |
| --- | --- |
| CPU and RAM | Four Cortex-A53 cores in AArch32; secondary-core power/mailbox handoff. Linux memory ranges come from the TV's device tree. Reserved video/DSP buffers and startup SRAM have RAM backing. Physical cache timing and secure-memory protection are not reproduced. |
| Interrupts and timers | Relocated GICv2, stock 24 MHz timer0 counter/comparator, legacy timer counters. The boot ROM handoff is modeled at a higher level. |
| Serial | MediaTek console register interface and optional host terminal connection. Host input is paced at nominal 115200 baud through a bounded queue and the guest FIFO. Peripheral modem peers and full baud/control behavior remain incomplete. |
| eMMC | MSDC command, PIO and DMA paths, descriptor handling, interrupts, reads and optional writes. A card profile disables legacy one-sector reliable writes that trigger a vendor-kernel partial-write bug. Power-loss atomicity is not modeled. |
| Standby controller | Decoded PDWNC mailbox commands and IRQ104/SPI72, with unsupported requests logged. The 8051 firmware is not executed. |
| Audio processor | Reset-ready and decoded lifecycle mailbox responses; enough for `AUD_Init End`. DSP instruction execution, decoding and sound output are absent. |
| Keypad ADC | Idle, full-scale channel readings prevent zero-valued stub registers from generating false OK-button presses. Physical key inputs are not implemented. |
| Graphics | Reset, command queue, packed pixel fills, same-format copies and completion interrupts. Raw OSD plane 2 scanout into a QEMU display. Separate SwiftShader/HWC development adaptation passes guest pixel/shader tests. Mali hardware is not emulated; stable Android TV display remains incomplete. |
| Ambilight | Recovered stock kernel algorithm and actual SPI output capture. Constant-red input has produced nonblack firmware output. Optional raw-framebuffer sampling supplies approximate measurements. Real panel geometry, calibration and full application-driven operation remain unverified. |
| Trusty and other devices | Unsupported secure-monitor calls return errors. USB, tuner, network, clock/PLL and other peripheral behavior is incomplete. |

`[mt5891 missing ...]` identifies accesses without an implemented peripheral model. Hardware readiness does not establish rendering, audio or secure-world fidelity. This emulator cannot validate that a custom update will flash, recover, preserve DRM, or be safe on the physical TV.

## Stock firmware installation

`stock-emmc-107.1.143.0.img` is a sparse 15,634,268,160-byte disk reconstructed from the supplied TPM171E_R.107.001.143.000 update. `partitions.json` contains the measured 32-partition geometry. System, boot/recovery, Linux rootfs, third-party filesystem and included firmware payloads are installed; five writable partitions use Linux 3.10-compatible ext4 features and the update's default files. The [installation report](stock-emmc-107.1.143.0.img.install.json) records source hashes and the filesystem profile.

The standalone `dmverity` partition is empty, but the installed system/rootfs verification metadata is sufficient for the verified mounts observed during boot. NVM, Ambilight-specific calibration, DRM and other device-specific data are absent. This image is not a backup of the TV.

Reproduce the installation:

```sh
python3 install_stock_os.py \
  --firmware '/Users/palusa/Downloads/Philips/55OLED803:12/autorun.upg' \
  --passfile '/Users/palusa/Documents/Codex/2026-10-20/my/work/philips-port/private/passfile.txt' \
  --output ./rebuilt-stock-emmc.img
```

The installer needs `unzip`, `openssl` and `mke2fs`. It reads the update as data, does not execute its scripts, and refuses to overwrite an existing image. The private passfile is not included in deliverables.

`extract_boot.py` preserves the original kernel payload and also emits `kernel-without-dtb.bin`. The latter removes the appended default device tree so QEMU can supply the measured external tree; the kernel code and stock ramdisk are unchanged. The runner restores `vmalloc=650mb` and the measured partition layout. `create_flash.py` remains a geometry-only helper, not a complete OS installer.

## Build the emulator

The patch modifies a dedicated QEMU 11.1.2 `virt` build. It is not a general replacement for QEMU's standard `virt` machine.

Upstream: [QEMU 11.1.2 source](https://download.qemu.org/qemu-11.1.2.tar.xz), SHA-256 `731b5681e4bb18be313231579b8efd0296c5b015fa36dc533874b639ba838016`. Apply `qemu-11.1.2-55oled803.patch` with `patch -p1`, then configure and build:

```text
--target-list=aarch64-softmmu --disable-docs --disable-tools
--disable-cocoa --disable-gtk --disable-sdl --disable-opengl
--disable-spice --disable-vnc --disable-slirp --disable-guest-agent
--disable-rust --disable-pvg --enable-fdt=system
```

QEMU's license is in `QEMU-COPYING`. The patch includes the added peripheral source files. Firmware components remain the user's locally supplied Philips software. No security patches have yet been applied to that firmware.
