import struct
import unittest
from decode_spi import decode_hardware0, decode_record


class PacketTest(unittest.TestCase):
    def test_big_endian_bgr_and_current_fields(self):
        header = 0x96400000 | 3 | (4 << 7) | (5 << 14)
        packet = header.to_bytes(4, "big") + struct.pack(">HHH", 0x0300, 0x0200, 0x0100) * 4
        decoded = decode_hardware0(packet)
        self.assertEqual(decoded, [((0x0100, 0x0200, 0x0300), [3, 4, 5])] * 4)
        event = next(decode_record({"schema": "mt5891-ambilight-spi-v1",
                                   "sequence": 1, "complete": True,
                                   "data_hex": packet.hex()}))
        self.assertEqual(event["rgb_application"], [1, 2, 3])

    def test_rejects_unknown_or_truncated(self):
        with self.assertRaises(ValueError):
            decode_hardware0(b"\x96")
        with self.assertRaises(ValueError):
            decode_hardware0(bytes(28))
        with self.assertRaises(ValueError):
            list(decode_record({"schema": "mt5891-ambilight-spi-v1", "complete": False}))


if __name__ == "__main__":
    unittest.main()
