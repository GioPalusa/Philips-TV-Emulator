import struct
import tempfile
import unittest
import zlib
from pathlib import Path
from host_frame import HEADER, HostFrame, png_from_ppm


class HostFrameTests(unittest.TestCase):
    def test_stable_pixels_stale_and_inflight_frames(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "frame"
            header = HEADER.pack(0x55475048, 1, 1920, 1080, 7680, 1, 2, 1)
            path.write_bytes(header + bytes(64-len(header)) +
                             bytes((12, 34, 56, 255)) * (1920*1080))
            reader = HostFrame(path)
            ppm, count = reader.read()
            self.assertEqual(count, 1)
            self.assertTrue(ppm.startswith(b"P6\n1920 1080\n255\n"))
            self.assertEqual(ppm[-3:], bytes((12, 34, 56)))
            self.assertIsNone(reader.read())
            with path.open("r+b") as stream:
                stream.seek(24)
                stream.write(struct.pack("<QQ", 3, 2))
            self.assertIsNone(reader.read())
            with path.open("r+b") as stream:
                stream.seek(24)
                stream.write(struct.pack("<Q", 4))
            self.assertEqual(reader.read()[1], 2)
            reader.mapping.close()

    def test_invalid_header_and_missing_file(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "frame"
            reader = HostFrame(path)
            self.assertIsNone(reader.read())
            path.write_bytes(bytes(64))
            with self.assertRaises(ValueError):
                reader.read()
            reader.mapping.close()

    def test_png_pixels(self):
        data = png_from_ppm(b"P6\n2 1\n255\n" + bytes((255, 0, 0, 0, 255, 0)))
        self.assertEqual(data[:8], b"\x89PNG\r\n\x1a\n")
        pos, compressed = 8, b""
        while pos < len(data):
            size = struct.unpack_from(">I", data, pos)[0]
            name, payload = data[pos+4:pos+8], data[pos+8:pos+8+size]
            crc = struct.unpack_from(">I", data, pos+8+size)[0]
            self.assertEqual(crc, zlib.crc32(name + payload))
            if name == b"IDAT":
                compressed += payload
            pos += size + 12
        self.assertEqual(zlib.decompress(compressed), b"\0\xff\0\0\0\xff\0")


if __name__ == "__main__":
    unittest.main()
