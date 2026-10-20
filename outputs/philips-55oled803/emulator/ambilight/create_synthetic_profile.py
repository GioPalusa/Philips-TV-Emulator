#!/usr/bin/env python3
"""Create an APFS clone with firmware-supported, synthetic Ambilight geometry.

This is a host development fixture. Never flash its output onto a physical TV.
The source must be a reconstructed emulator disk with an entirely empty NVM
partition. Only bytes 0x464 and 0x465 of partition 26 are changed.
"""
import argparse
import ctypes
import hashlib
import json
import os
from pathlib import Path
import stat
import sys

from nvm_options import decode_options

NVM_START = 14620295168
NVM_SIZE = 2097152
DISK_SIZE = 15634268160
PATCH = b"\x4c\x08"  # Compiled fallback index 10: side4, top9, bottom0, topology1.


def create_profile(source: Path, destination: Path) -> dict:
    source = source.resolve(strict=True)
    destination = destination.absolute()
    manifest = destination.with_suffix(destination.suffix + ".synthetic-ambilight.json")
    source_stat = source.stat()
    if not stat.S_ISREG(source_stat.st_mode) or source_stat.st_size != DISK_SIZE:
        raise ValueError("Source must be a regular reconstructed 15634268160-byte emulator image")
    if destination.exists() or destination.is_symlink() or manifest.exists():
        raise ValueError("Destination image and manifest must not exist")
    with source.open("rb") as stream:
        stream.seek(NVM_START)
        nvm = stream.read(NVM_SIZE)
    if nvm != bytes(NVM_SIZE):
        raise ValueError("Refusing source with nonempty NVM; use the pristine reconstruction")
    if sys.platform != "darwin":
        raise RuntimeError("This helper requires macOS clonefile (APFS); no full-copy fallback")
    libc = ctypes.CDLL(None, use_errno=True)
    libc.clonefile.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_int]
    libc.clonefile.restype = ctypes.c_int
    if libc.clonefile(os.fsencode(source), os.fsencode(destination), 0):
        error = ctypes.get_errno()
        raise OSError(error, os.strerror(error), str(destination))
    with destination.open("r+b") as stream:
        stream.seek(NVM_START + 0x464)
        stream.write(PATCH)
        stream.flush()
        os.fsync(stream.fileno())
        stream.seek(NVM_START)
        changed = stream.read(NVM_SIZE)
    expected = bytearray(nvm)
    expected[0x464:0x466] = PATCH
    if changed != expected:
        raise RuntimeError("Clone NVM verification failed; destination retained for inspection")
    with source.open("rb") as stream:
        stream.seek(NVM_START)
        if stream.read(NVM_SIZE) != nvm:
            raise RuntimeError("Source NVM changed during operation")
    report = {
        "schema": "philips-emulator-synthetic-ambilight-profile-v1",
        "profile": "synthetic-compiled-fallback-geometry",
        "source_image": str(source),
        "destination_image": str(destination),
        "source_size": source_stat.st_size,
        "source_mtime_ns": source_stat.st_mtime_ns,
        "copy_method": "macOS clonefile; independent APFS copy-on-write clone",
        "physical_tv_configuration": False,
        "flash_to_physical_tv": False,
        "stock_algorithms_run": False,
        "source_nvm_sha256": hashlib.sha256(nvm).hexdigest(),
        "destination_nvm_sha256": hashlib.sha256(changed).hexdigest(),
        "changes": [{"partition": 26, "offset_hex": "0x464",
                     "image_offset": NVM_START + 0x464,
                     "before_hex": "0000", "after_hex": PATCH.hex()}],
        "options": decode_options(PATCH + b"\0"),
        "evidence": {
            "module_sha256": "7c9beee7c57ce276357eb4ee8a031ea3c8e5eebd42230df5b073ae557633bea9",
            "support_gate": "IMamb_Eng_Create 0x59fa8c",
            "geometry_decode": "IMamb_Eng_Create 0x59fb34..0x59fb74",
            "default_table": ".rodata+0x85dc6, 24 four-byte tuples",
            "fallback_index": "IMamb_App_GetArchIndex 0x5a1d88: 10",
        },
        "limitations": [
            "Only geometry is seeded; other NVM settings remain zero.",
            "EEPROM_Init and its MSDC initializer do not validate checksums or erase storage.",
            "No checksum surrounds the direct Ambilight option reads.",
            "Other userspace initialization might later change NVM; observe boot logs.",
            "No measurements of physical 55OLED803/12 topology are represented.",
        ],
    }
    with manifest.open("x") as stream:
        json.dump(report, stream, indent=2)
        stream.write("\n")
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    try:
        result = create_profile(args.source, args.destination)
    except (ValueError, RuntimeError, OSError) as exc:
        parser.error(str(exc))
    print(json.dumps(result, indent=2))
