#!/usr/bin/env python3
"""Extract QEMU-ready zImage and ramdisk from this TV's stock boot image."""

import argparse
import struct
from pathlib import Path


def round_up(value: int, alignment: int) -> int:
    return (value + alignment - 1) // alignment * alignment


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("stock_boot", type=Path)
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()
    data = args.stock_boot.read_bytes()
    if data[:8] != b"ANDROID!":
        parser.error("not an Android boot image")
    kernel_size, _, ramdisk_size, _, _, _, _, page_size, _, _ = struct.unpack_from(
        "<10I", data, 8
    )
    if page_size < 512 or page_size & (page_size - 1):
        parser.error("invalid boot image page size")
    kernel_start = page_size
    ramdisk_start = kernel_start + round_up(kernel_size, page_size)
    kernel = data[kernel_start : kernel_start + kernel_size]
    ramdisk = data[ramdisk_start : ramdisk_start + ramdisk_size]
    if len(kernel) != kernel_size or len(ramdisk) != ramdisk_size:
        parser.error("truncated boot image")
    if kernel[:4] != bytes.fromhex("27051956"):
        parser.error("expected a uImage-wrapped ARM kernel")
    kernel = kernel[64:]  # QEMU needs the raw zImage, not the uImage header.
    if len(kernel) < 0x30 or struct.unpack_from("<I", kernel, 0x24)[0] != 0x016F2818:
        parser.error("expected an ARM zImage")
    start, end = struct.unpack_from("<II", kernel, 0x28)
    zimage_size = end - start
    if not 0x30 <= zimage_size <= len(kernel):
        parser.error("invalid zImage extent")
    # The appended stock default DTB overrides QEMU's measured external tree.
    # Preserve the full payload and emit a second image with only that tail removed.
    zimage = kernel[:zimage_size]
    if not ramdisk.startswith(bytes.fromhex("1f8b")):
        parser.error("expected a gzip ramdisk")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    payloads = (("kernel-payload.bin", kernel),
                ("kernel-without-dtb.bin", zimage), ("ramdisk.img", ramdisk))
    targets = [args.output_dir / name for name, _ in payloads]
    if any(target.exists() for target in targets):
        parser.error("refusing to overwrite an existing extracted file")
    for name, payload in payloads:
        target = args.output_dir / name
        with target.open("xb") as stream:
            stream.write(payload)
        print(f"Wrote {target.resolve()} ({len(payload):,} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
