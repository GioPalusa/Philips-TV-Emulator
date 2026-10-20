# Software graphics for the Philips development emulator

## What is verified

The stock Android8 guest executed the included ARM32 SwiftShader libraries:

```text
EGL 1.4 vendor=Google Inc.
GLES vendor=Google Inc. renderer=Google SwiftShader
PASS clear/readback red RGBA=255,0,0,255
PASS shaders/triangle interior green; exterior preserved red
SWIFTSHADER TEST PASS
```

The test creates an EGL pbuffer, checks a clear pixel, compiles GLSL vertex
and fragment shaders, renders a triangle and checks interior/exterior pixels.
This is real software rendering inside the emulated ARM guest.
The full result is in `renderer-test-result.txt`.

SurfaceFlinger subsequently initialized this renderer and displayed the stock
BootAnimation. Android reached `sys.boot_completed=1` and accepted Home input.
The TV launcher and vendor service startup are still under investigation.
This package is an explicit development adaptation, not a Mali GPU emulator
and not a security update for the physical TV.

## Included components

- `libEGL_swiftshader.so`, `libGLESv2_swiftshader.so`,
  `libGLESv1_CM_swiftshader.so`: ARM32/API26 software rendering libraries.
- `render_test`, `render_test.c`: actual pixel/shader test.
- `hwcomposer.emulator.so`, `hwcomposer_emulator.c`: HWC1.1 framebuffer
  composer, exposed through the stock HWC2-on-HWC1 adapter.
- `gralloc.emulator.so`, `patch_gralloc.py`: exact-stock allocator variant
  selecting its existing ashmem allocation path for cross-process imports.
- `sepolicy-software-graphics`: narrowly modified development policy.
- Source, license and focused verification files for these additions.

The composer marks source layers for GLES client composition, waits for
the completed target's acquire fence, closes transferred fence descriptors,
and calls the stock framebuffer HAL's `post`. It propagates errors and takes
display dimensions/DPI/refresh from that framebuffer. Guest monotonic-clock
VSync callbacks honor enable/disable and blank state. There are no hardware
overlays or virtual displays. Scanout buffer locking follows the framebuffer
HAL's synchronous post/lock contract. ASan/UBSan host tests passed; the result
is in `hwc-test-result.txt`.

## Development-image selection

The prepared profile is in `../development/`. Reproduce it into new directories:

```sh
python3 outputs/philips-55oled803/emulator/software-graphics/prepare_profile.py \
  --output outputs/philips-55oled803/emulator/development-rebuilt \
  --scratch work/philips-profile-rebuilt \
  --debugfs work/philips-ext4/e2fsprogs-1.47.2/debugfs/debugfs \
  --e2fsck work/philips-ext4/e2fsprogs-1.47.2/e2fsck/e2fsck
```

This makes an independent APFS clone of the stock image, installs the files,
verifies their bytes and SELinux labels, checks ext4, and creates a separate
ramdisk. It refuses existing output directories. The manifest records changes.
The Ambilight helper enables stock measured-input mode 8 after 60 guest seconds.
Use the UI or `run.py --ambilight-framebuffer` to provide approximate raw OSD
measurements; constant fixtures remain available for diagnostics.

The parent image installer controls these changes in a cloned image:

1. Install SwiftShader under `/system/lib/egl`.
2. Disable the monolithic `libGLES_mali.so` in that development image.
3. Install `hwcomposer.emulator.so` and `gralloc.emulator.so` under `/vendor/lib/hw`.
4. Set `ro.hardware.gralloc=emulator` and `ro.hardware.hwcomposer=emulator`
   before graphics services start.
5. Preserve appropriate ownership, permissions and SELinux file labels.
6. Create `/user_setting/rw` during `post-fs`. The update image omits this
   persistent directory; stock initialization assumes it already exists.

## Framebuffer allocation fix

The stock fallback allocator returns framebuffer handles containing the
allocating process's virtual address. Its import path skips mapping these
handles. With the HIDL allocator and SurfaceFlinger in separate processes,
SwiftShader attempted a store to an unmapped address and crashed.

The development variant replaces one Thumb conditional branch at file offset
`0x120a` with a NOP. This selects the stock ashmem allocator. Each process can
map the resulting shared handle, and the stock framebuffer `post` copies it
into its own framebuffer mapping. The patch checks the exact stock SHA-256
and changes only two bytes; `gralloc.emulator.json` records provenance.
The original `gralloc.default.so` is preserved in the image.

Android8's normal EGL loader scans monolithic drivers first; simply adding
SwiftShader libraries or setting `ro.hardware.egl` does not reliably replace
Mali. The latter property applies to its separate updated-driver path.
The hardware-module loader does honor `ro.hardware.<class>` overrides.

## Scoped policy changes

Both processes produced actual `execmem` denials while executing SwiftShader
JIT code, followed by faults. Only these two rules were added:

```text
allow bootanim bootanim:process execmem;
allow surfaceflinger surfaceflinger:process execmem;
```

The policy remains version30 with 18,052 access-vector entries. No domain was
made permissive. For each added permission, the tool reparses its output,
reverts that one bit, and compares equal-roundtrip canonical serializations
byte for byte. This verifies all other policy content is preserved, including
the permissive-domain bitmap.

`policy/changes.json` records source/output SHA-256 values.
`policy/observed-execmem-denials.txt` records the observed failures.
The tool uses [SELinuxProject libsepol3.6](https://github.com/SELinuxProject/selinux/releases/tag/3.6).
To reproduce from the extracted original ramdisk policy:

```sh
python3 outputs/philips-55oled803/emulator/software-graphics/policy/build_policy.py \
  work/philips-software-gles/sepolicy-stock \
  work/sepolicy-software-graphics-reproduced
```

The source and output policy files are never overwritten by that script.

## Known adapter lifecycle issue

The stock `/vendor/lib/libhwc2on1adapter.so` has an unchecked VSync callback:
Thumb instruction `blx r1` at address `0x14630` calls the registered pointer
without a null check. Its behavior matches the official Android8 source:

- [HwcHal::enableCallback(false)](https://android.googlesource.com/platform/hardware/interfaces/+/android-8.0.0_r1/graphics/composer/2.1/default/Hwc.cpp)
  unregisters the HWC2 callback by passing null.
- [HWC2On1Adapter::hwc1Vsync](https://android.googlesource.com/platform/frameworks/native/+/android-8.0.0_r1/libs/hwc2on1adapter/HWC2On1Adapter.cpp)
  checks that a map entry exists, then calls its pointer without checking null.

This is a plausible explanation for the composer service fault after
SurfaceFlinger's JIT-permission fault; a crash backtrace is still needed to
confirm that specific runtime cause. The adapter binary has not been patched.
The development HWC1 close path stops and joins its VSync thread before the
adapter-owned callback object is destroyed.

## Renderer build provenance

[Pinned SwiftShader source](https://android.googlesource.com/platform/external/swiftshader/+/40586720c2da48d4bb1ddf936204fd6eab2d54a9/)
contains the ARM32 Subzero JIT, GLES rasterizer, shader compiler and Android
native-buffer integration. It was cross-compiled with existing LLVM Clang,
ARM ELF binutils, scoped AOSP headers and the stock TV shared libraries.
The guest libc/libc++ were not replaced.

Reproduction scripts are retained at `work/philips-software-gles/build.py`
and `work/philips-software-gles/hwc/build.py`. The former uses the downloaded
source/header archives, not a complete Android SDK. Android compiler-rt
provides proper per-thread emulated TLS; `cache_runtime.c` invokes the real
ARM cacheflush syscall wrapper. Bare-metal no-op cache and single-thread TLS
implementations were excluded. The libraries have non-executable stacks and
no text relocations. The bundled build also includes bounded framebuffer-copy diagnostics; `framebuffer-diagnostics.patch` records that instrumentation against the pinned source. The selected linker does not provide RELRO, another
reason to treat these as development artifacts.
