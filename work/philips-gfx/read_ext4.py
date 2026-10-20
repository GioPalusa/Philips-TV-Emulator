#!/usr/bin/env python3
"""Read-only ext4 inspection directly inside the stock eMMC image."""
import argparse
import json
import pathlib
import posixpath
import stat
import struct


def u16(data, off):
    return struct.unpack_from("<H", data, off)[0]


def u32(data, off):
    return struct.unpack_from("<I", data, off)[0]


class Ext4:
    def __init__(self, image, offset, size):
        self.file = open(image, "rb")
        self.offset, self.size = offset, size
        sb = self.read(1024, 1024)
        if u16(sb, 56) != 0xef53:
            raise ValueError("Not an ext4 superblock")
        self.block_size = 1024 << u32(sb, 24)
        self.inodes_per_group = u32(sb, 40)
        self.inode_size = u16(sb, 88)
        self.descriptor_size = max(32, u16(sb, 254))
        self.gdt_offset = (2 if self.block_size == 1024 else 1) * self.block_size
        self.inodes = u32(sb, 0)

    def read(self, off, size):
        if off < 0 or size < 0 or off + size > self.size:
            raise ValueError(f"Read outside filesystem: {off:#x}+{size:#x}")
        self.file.seek(self.offset + off)
        data = self.file.read(size)
        if len(data) != size:
            raise ValueError("Short image read")
        return data

    def inode(self, number):
        if not 1 <= number <= self.inodes:
            raise ValueError("Invalid inode")
        group, index = divmod(number - 1, self.inodes_per_group)
        gd = self.read(self.gdt_offset + group * self.descriptor_size,
                       self.descriptor_size)
        block = u32(gd, 8)
        if self.descriptor_size >= 64:
            block |= u32(gd, 40) << 32
        return self.read(block * self.block_size + index * self.inode_size,
                         self.inode_size)

    def extents(self, node, expected_depth=None):
        if u16(node, 0) != 0xf30a:
            raise ValueError("Not an extent node")
        count, maximum, depth = u16(node, 2), u16(node, 4), u16(node, 6)
        if (depth > 5 or count > maximum or 12 + count * 12 > len(node) or
                (expected_depth is not None and depth != expected_depth)):
            raise ValueError("Invalid extent header")
        result = []
        for i in range(count):
            entry = node[12 + i * 12:24 + i * 12]
            logical = u32(entry, 0)
            if depth:
                block = u32(entry, 4) | u16(entry, 8) << 32
                result += self.extents(self.read(block * self.block_size,
                                                self.block_size), depth - 1)
            else:
                length = u16(entry, 4)
                unwritten = length > 32768
                if unwritten:
                    length -= 32768
                physical = u32(entry, 8) | u16(entry, 6) << 32
                result.append((logical, length, physical, unwritten))
        return result

    def data(self, number):
        inode = self.inode(number)
        size = u32(inode, 4) | u32(inode, 108) << 32
        if size > 256 * 1024 * 1024:
            raise ValueError("File exceeds inspection limit256MiB")
        mode, flags = u16(inode, 0), u32(inode, 32)
        if stat.S_ISLNK(mode) and size <= 60 and not flags & 0x80000:
            return inode[40:40 + size]
        if flags & 0x10000000:
            raise ValueError("Inline data not supported")
        if not flags & 0x80000:
            raise ValueError("Only extent-mapped files supported")
        output = bytearray(size)
        for logical, count, physical, unwritten in self.extents(inode[40:100]):
            start = logical * self.block_size
            length = min(count * self.block_size, size - start)
            if length > 0 and not unwritten:
                output[start:start + length] = self.read(
                    physical * self.block_size, length)
        return bytes(output)

    def directory(self, number):
        if not stat.S_ISDIR(u16(self.inode(number), 0)):
            raise NotADirectoryError(number)
        data, off, entries = self.data(number), 0, {}
        while off < len(data):
            ino, length, name_len = u32(data, off), u16(data, off + 4), data[off + 6]
            if length < 8 or off + length > len(data) or name_len > length - 8:
                raise ValueError(f"Invalid directory entry at{off:#x}")
            name = data[off + 8:off + 8 + name_len].decode("utf-8")
            if ino:
                entries[name] = ino
            off += length
        return entries

    def resolve(self, path, hops=0):
        if hops > 16:
            raise ValueError("Symlink loop")
        parts = posixpath.normpath("/" + path.lstrip("/")).strip("/").split("/")
        current = 2
        if parts == [""]:
            return current
        for i, part in enumerate(parts):
            current = self.directory(current)[part]
            if stat.S_ISLNK(u16(self.inode(current), 0)):
                target = self.data(current).decode("utf-8")
                if not target.startswith("/"):
                    target = "/".join(parts[:i] + [target])
                target = posixpath.join(target, *parts[i + 1:])
                return self.resolve(target, hops + 1)
        return current


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("path")
    p.add_argument("--image", default="outputs/philips-55oled803/emulator/"
                                     "stock-emmc-107.1.143.0.img")
    p.add_argument("--partitions", default="outputs/philips-55oled803/emulator/"
                                          "partitions.json")
    p.add_argument("--partition", default="system")
    p.add_argument("--output", type=pathlib.Path)
    a = p.parse_args()
    part = next(x for x in json.loads(pathlib.Path(a.partitions).read_text())
                ["partitions"] if x["name"] == a.partition)
    fs = Ext4(a.image, part["start_byte"], part["size_bytes"])
    number = fs.resolve(a.path)
    if a.output:
        a.output.write_bytes(fs.data(number))
        print(a.output)
    elif stat.S_ISDIR(u16(fs.inode(number), 0)):
        for name, ino in fs.directory(number).items():
            inode = fs.inode(ino)
            size = u32(inode, 4) | u32(inode, 108) << 32
            print(f"{stat.filemode(u16(inode, 0))} {ino:8} {size:10} {name}")
    else:
        print(fs.data(number).decode("utf-8", errors="replace"))
