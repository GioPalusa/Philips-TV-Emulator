#!/usr/bin/env python3
"""Decode the three non-secret Ambilight option bytes at NVM offset 0x464.

Accepts three hexadecimal bytes, never opens a TV or edits a disk image.
Bit fields come from IMamb_Eng_Create in dtv_driver.ko. The table is the
compiled fallback tuning data, not a measured 55OLED803/12 configuration.
"""
import argparse
import json

DEFAULT_ARCHITECTURES = (
    (4, 9, 8, 0), (4, 9, 9, 0), (2, 0, 0, 0), (3, 0, 0, 0),
    (4, 0, 0, 0), (4, 9, 0, 0), (5, 9, 0, 0), (3, 6, 0, 0),
    (4, 7, 0, 0), (3, 7, 0, 0), (4, 9, 0, 1), (6, 11, 0, 0),
    (5, 9, 10, 0), (4, 8, 0, 0), (3, 7, 0, 1), (4, 8, 8, 0),
    (5, 11, 0, 0), (3, 8, 0, 0), (4, 12, 0, 0), (3, 7, 0, 2),
    (3, 8, 0, 1), (2, 7, 0, 0), (3, 8, 8, 0), (5, 11, 0, 1),
)


def decode_options(data: bytes) -> dict:
    if len(data) != 3:
        raise ValueError("Provide exactly three bytes for NVM 0x464..0x466")
    a, b, c = data
    geometry = (a & 7, (a >> 3) & 15, (a >> 7) | ((b & 7) << 1),
                (b >> 3) & 3)
    selection = b >> 5
    match = geometry in DEFAULT_ARCHITECTURES
    return {
        "schema": "philips-ambilight-nvm-options-v1",
        "nvm_partition": 26,
        "offset_hex": "0x464",
        "raw_hex": data.hex(),
        "passes_support_gate": a != 0,
        "side_segments": geometry[0],
        "top_segments": geometry[1],
        "bottom_segments": geometry[2],
        "topology_version": geometry[3],
        "hardware_selection": selection,
        "algorithm_hardware_variant": {0: 0, 1: 1, 2: 0, 3: 1, 4: 2, 5: 2}.get(selection),
        "mirror_flip_correction_enabled": (c >> 6) != 0,
        "matches_compiled_architecture": match,
        "compiled_architecture_index": DEFAULT_ARCHITECTURES.index(geometry) if match else 10,
        "limitations": [
            "The firmware uses architecture index 10 when no tuple matches.",
            "Valid flash tuning data can replace the compiled architecture table.",
            "Passing the support gate does not prove the algorithm is running.",
            "These bytes alone do not establish physical LED count or wiring order.",
        ],
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("hex_bytes", help="Three bytes, e.g. '4c 08 00' (synthetic geometry)")
    args = parser.parse_args()
    try:
        result = decode_options(bytes.fromhex(args.hex_bytes))
    except ValueError as exc:
        parser.error(str(exc))
    print(json.dumps(result, indent=2))
