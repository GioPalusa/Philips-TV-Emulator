# Philips 55OLED803/12: firmware extraction and root path

## Confirmed on this TV

- Firmware: `TPM171E_R.107.001.143.000`; board: `PH7M_EU_5596`; SoC: MT5891; Android: 8.0.0.
- ADB is authenticated, but the stock shell is UID 2000 (`shell`), with `ro.debuggable=0` and `ro.secure=1`.
- Raw eMMC partitions such as `/dev/block/mmcblk0p5` are readable only by root.
- `/dev/cli` resolves to a character device accessible to the shell group. It is the interface used by the published TPM171E temporary-root research.

## Extracted locally

`stock-boot-107.1.143.0.img` is the **stock boot image from the supplied 2021 `autorun.upg`**, decrypted using the recovery resource read from this TV. It is not a live read of the TV's boot partition.

- Size: 12,526,888 bytes
- SHA-1: `737cc3fff2e4e0885f39cdabd1418bb3ff62af74`
- SHA-256: `e1e15c5d0b24bb6ae82990a63e4351cac444b2036ac88d2ea4b150c6e7b30c74`
- The SHA-1 matches the stock boot image recorded by the independent [TPM171E root project](https://github.com/saidsurucu/philips-tpm171e-root). The TV firmware version also matches that project's tested device. This supports compatibility but does not prove that every partition on this 55OLED803/12 is identical.

The recovery resource and extracted passfile are kept in the local private work folder; they are not part of this output.

The exact-version recovery package and USB procedure are in [RECOVERY.md](RECOVERY.md). The ARM `philips-loader` and `philips-rootexec` binaries were built from the linked research projects, staged under `/data/local/tmp` on the TV, and tested only through their harmless help/usage paths. Their kernel-writing and root-trigger paths have not been run.

## Root route for a live partition dump

The [original TPM171E research](https://github.com/yath/tpm171e) uses a `dtv_driver.ko` kernel debug interface to acquire temporary root. The [follow-up implementation](https://github.com/saidsurucu/philips-tpm171e-root) fixes a Go thread-switching problem with a `rootexec` helper. It reports working permanent Magisk root on the same board and firmware, although its demonstrated TV is a different model.

For a dump, temporary root is the relevant stage:

1. Prepare and test a recovery route and keep a copy of the stock boot image. A failed kernel exploit can crash the TV; flashing a bad boot image can leave it unable to boot.
2. Build the original `loader` and the follow-up `rootexec` from reviewed source. The `loader` first locates the relevant handler on the live device and stages the temporary payload. Do not reuse another TV's hard-coded kernel address.
3. Trigger the payload with `rootexec`; verify `uid=0` before reading any raw partitions.
4. Read required partitions into files under `/data/local/tmp`, pull them over ADB, and compare sizes and hashes. Keep dumps of factory, DRM, and user-data partitions private because they may contain device keys or personal data.
5. Let the temporary root expire on reboot, then disable network ADB when work is complete.

Permanent root is a separate operation that patches and flashes the boot partition with Magisk. It is not necessary for extracting a live dump, and root itself does not supply newer Android security updates.

No root exploit, reboot, or flash has been run on this TV during this investigation. The recovery USB stick still needs to be prepared before trying the exploit.

## Model-specific emulator

The [55OLED803/12 emulator](emulator/README.md) now boots the stock Linux kernel
on four emulated Cortex-A53 cores and has reached Android framework boot
completion. Development graphics profiles have displayed the stock boot
animation; actual guest GLES pixel and shader tests also pass through ANGLE on
the Mac's Metal GPU. The stock Ambilight algorithm has produced captured SPI
output from explicitly synthetic measurement inputs. Full TV peripheral
behavior, physical LED calibration and a consistently usable launcher remain
incomplete. This does not provide security updates or validate physical flashing.

The [wiki development history](https://github.com/GioPalusa/Philips-TV-Emulator/wiki/Development-History)
tracks the stages, evidence and remaining work.
