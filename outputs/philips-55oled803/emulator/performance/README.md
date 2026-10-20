# Performance milestones — 20 October 2026

These measurements do not establish responsiveness equal to the physical TV.

## MMIO diagnostic lookup

The previous unimplemented-register diagnostic performed a linear search over
up to 8,192 addresses for each access while holding QEMU's global lock. The
replacement uses a bounded hash table and preserves first-access logging,
polling counts, and the existing address limit.

`test_mmio_trace.c` compares both implementations over 8,192 addresses,
collisions, repeated accesses, and capacity exhaustion. The recorded
`mmio-benchmark.txt` reports 2.032225 seconds versus 0.008583 seconds for its
one-million-access workload. This is a microbenchmark of the lookup only.

Two five-second host samples showed `philips_note_mmio` dropping from 630 to
7 top-of-stack samples. The guest workloads were not identical, so this is
corroboration of hotspot removal, not a whole-system speedup measurement.
The later profile prominently contains emulated floating-point operations.

## Raw display capture

The viewer requests QEMU PPM output and displays RGB pixels on a canvas.
Capture and browser presentation are bounded to 20 Hz with no frame queue.
Observed capture times were approximately 9–15 ms and browser presentation
approximately 19.6 Hz. **VIEW FPS counts presentations, including repeated
images; it does not measure newly rendered Android frames.**

The guest still uses ARM32 SwiftShader in this profile. Android boot completion
and actual OSD scanout were observed after applying the MMIO improvement.
Host GLES acceleration is a separate implementation in `../host-graphics`.
