#!/usr/bin/env python3
"""Boot stock 55OLED803/12 firmware in the local hardware-development model."""

import argparse
import json
import os
import subprocess
from pathlib import Path


HERE = Path(__file__).resolve().parent


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--seconds", type=float, default=60,
        help="Stop after this many seconds; 0 runs until Ctrl-C (default: 60).",
    )
    parser.add_argument(
        "--log", type=Path, default=Path("55oled803-boot.log"),
        help="Where to write boot output (default: ./55oled803-boot.log).",
    )
    parser.add_argument(
        "--disk", type=Path, default=HERE / "stock-emmc-107.1.143.0.img",
        help="Raw stock eMMC image; all guest writes go to a temporary overlay",
    )
    parser.add_argument(
        "--no-disk", action="store_true", help="Run without an attached disk",
    )
    parser.add_argument("--ambilight-log", type=Path,
                        help="New JSONL file for guest Ambilight SPI transfers")
    parser.add_argument("--ambilight-fixture", action="store_true",
                        help="Supply synthetic measurement rows and 50 Hz video timing")
    parser.add_argument("--ambilight-rgb16",
                        help="Constant synthetic measurement R,G,B in 0..65535; requires --ambilight-fixture")
    parser.add_argument("--ambilight-framebuffer", action="store_true",
                        help="Feed approximate raw OSD measurements into the stock Ambilight algorithm")
    parser.add_argument("--console", action="store_true",
                        help="Connect this terminal to the Android serial shell (Ctrl-C stops QEMU)")
    parser.add_argument("--ramdisk", type=Path, default=HERE / "ramdisk.img",
                        help="Ramdisk to boot; defaults to the original stock ramdisk")
    parser.add_argument("--osd-scanout", action="store_true",
                        help="Enable the raw guest framebuffer display and virtual display timing")
    parser.add_argument("--qmp", type=Path,
                        help="Local Unix socket for QMP monitoring and framebuffer screenshots")
    args = parser.parse_args()
    if args.seconds < 0:
        parser.error("--seconds must be zero or greater")
    if args.ambilight_rgb16 and not args.ambilight_fixture:
        parser.error("--ambilight-rgb16 requires --ambilight-fixture")
    if args.ambilight_framebuffer and args.ambilight_fixture:
        parser.error("Select framebuffer measurements or a synthetic fixture")

    inputs = (
        HERE / "qemu-system-aarch64-55oled803",
        HERE / "kernel-without-dtb.bin",
        args.ramdisk,
        HERE / "mt5891-sanitized.dtb",
    )
    missing = [str(path) for path in inputs if not path.is_file()]
    if missing:
        parser.error("missing emulator file(s): " + ", ".join(missing))

    command = [
        str(inputs[0]),
        "-accel", "tcg",
        "-machine", "virt,gic-version=2,highmem=off,virtualization=on",
        "-cpu", "cortex-a53,aarch64=off,cntfrq=24000000",
        "-smp", "4",
        "-m", "880M",
        "-nodefaults",
        "-nic", "none",
        "-display", "none",
        "-serial", "none",
        "-monitor", "none",
        "-no-reboot",
        "-kernel", str(inputs[1]),
        "-initrd", str(inputs[2]),
        "-dtb", str(inputs[3]),
        "-append",
        "console=ttyMT0,115200n1 earlyprintk=serial,ttyMT0 "
        "androidboot.hardware=mt5891 device_name=55OLED803/12 vmalloc=650mb "
        + (HERE / "partition-bootargs.txt").read_text().strip(),
    ]
    if not args.no_disk:
        if not args.disk.is_file():
            parser.error(f"eMMC image not found: {args.disk} (or use --no-disk)")
        manifest = json.loads((HERE / "partitions.json").read_text())
        if args.disk.stat().st_size != manifest["emmc_size_bytes"]:
            parser.error("eMMC image size does not match the measured TV geometry")
        command += [
            "-drive",
            f"if=none,format=raw,snapshot=on,file={str(args.disk.resolve()).replace(',', ',,')},id=tv-emmc",
            "-global", "mt5891-msdc.allow-writes=on",
            "-global", "emmc.reliable-write-sector-count=0",
        ]
        print("Attached stock eMMC through MT5891 MSDC; writes use a temporary overlay.")
    environment = os.environ.copy()
    environment.pop("PHILIPS_AMBILIGHT_LOG", None)
    environment.pop("PHILIPS_AMBILIGHT_FIXTURE", None)
    environment.pop("PHILIPS_VIDEO_VSYNC_FIXTURE", None)
    environment.pop("PHILIPS_AMBILIGHT_FIXTURE_RGB16", None)
    environment.pop("PHILIPS_AMBILIGHT_FRAMEBUFFER", None)
    environment.pop("PHILIPS_OSD_SCANOUT", None)
    if args.osd_scanout:
        environment["PHILIPS_OSD_SCANOUT"] = "1"
    if args.ambilight_framebuffer:
        environment["PHILIPS_AMBILIGHT_FRAMEBUFFER"] = "1"
        environment["PHILIPS_OSD_SCANOUT"] = "1"
        environment["PHILIPS_VIDEO_VSYNC_FIXTURE"] = "1"
        print("Approximate raw OSD measurements feed the stock Ambilight algorithm.")
    if args.qmp:
        if args.qmp.exists():
            parser.error("QMP socket path already exists")
        command += ["-qmp", f"unix:{args.qmp.resolve()},server=on,wait=off"]
    if args.ambilight_fixture:
        environment["PHILIPS_AMBILIGHT_FIXTURE"] = "1"
        environment["PHILIPS_VIDEO_VSYNC_FIXTURE"] = "1"
        print("Synthetic Ambilight measurements and video timing enabled.")
        if args.ambilight_rgb16:
            environment["PHILIPS_AMBILIGHT_FIXTURE_RGB16"] = args.ambilight_rgb16
    if args.console:
        command += ["-chardev", "stdio,id=tv-console,signal=on"]
    if args.ambilight_log:
        if args.ambilight_log.exists():
            parser.error("Ambilight log already exists; select a new filename")
        args.ambilight_log.parent.mkdir(parents=True, exist_ok=True)
        environment["PHILIPS_AMBILIGHT_LOG"] = str(args.ambilight_log.resolve())
    args.log.parent.mkdir(parents=True, exist_ok=True)
    try:
        with args.log.open("wb") as log:
            process = subprocess.Popen(command,
                                       stdout=None if args.console else log,
                                       stderr=log, env=environment)
            try:
                code = process.wait(timeout=args.seconds if args.seconds else None)
            except subprocess.TimeoutExpired:
                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
                code = 0
            except KeyboardInterrupt:
                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
                code = 0
    except OSError as exc:
        parser.exit(1, f"Could not launch the emulator: {exc}\n")

    print(f"Boot log: {args.log.resolve()}")
    if args.ambilight_log:
        print(f"Ambilight SPI capture: {args.ambilight_log.resolve()}")
        print("An empty capture means the firmware has not emitted LED data.")
    if code:
        print(f"QEMU exited with status {code}; inspect the log.")
    return code


if __name__ == "__main__":
    raise SystemExit(main())
