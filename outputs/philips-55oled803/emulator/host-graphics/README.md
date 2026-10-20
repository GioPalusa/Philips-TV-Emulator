# Host graphics bridge: Android GLES → gfxstream → ANGLE Metal

This bridge executes Android's serialized OpenGL ES commands on the Mac GPU. It is a graphics compatibility layer, not an emulation of the Mali GPU's registers, firmware, or timing. Guest applications and Android remain inside the Philips emulator.

## Verified on this Mac

- Installed Android Emulator SDK **36.6.11 / build 15507667**, native arm64 backend.
- Actual renderer: **ANGLE Metal Renderer: Apple M4 Pro**.
- Standalone 1920×1080 shader triangle: correct center pixel; median GPU draw plus finish **0.527 ms**, full-frame CPU readback **3.737 ms**, over 120 warmed frames. This simple workload does not measure Android UI responsiveness.
- Android 8 goldfish wire protocol: renderer version, EGL version, config queries, context/window/color-buffer creation, clear, flush, and posting all work.
- Red, green, and blue frames sent over the local Unix socket appear correctly in the shared RGBA output. Synthetic frame-post test observed about **23 ms** after first-frame warmup. Its repeated posts and 20 ms polling are a correctness test, not an end-to-end latency benchmark.
- Evidence is in `evidence/`. Complete Android launcher performance must be measured with the integrated guest and transport.

## Build and start

Requires the user's installed Android Emulator SDK and Xcode command-line tools. The SDK libraries are referenced in place and are not copied into this deliverable.

```sh
./build.sh
./launch.py
```

Set `ANDROID_SDK_ROOT` if the SDK is not under `~/Library/Android/sdk`. Launch prints a JSON object containing the Unix socket and frame paths, then runs the renderer. The temporary directory is private (0700); socket and frame are 0600. The renderer is a foreground process; stop it with Ctrl-C. Each launch uses fresh paths. Existing socket/frame files are never replaced.

The API headers are pinned to gfxstream commit `01b914196fc1` (2026-05-13). The current upstream `FeatureSet` layout includes fields absent from SDK 36.6.11 and must not be substituted. The backend's C++ API is not a stable cross-version ABI: SDK upgrades require revalidation or building a matched gfxstream release from source.

## Transport

Each guest GLES thread has a separate bidirectional stream. Each host Unix-socket connection starts with a NUL-terminated service name:

- `pipe:opengles`: followed by the original little-endian uint32 flags word and the Android 8 generated GLES/renderControl command stream. Replies are returned unchanged.
- `pipe:GLProcessPipe`: followed by little-endian uint32 value 100. Reply is a unique uint64 process ID. The connection remains open for that process's lifetime and its resources are cleaned when it closes.

Commands are decoded by gfxstream. The bridge does not reinterpret opcodes. The guest broker and QEMU shared-memory device forward bytes; no guest TCP/IP is required.

The host reply pump blocks on `RenderChannel::waitUntilReadable()`, avoiding periodic polling. An isolated 1000-call renderControl round-trip benchmark improved median latency from 0.318 ms (250 μs polling) to 0.0144 ms (event notification); 95th percentile improved from 0.333 ms to 0.0269 ms. This excludes the emulated CPU and guest broker.

Set `PHILIPS_HOSTGPU_TRACE=1` before launch for passive stream byte/opcode counts, printed at most every five seconds while traffic flows. Counts do not modify commands or enable checksums.

`SELECTED_RENDERER_ANGLE_INDIRECT` selects the GLES backend shader path. `ANGLE_DEFAULT_PLATFORM=metal` selects the actual GPU backend. Although the enum's upstream comment mentions SwiftShader, runtime evidence explicitly identifies Metal. Leaving the selection at `HOST` produces incompatible desktop GLSL during texture copies.

## Shared framebuffer

One mmap file, top-down RGBA8 pixels at offset 64, total size 8,294,464 bytes. The fixed header uses little-endian values:

| Offset | Type | Meaning |
|---|---|---|
| 0 | uint32 | Magic `0x55475048` |
| 4 | uint32 | Version 1 |
| 8 / 12 | uint32 | Width 1920 / height 1080 |
| 16 | uint32 | Stride 7680 bytes |
| 20 | uint32 | Format 1 = RGBA8 |
| 24 | uint64 | Sequence, odd during write and even when stable |
| 32 | uint64 | Frame count |
| 40–63 | bytes | Reserved zero |

Readers should read an even sequence, copy the frame, and confirm the same sequence afterward. gfxstream uses asynchronous GPU readback; the callback must call `getReadPixelsCallback()` rather than trusting the notification's pixel buffer. The first frame requires filling the readback pipeline. Currently output is fixed at 1080p.

## Scope and remaining work

This package does not itself install the guest EGL/gralloc libraries or wire the QEMU transport. It has no physical-TV connection. No firmware update or hardware performance equivalence is implied. GPU command validation, resource limits beyond the 128-client cap, shutdown cleanup, transport batching, and full guest UI benchmarking remain integration work.

The socket accepts GPU commands and must remain restricted to the trusted local emulator process. Do not expose it over a network.

## Source and licensing

The interface headers retain their Apache-2.0 notices from [Google gfxstream](https://github.com/google/gfxstream/tree/01b914196fc1). Header reproduction is pinned in `sources.json`; license text is in `LICENSE.gfxstream`. The SDK's own LICENSE and NOTICE files govern the installed native libraries and dependencies. This package does not redistribute those libraries.
