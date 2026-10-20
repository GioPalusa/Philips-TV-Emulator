#!/usr/bin/env python3
"""Select the stock allocator's ashmem path in a separate emulator-only HAL."""
import argparse
import hashlib
import json
from pathlib import Path

STOCK = "f2436f67001cf48b34b894ca7b25cd5349a6f58b548b8b103c386c20b0d15a9a"

def patch(raw):
    if hashlib.sha256(raw).hexdigest() != STOCK:
        raise ValueError("This patch requires the exact inspected stock gralloc HAL")
    # ELF's executable LOAD segment has equal file offset and virtual address.
    # alloc() tests usage & GRALLOC_USAGE_HW_FB, then BNE 0x121a selects a
    # framebuffer slice. NOP falls through to the existing ashmem allocator.
    # Its buffers can be imported by the separate HIDL/SF/composer processes.
    assert raw[0x120a:0x120c] == bytes.fromhex("06d1")
    result = bytearray(raw)
    result[0x120a:0x120c] = bytes.fromhex("00bf")
    assert sum(a != b for a, b in zip(raw, result)) == 2
    return bytes(result)

if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("stock", type=Path)
    ap.add_argument("output", type=Path)
    args = ap.parse_args()
    result = patch(args.stock.read_bytes())
    with args.output.open("xb") as stream:
        stream.write(result)
    args.output.with_suffix(".json").write_text(json.dumps({
        "purpose": "Emulator-only shared-memory allocation compatibility",
        "stock_sha256": STOCK,
        "output_sha256": hashlib.sha256(result).hexdigest(),
        "changes": [{"offset": "0x120a", "before": "06d1", "after": "00bf",
                     "meaning": "BNE framebuffer allocation -> NOP; use stock ashmem path"}],
        "presentation": "Stock framebuffer post copies imported ashmem pixels into fb memory",
        "original_preserved": True,
    }, indent=2) + "\n")
