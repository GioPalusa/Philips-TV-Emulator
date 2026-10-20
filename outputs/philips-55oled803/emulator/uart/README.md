# UART receive timing

The emulator's console RX models nominal **115200 baud, 8N1**: ten wire bits
per byte, rounded up to **86,806 ns** per byte. The FIFO holds 31 bytes when
enabled, or one byte when disabled. A separate 256-byte ingress queue provides
bounded, lossless host backpressure.

## Late timer dispatch

Previously, every callback admitted one byte and scheduled the next at
`callback time + 86,806 ns`. A late main-loop callback therefore discarded
elapsed wire time. The unchanged source in a deterministic timer harness
admitted only **one byte** when its first callback was dispatched at 1 ms,
although **11 complete byte periods** had elapsed.

The revised source retains the next byte's deadline. A callback admits elapsed
bytes until the FIFO is full or no whole byte period remains. This loop is
bounded to 31 arrivals. FIFO reads never refill inline. Empty input or a full
FIFO clears accumulated timing; when reception resumes, another whole byte
period must pass. TX behavior is unchanged.

This backpressure policy preserves existing bytes instead of implementing
physical UART overflow. It is a deliberate functional-model limitation.

## Verification

`test_rx_delayed.py` compiles the exact UART section extracted from `virt.c`
with deterministic timer and character adapters. AddressSanitizer and
UndefinedBehaviorSanitizer checks pass. Tests cover delayed dispatch, capacity,
byte order across all 256 ingress bytes, single-byte mode, FIFO flush,
backpressure, idle restart and receive-interrupt clearing.

`qtest_rx_timing.py` runs the actual QEMU device with a private character socket.
It verifies 0 bytes at 86,805 ns, 1 at 86,806 ns, 11 at 1 ms, and a full 31-byte
FIFO at 3 ms, plus byte order and single-byte backpressure.

**The actual-QEMU qtest test passes both before and after this change.**
QEMU's `clock_step` and `clock_set` visit every intermediate timer deadline via
`qemu_clock_advance_virtual_time`; they cannot reproduce a late callback.
The failing-before/passing-after evidence comes from the deterministic
production-source harness, not a claim that qtest delayed dispatch.

From the workspace root:

```sh
python3 outputs/philips-55oled803/emulator/uart/test_rx_delayed.py
python3 outputs/philips-55oled803/emulator/uart/qtest_rx_timing.py \
  --binary work/philips-emulator/qemu-11.1.2/build/qemu-system-aarch64
```

The source harness accepts `--source PATH` for another checkout and
`--expect-old` to reproduce the one-byte result against the old source.

`rx-deadline-evidence.json` records hashes, results and limits. These tests do
not modify the running emulator or the physical TV. Live remote latency and
its other contributing delays still require measurement.
