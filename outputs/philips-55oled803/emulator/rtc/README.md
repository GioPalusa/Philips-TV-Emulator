# MT5891 RTC calendar model

The stock kernel contains support for `CLOCK_BOOTTIME_ALARM`. The current missing RTC device prevents it from creating these timers.

## Evidence

- Guest startup prints `Rtc_reg_base: 0xf0028000`, then `unable to open rtc device (rtc0)`.
- Bluetooth's alarm code reports `timer_create` clock 9 returning error **524**.
- Exact stock kernel `alarm_timer_create` at `0xc0078770` calls `alarmtimer_get_rtcdev`. A null device returns `0xfffffdf4` (**−524**) at `0xc00787d4`. Capability failure is a different return (**−1**).
- `mt53xx_rtc_probe` at `0xc035ec04` maps the stock `Mediatek, PDWNC` node. After unlock writes `87`, `78` to offset `748`, it checks bit `40` of offset `73c`. When clear, it sets `_fgRTCDisableRTC` and exits successfully without registering an RTC. The previously unmodeled register read zero.
- When the status bit is present and the calendar valid, probe additionally checks offset `108` against **12,000,000** (`0x00b71b00`) before preserving the date. Otherwise it initializes its default 2017 calendar.
- The stock platform's IRQ resource is −1, selecting the RTC operations containing `read_time`, `set_time`, and `set_alarm_2`. This model does not invent a new kernel IRQ route.

Source identity: extracted stock kernel ELF SHA-256 `f039c1fdec88c97de9279d35a8d7f5acf25b2fa1c8f677517862774d53f939ee`; addresses from its extracted kallsyms. Disassembly supporting this analysis remains in `work/philips-rtc/rtc-driver.S`.

## Implemented subset

- Calendar registers at **0xf0028700–0xf002874b**; BCD year (2000–2099), month, day, weekday, 24-hour hour/minute/second, leap-year phase.
- Initial date follows QEMU's configured RTC policy. Subsequent elapsed time follows **QEMU virtual time**, so pausing the VM pauses this modeled clock.
- Control bit 6 reports the modeled RTC's presence; control bit 0 freezes calendar updates for programming.
- Exact stock unlock sequence and relocking; setting date/time updates the clock's epoch when freeze clears.
- Byte/halfword/word bus accesses with little-endian lane handling.
- The calibration register at PDWNC offset `108` returns 12 MHz, matching the stock probe's preserved-calendar check.
- Alarm register storage exists in the range, but **alarm matching, IRQ delivery, power-state wakeup, and suspend/resume wake behavior are not implemented or claimed**. Once the kernel registers this RTC, awake `CLOCK_BOOTTIME_ALARM` expiry is handled by its existing hrtimer implementation; the integrated guest has now registered `rtc0`, while a direct timer-expiry test remains pending.

This change enables the missing device model. It does not disable Bluetooth or change its timer requests.

## Integration hooks

In `hw/arm/virt.c`, include `philips-rtc.inc` alongside the other Philips model includes. Call `philips_rtc_read(offset,size,&value)` and `philips_rtc_write(offset,size,value)` before the generic MMIO fallback, returning on handled access. Call `philips_rtc_init()` once during machine setup beside PDWNC initialization. Other PDWNC registers are not claimed by this model.

## Focused model test

```sh
clang -std=c11 -D_DARWIN_C_SOURCE -Wall -Wextra -Wno-unused-parameter \
  -Itest-include test_rtc.c -o test_rtc
./test_rtc
```

The harness compiles the same model source with deterministic clock/reset adapters. It verifies presence/calibration, locked writes, unlock order, BCD calendar values, 24-hour rollover, leap day (including 2000), year rollover, freeze/write/resume, bus lanes, and reset. The preserved pass result is in `evidence/model-test.txt`.

## Guest alarmtimer probe

`rtc_alarm_probe` is an ARM32 Android 8 executable built against the existing guest sysroot. Run it in an init service with the `CAP_WAKE_ALARM` capability. It creates clock-9 `CLOCK_BOOTTIME_ALARM`, sets a 250 ms timer, checks expiry after 500 ms while the VM stays awake, and deletes the timer. It prints the exact errno on failure. A shell lacking the capability can receive `EPERM`, which is separate from the missing-RTC error 524. Guest execution is pending integration; the binary being present is not a passing result.

## Observed integration

Run `20261020-192007-df77ee` registered `mt53xx_rtc` as `rtc0` at
1.673187 guest seconds and set the system clock to 2026-10-20 17:20:08 UTC.
The next run also registered the device. These observations establish stock
driver discovery and clock initialization, not suspend wake or alarm expiry.
