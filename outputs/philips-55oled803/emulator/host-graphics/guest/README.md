# ARM32 Android 8 host graphics guest stack

This development stack moves GLES commands to the host renderer. It is not a Mali GPU model. These artifacts compile and link against this TV's Android 8 libraries. The guest clear/readback and shader pixel tests now pass through ANGLE Metal on the Apple M4 Pro (see `guest-render-test.txt`). Full TV interface performance and boot timing remain separate validation.

## Artifacts

- `libEGL_emulation.so`, `libGLESv1_CM_emulation.so`, `libGLESv2_emulation.so`: EGL and GLES front ends. Install in `/system/lib/egl`.
- `libGLESv1_enc.so`, `libGLESv2_enc.so`, `lib_renderControl_enc.so`, `libOpenglSystemCommon.so`: encoder dependencies, for `/system/lib`.
- `gralloc.goldfish.so`: compatible host color-buffer allocator, for `/system/lib/hw`; select `ro.hardware.gralloc=goldfish` and `ro.kernel.qemu.gles=1` in the isolated development ramdisk. The existing ashmem gralloc variant is incompatible with these host color-buffer handles.
- `hostgpu_broker`: nonblocking Unix-socket to QEMU MMIO broker, for an emulator-only init service. Uses existing `/dev/rmmgr`; `--probe` only checks the emulated device's magic value.
- `hostgpu_render_test`: standalone EGL2 pbuffer pixel and shader test. Must print `HOSTGPU TEST PASS` with a host GPU renderer before treating the stack as operational.

The libraries connect exclusively to guest `/dev/socket/philips_hostgpu`. Every socket starts with NUL-terminated `pipe:opengles` or `pipe:GLProcessPipe`. The broker preserves independent streams and backpressure. It handles up to 64 clients, with 64 KiB queues per direction per client. It polls at 4 ms while active and 100 ms without clients; actual latency remains to be measured. Access is governed by the emulator SELinux policy. The broker requires a dedicated service and socket/device permissions; do not install on physical hardware.

## Transport v1

Shared payload physical address `0xa1000000`, size 1 MiB; control address `0xa1100000`, size 4 KiB. Both sit outside this board's RAM and reserved framebuffer pools. Registers, all little-endian uint32:

| Offset | Register |
| --- | --- |
| 0 | Write command: OPEN=1, WRITE=2, READ=3, CLOSE=4 |
| 4 | Completion status: zero or negative Linux errno |
| 8 | Host connection ID |
| 12 | Payload size / maximum read size |
| 16 | Signed result: connection ID or byte count |
| 20 | Read-only magic `0x50484750` |

Commands complete synchronously, but host socket operations never block. READ returns `-EAGAIN` when no bytes are available; zero means EOF. WRITE may accept a prefix. OPEN takes the NUL-terminated service handshake. QEMU must translate Darwin errno values to Linux values. Barriers order payload/control access. The socket transport is emulator-only and provides no guest network access.

Goldfish `fb_post` sends `rcFBPost(hostColorBuffer)` directly. It does not write the previous MT5891 framebuffer. The host must publish posted frames to the viewer and supply image samples to the Ambilight emulation. Sending every frame back through the guest would add avoidable copies.

## Rebuild

Prerequisite: the existing `work/philips-software-gles` Android 8 platform headers, ARM32 sysroot and stock linking libraries prepared by that renderer's build procedure. Homebrew LLVM and `arm-none-eabi` tools must be available. From the repository root:

```sh
python3 outputs/philips-55oled803/emulator/host-graphics/guest/prepare_sources.py
python3 outputs/philips-55oled803/emulator/host-graphics/guest/build.py
```

Outputs appear in `work/philips-guest-gpu/build`. Both scripts honor `PHILIPS_GUEST_GPU_WORK`. The source manifest pins public archive hashes. The socket patch preserves the AOSP license header; generated encoder implementations are unmodified. Upstream sources: Android `device/generic/goldfish-opengl` and Bionic private headers, tag `android-8.0.0_r36`.

## Device mapping evidence

The stock module `/vendor/lib/modules/mtk_mmap.ko` (SHA256 `232470c171bd28c80822dc4ac7fa59ab8175d9231fee1c5bf55f2e4183109738`) is loaded in stock post-fs-data. Static inspection of `adapt_dev_mmap` at 0x78 shows `remap_pfn_range(vma, vm_start, vm_pgoff, vm_end-vm_start, vm_page_prot)` without a physical-range filter. Module initialization registers major 229, minor 0, with name `/dev/rmmgr`. The boot log also confirms stock init creates `/dev/rmmgr` as a symlink to `/linux_rootfs/dev/rmmgr`. This establishes a likely existing mapping interface without replacing the kernel. It does not establish that SELinux will permit this broker or that a runtime mapping succeeds. REA instruction evidence: `ev_1ab2211622e26fe1e67f7e3552b74f354c3569a065ccacfa760756cfff488d1b`.

## Explicit development SELinux profile

`policy/sepolicy-hostgpu` adds 58 concrete source/target/class/permission rules to the previously verified two-permission graphics policy. It does not disable enforcement. Every addition is listed in `policy/rules.txt`; each step was reparsed and its single change reversed to verify the original canonical policy was reproduced. `policy/build_policy.py` rebuilds and checks the exact output hash.

The broker launches through the existing shell entrypoint and temporarily uses the shipped `mt_dtv-svc` domain, which also affects the other process in that domain. This is an explicit emulator development accommodation, not production isolation. Its init-created socket uses the existing `surfaceflinger` peer context, which is an MLS trusted subject and permits categorized Android apps to connect. Before listening, the broker labels the socket inode as the existing `pdx_display_client_endpoint_socket` type (an MLS trusted object). This is a development accommodation rather than a dedicated broker domain. Only listed graphics/application client domains receive connect permission. No guest networking permission is added. The broker accepts the init-provided descriptor and waits up to 30 seconds for the existing mapping device. `emulator-hostgpu.rc` starts it in post-fs-data and runs the independent pixel test at boot.

These static policy changes must still be verified against runtime AVCs and MLS constraints. Keep this policy paired with the emulator-only ramdisk, and never flash it to the television.

Observed first integration run: `HOSTGPU_PROBE PASS magic=50484750 PA=a1100000`. This confirms the stock `/dev/rmmgr` mapping reaches the QEMU device. Initial broker entrypoint and init socket cleanup AVCs were addressed in the revised init/policy; subsequent guest rendering passed after the EGL client-state fix below.

The second run established the broker connection and returned EGL 1.4 with the host Apple renderer. It then exposed an Android 8 encoder initialization bug: `eglMakeCurrent` queried GLES3 capabilities before assigning the encoder's client state. The old EGL driver upgrades requested ES2 contexts when the host advertises GLES3. `egl-client-state-order.patch` assigns that state before capability queries, preserving the later full make-current initialization. This fixes the observed null-state assertion without suppressing it or faking capability values.

Third integration run: `HOSTGPU TEST PASS`; the guest renderer reports ANGLE Metal on Apple M4 Pro. It verified red RGBA clear/readback, a green shader triangle interior and preserved red exterior. SurfaceFlinger also passed its earlier client-state crash point. This proves real host GPU rendering from the ARM32 guest; it does not yet establish television-equivalent responsiveness.
