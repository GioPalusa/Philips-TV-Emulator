#!/usr/bin/env python3
"""Create a sparse eMMC image with the live TV's partition offsets.

Only the optional stock boot image is copied into it. All other bytes are
zero; this is a geometry template and not a backup of the TV.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path


HERE = Path(__file__).resolve().parent


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path, help="New sparse raw image path")
    parser.add_argument(
        "--boot-image", type=Path,
        help="Optional stock Android boot image to put in the boot partition",
    )
    args = parser.parse_args()
    manifest = json.loads((HERE / "partitions.json").read_text())
    boot = next(part for part in manifest["partitions"] if part["name"] == "boot")
    if args.boot_image:
        boot_bytes = args.boot_image.read_bytes()
        if len(boot_bytes) > boot["size_bytes"]:
            parser.error("boot image exceeds the TV's boot partition")
    else:
        boot_bytes = b""

    args.output.parent.mkdir(parents=True, exist_ok=True)
    try:
        fd = os.open(args.output, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o644)
    except FileExistsError:
        parser.error(f"refusing to overwrite {args.output}")
    try:
        os.ftruncate(fd, manifest["emmc_size_bytes"])
        if boot_bytes:
            os.lseek(fd, boot["start_byte"], os.SEEK_SET)
            position = 0
            while position < len(boot_bytes):
                position += os.write(fd, boot_bytes[position:])
        os.fsync(fd)
    except BaseException:
        os.close(fd)
        args.output.unlink(missing_ok=True)
        raise
    else:
        os.close(fd)

    print(f"Created {args.output.resolve()}")
    print(f"Logical size: {manifest['emmc_size_bytes']:,} bytes")
    print(f"Physical disk used: {args.output.stat().st_blocks * 512:,} bytes")
    if boot_bytes:
        print(f"Stock boot at offset {boot['start_byte']:,} bytes")
        print(f"Boot SHA-256: {hashlib.sha256(boot_bytes).hexdigest()}")
    print("All other partition contents are empty. This is not a TV backup.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
