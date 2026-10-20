#!/usr/bin/env python3
"""Decode only verified hardware-0 packets emitted by amb_driv_compute.

Input JSONL: {"schema":"mt5891-ambilight-spi-v1","sequence":1,
             "complete":true,"data_hex":"..."}
Output: indexed wire colors in the common viewer schema. Unknown packet types
are rejected. Physical placement and brightness-current calibration are unknown.
"""
import argparse
import json
import struct
import sys


def decode_hardware0(data):
    if not data or len(data) % 28:
        raise ValueError("Hardware-0 packets require complete 28-byte groups")
    pixels = []
    for offset in range(0, len(data), 28):
        packet = data[offset:offset + 28]
        if packet[0] != 0x96 or packet[1] & 0xC0 != 0x40:
            raise ValueError(f"Unrecognized hardware-0 header at byte {offset}")
        header = int.from_bytes(packet[:4], "big")
        gains = [header & 0x7f, (header >> 7) & 0x7f, (header >> 14) & 0x7f]
        # amb_driv_compute 0x599f88..0x599fc0 serializes B,G,R big-endian.
        for i in range(4):
            blue, green, red = struct.unpack_from(">HHH", packet, 4 + i * 6)
            pixels.append(((red, green, blue), gains))
    return pixels


def decode_record(record):
    if record.get("schema") != "mt5891-ambilight-spi-v1":
        raise ValueError("Unsupported SPI trace schema")
    if record.get("complete") is not True:
        raise ValueError("Truncated or overflowed SPI transfer")
    for i, (rgb, gains) in enumerate(decode_hardware0(bytes.fromhex(record["data_hex"])), 1):
        yield {
            "schema": "mtamb-pixel-v1",
            "sequence": record["sequence"],
            "origin": "guest-mmio-spi",
            "stream": "processed",
            "pixel": i,
            "index_space": "spi-wire-order-not-panel-position",
            "rgb_raw_u16": list(rgb),
            "rgb_application": [v >> 8 for v in rgb],
            "current_control_fields": gains,
            "calibration": "unmodelled",
        }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("capture", type=argparse.FileType("r"))
    args = parser.parse_args()
    try:
        for line in args.capture:
            if line.strip():
                for event in decode_record(json.loads(line)):
                    print(json.dumps(event))
    except (ValueError, KeyError) as error:
        print(f"Cannot decode capture: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
