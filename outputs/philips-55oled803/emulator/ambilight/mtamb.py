#!/usr/bin/env python3
"""Decode the observed ARM32 MTAMB pixel ioctl ABI.

This is an integration component, not a replacement for the stock Ambilight
algorithm or a completed QEMU peripheral. Guest-memory adapters supply read()
and write(); no network or live-TV operations are performed.
"""
from dataclasses import dataclass, field
import json
import struct
from typing import Callable

SET_STATIC = 0x40083010
GET_STATIC = 0x40083011
SET_MEASURED = 0x40083014
SET_PROCESSED = 0x4008301A
GET_PROCESSED = 0x4008301B
OPERATIONS = {
    SET_STATIC: ("set", "static"),
    GET_STATIC: ("get", "static"),
    SET_MEASURED: ("set", "measured"),
    SET_PROCESSED: ("set", "processed"),
    GET_PROCESSED: ("get", "processed"),
}
RGB = struct.Struct("<III")
ARGUMENT = struct.Struct("<II")


@dataclass
class PixelBoundary:
    """State at the verified MTAL API boundary, with honest unknown handling.

    Returning a static color as a processed color would falsely claim that the
    proprietary processing ran. Therefore each stream is independent, and reads
    of unobserved colors fail. The integration must supply actual stock results.
    """

    emit: Callable[[dict], None] = lambda event: None
    pixels: dict = field(default_factory=lambda: {
        "static": {}, "measured": {}, "processed": {}
    })
    sequence: int = 0

    def ioctl(self, request: int, argument_address: int, read: Callable,
              write: Callable) -> int:
        if request not in OPERATIONS:
            raise NotImplementedError(f"Unmodelled MTAMB ioctl 0x{request:08x}")
        raw = read(argument_address, ARGUMENT.size)
        if len(raw) != ARGUMENT.size:
            raise ValueError("Short ARM32 ioctl argument")
        pixel, address = ARGUMENT.unpack(raw)
        if not 1 <= pixel <= 255:
            raise ValueError("Observed MTAMB callers use one-based uint8 indices")
        action, stream = OPERATIONS[request]
        if action == "set":
            raw = read(address, RGB.size)
            if len(raw) != RGB.size:
                raise ValueError("Short MTAMB RGB data")
            rgb = RGB.unpack(raw)
            self.pixels[stream][pixel] = rgb
            self.sequence += 1
            self.emit({
                "schema": "mtamb-pixel-v1",
                "sequence": self.sequence,
                "origin": "guest-ioctl",
                "stream": stream,
                "ioctl": f"0x{request:08x}",
                "pixel": pixel,
                "rgb_raw_u32": list(rgb),
                "rgb_application": [channel >> 8 for channel in rgb],
            })
        else:
            if pixel not in self.pixels[stream]:
                raise LookupError(f"No observed {stream} value for pixel {pixel}")
            write(address, RGB.pack(*self.pixels[stream][pixel]))
        return 0


def jsonl_sink(file):
    def emit(event):
        file.write(json.dumps(event, separators=(",", ":")) + "\n")
        file.flush()
    return emit
