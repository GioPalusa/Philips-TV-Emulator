"""Read the renderer's versioned, seqlocked RGBA output without a guest copy."""
import mmap
from pathlib import Path
import struct
import zlib

HEADER = struct.Struct("<6I2Q")


def png_from_ppm(ppm):
    kind, size, maximum, rgb = ppm.split(b"\n", 3)
    width, height = map(int, size.split())
    if (kind != b"P6" or maximum != b"255" or not 0 < width <= 4096 or
            not 0 < height <= 2160 or len(rgb) != width * height * 3):
        raise ValueError("Invalid RGB framebuffer")
    def chunk(name, data):
        return (struct.pack(">I", len(data)) + name + data +
                struct.pack(">I", zlib.crc32(name + data)))
    scanlines = b"".join(b"\0" + rgb[row*width*3:(row+1)*width*3]
                         for row in range(height))
    return (b"\x89PNG\r\n\x1a\n" +
            chunk(b"IHDR", struct.pack(">2I5B", width, height, 8, 2, 0, 0, 0)) +
            chunk(b"IDAT", zlib.compress(scanlines, 1)) + chunk(b"IEND", b""))


class HostFrame:
    def __init__(self, path):
        self.path = Path(path)
        self.mapping = None
        self.sequence = None

    def read(self):
        if self.mapping is None:
            try:
                with self.path.open("rb") as stream:
                    self.mapping = mmap.mmap(stream.fileno(), 0, access=mmap.ACCESS_READ)
            except (FileNotFoundError, ValueError):
                return None
        data = self.mapping
        if len(data) < 64:
            raise ValueError("Host graphics header is truncated")
        magic, version, width, height, stride, fmt, sequence, count = HEADER.unpack_from(data)
        if (magic, version, width, height, stride, fmt) != (
                0x55475048, 1, 1920, 1080, 7680, 1):
            raise ValueError("Unsupported host graphics frame format")
        if len(data) != 64 + stride * height:
            raise ValueError("Host graphics pixel size is invalid")
        if sequence & 1 or not count or sequence == self.sequence:
            return None
        rgba = data[64:]
        # The producer increments sequence before and after writing. Discard a
        # concurrent copy; keep displaying the last complete frame.
        if struct.unpack_from("<Q", data, 24)[0] != sequence:
            return None
        rgb = bytearray(width * height * 3)
        rgb[0::3], rgb[1::3], rgb[2::3] = rgba[0::4], rgba[1::4], rgba[2::4]
        self.sequence = sequence
        return f"P6\n{width} {height}\n255\n".encode() + rgb, count
