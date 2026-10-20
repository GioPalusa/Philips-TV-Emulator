#!/usr/bin/env python3
"""Create a separate development ramdisk while preserving the stock input."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path


def read_newc(raw):
    entries = []
    offset = 0
    while offset + 110 <= len(raw):
        if raw[offset:offset+6] != b"070701":
            raise ValueError(f"Unsupported cpio header at {offset}")
        fields = [int(raw[offset+6+i*8:offset+14+i*8], 16) for i in range(13)]
        name_start = offset + 110
        name_end = name_start + fields[11]
        name = raw[name_start:name_end-1].decode()
        if raw[name_end-1:name_end] != b"\0":
            raise ValueError("Unterminated cpio name")
        start = (name_end + 3) & ~3
        end = start + fields[6]
        if end > len(raw):
            raise ValueError("Truncated cpio payload")
        if name == "TRAILER!!!":
            return entries
        entries.append((name, fields, raw[start:end]))
        offset = (end + 3) & ~3
    raise ValueError("Missing cpio trailer")


def write_newc(entries):
    result = bytearray()
    for name, original_fields, data in entries + [
        ("TRAILER!!!", [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 11, 0], b"")
    ]:
        fields = original_fields.copy()
        encoded = name.encode() + b"\0"
        fields[6], fields[11] = len(data), len(encoded)
        result += b"070701" + b"".join(f"{value:08x}".encode() for value in fields)
        result += encoded
        result += bytes(-len(result) % 4)
        result += data
        result += bytes(-len(result) % 4)
    result += bytes(-len(result) % 512)
    return bytes(result)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stock", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--disable-system-verity", action="store_true",
                        help="Permit a separately modified emulator system partition")
    parser.add_argument("--property", action="append", default=[], metavar="KEY=VALUE",
                        help="Set an emulator development property in default.prop")
    parser.add_argument("--append-init", type=Path,
                        help="Append a local development service fragment to init.rc")
    parser.add_argument("--sepolicy", type=Path,
                        help="Use a separately audited emulator development policy")
    args = parser.parse_args()
    if args.output.exists():
        parser.error("Output already exists")
    properties = {}
    for item in args.property:
        key, sep, value = item.partition("=")
        if not sep or not key or any(c not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-" for c in key) or "\n" in value or "\r" in value:
            parser.error("Invalid property")
        properties[key] = value
    stock = args.stock.read_bytes()
    entries = read_newc(gzip.decompress(stock))
    updated, changed = [], []
    for name, fields, data in entries:
        original = data
        if name == "fstab.mt5891" and args.disable_system_verity:
            lines = data.decode().splitlines(True)
            found = False
            for i, line in enumerate(lines):
                columns = line.split()
                if not line.startswith("#") and len(columns) > 1 and columns[1] == "/system":
                    if "wait,verify" not in line:
                        raise ValueError("Unexpected stock system fstab entry")
                    lines[i] = line.replace("wait,verify", "wait")
                    found = True
            if not found:
                raise ValueError("Missing system fstab entry")
            data = "".join(lines).encode()
        if name == "default.prop" and properties:
            lines = [line for line in data.decode().splitlines()
                     if line.partition("=")[0] not in properties]
            lines.extend(key + "=" + value for key, value in properties.items())
            data = ("\n".join(lines) + "\n").encode()
        if name == "init.rc" and args.append_init:
            data += b"\n" + args.append_init.read_bytes() + b"\n"
        if name == "sepolicy" and args.sepolicy:
            data = args.sepolicy.read_bytes()
        if data != original:
            changed.append(name)
        updated.append((name, fields, data))
    if args.disable_system_verity and "fstab.mt5891" not in changed:
        raise ValueError("System verity change was not applied")
    if properties and "default.prop" not in changed:
        raise ValueError("Development properties were not applied")
    packed = write_newc(updated)
    verified = read_newc(packed)
    assert [(n, d) for n, f, d in verified] == [(n, d) for n, f, d in updated]
    output = gzip.compress(packed, mtime=0)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("xb") as stream:
        stream.write(output)
    args.output.with_suffix(args.output.suffix + ".json").write_text(json.dumps({
        "purpose": "Emulator-only development ramdisk; not a physical-TV update",
        "stock_sha256": hashlib.sha256(stock).hexdigest(),
        "output_sha256": hashlib.sha256(output).hexdigest(),
        "changed_entries": changed,
        "preserved_entries": len(entries)-len(changed),
        "system_verity_disabled": args.disable_system_verity,
        "development_properties": properties,
        "init_fragment_sha256": hashlib.sha256(args.append_init.read_bytes()).hexdigest() if args.append_init else None,
        "sepolicy_sha256": hashlib.sha256(args.sepolicy.read_bytes()).hexdigest() if args.sepolicy else None,
    }, indent=2) + "\n")
    print(args.output)


if __name__ == "__main__":
    main()
