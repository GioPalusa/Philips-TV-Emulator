# Target: Philips 55OLED803/12

The retail model is supplied by the owner. The identifiers below were read
directly from that TV over its authenticated ADB connection on 20 October 2026.
The collection used read-only properties, `/proc`, filesystem listings and
Android diagnostic commands. No root operation, configuration change or flash
was performed by this collection.

## Observed hardware and software

| Item | Evidence from the physical TV |
| --- | --- |
| Android model identifier | `ro.product.model=TPM171E` |
| Product / device | `PH7M_EU_5596` |
| Board property | `ro.product.board=TPM17XE_96` |
| SoC / hardware | `ro.board.platform=mt5891`, `ro.hardware=mt5891`; `/proc/cpuinfo` reports MT5891 |
| CPU | Four processors; ARM implementer `0x41`, part `0xd03`, revision 2 (Cortex-A53); running AArch32 |
| Application ABI | `armeabi-v7a,armeabi` |
| Linux-visible memory | `MemTotal: 1909568 kB`; this excludes reserved memory and is not the total installed DRAM capacity |
| Main eMMC device | `mmcblk0`, 15,267,840 KiB = 15,634,268,160 bytes; 32 numbered partitions |
| GPU renderer | `ARM, Mali-T860` |
| GLES driver string | `OpenGL ES 3.2 v1.r20p0-01rel0.4a629748dc9847303259494799348c70` |
| Android display size | `wm size`: 1920 × 1080; this is Android's reported rendering size, not proof of the physical panel's pixel count |
| Android density | `wm density`: 320 |
| Compositor refresh | SurfaceFlinger reports 60.000002 fps; latency query reports 16,666,666 ns period |
| Android | 8.0.0, API 26 |
| Reported security patch | 2021-01-05 |
| Linux | 3.10.79, SMP PREEMPT, build dated 8 November 2021, `armv7l` |
| Philips firmware | `TPM171E_R.107.001.143.000` |
| Build fingerprint | `Philips/PH7M_EU_5596/PH7M_EU_5596:8.0.0/OC/4718:user/release-keys` |

The actual TV also reports TPM171E through ADB. That name in an Android system
message is consistent with the target's stock firmware; it is not evidence that
another retail model has been selected.

The physical `/system/lib/egl/libGLES_mali.so` SHA-256 is
`4852724c5bddf4e04f92ef7f9d9e9c91bf411a88081b0bbe8dab46afa28409c6`.
The vendor module directory contains `mali_kbase.ko`, `mtk_mmap.ko`,
`star_mac.ko`, `wlan.ko`, `btmtk_usb.ko`, `tpvinput.ko`, USB and video modules.
Listing these files does not establish that each module is loaded.
The shell was denied access to `/proc/modules`.

The available CPU frequency sysfs reads returned no values, so CPU operating
frequencies have not been established. The SurfaceFlinger latency query
contained zero frame samples; its refresh period is not an input-latency
measurement or a benchmark of this TV's animation speed.

## What is reproduced and what is substituted

| Area | Current status |
| --- | --- |
| Kernel and system software | Derived from the owner's matching stock update; separate development-profile adaptations are recorded in manifests |
| CPU execution and memory map | Four AArch32 Cortex-A53 emulated cores; memory ranges recovered from this TV's device tree; no cycle-accurate timing guarantee |
| Boot and storage | Partial MT5891 peripheral models sufficient for observed Android framework boot; temporary writable overlays |
| Original Mali driver path | Does not initialize successfully in the current hardware model |
| SwiftShader profile | Software GLES adaptation; real Android rendering, slow under CPU emulation |
| Host GLES profile under development | Guest GLES command translation to host Metal; substitutes the graphics implementation and cannot validate Mali register-level behavior |
| Ambilight | Stock algorithm and SPI capture, approximate framebuffer measurements; synthetic fallback geometry |
| Panel / Ambilight calibration | Actual model/unit configuration and LED arrangement remain to be extracted or measured |
| Audio, tuner, HDMI, secure world | Incomplete; no claim of physical-device equivalence |

## Required evidence for hardware-specific development

1. Match extracted kernel, GPU user library and kernel modules to live hashes.
2. Preserve the measured device tree and partition geometry with their origin.
3. Establish actual panel configuration, Ambilight LED order/count and calibration,
   board options, clocks and peripheral revisions. Shared platform defaults are
   insufficient evidence for these model-specific details.
4. Measure identical navigation and rendering workloads on the physical TV and
   emulator before claiming comparable responsiveness.
5. Validate hardware-driver changes against the relevant real hardware or a
   sufficiently implemented hardware model. Fast translated GLES alone cannot
   validate a Mali driver update, boot-chain compatibility or flash recovery.

Device-specific keys, credentials, DRM data and personal settings are not part
of this inventory. The reconstructed emulator disk is not a full TV backup.
