import unittest
from mtamb import PixelBoundary, SET_STATIC, GET_STATIC, GET_PROCESSED, ARGUMENT, RGB


class BoundaryTest(unittest.TestCase):
    def setUp(self):
        self.memory = bytearray(256)
        self.events = []
        self.device = PixelBoundary(self.events.append)
        self.memory[16:24] = ARGUMENT.pack(1, 64)

    def read(self, address, size):
        return bytes(self.memory[address:address + size])

    def write(self, address, data):
        self.memory[address:address + len(data)] = data

    def test_verified_layout_and_q8_conversion(self):
        self.memory[64:76] = RGB.pack(255 << 8, 128 << 8, 3 << 8)
        self.device.ioctl(SET_STATIC, 16, self.read, self.write)
        self.assertEqual(self.events[0]["rgb_application"], [255, 128, 3])
        self.assertEqual(self.events[0]["pixel"], 1)
        self.memory[64:76] = bytes(12)
        self.device.ioctl(GET_STATIC, 16, self.read, self.write)
        self.assertEqual(RGB.unpack(self.memory[64:76]), (65280, 32768, 768))

    def test_does_not_invent_processed_output(self):
        self.memory[64:76] = RGB.pack(65280, 0, 0)
        self.device.ioctl(SET_STATIC, 16, self.read, self.write)
        with self.assertRaises(LookupError):
            self.device.ioctl(GET_PROCESSED, 16, self.read, self.write)

    def test_rejects_unknown_operation_and_zero_index(self):
        with self.assertRaises(NotImplementedError):
            self.device.ioctl(0x1234, 16, self.read, self.write)
        self.memory[16:24] = ARGUMENT.pack(0, 64)
        with self.assertRaises(ValueError):
            self.device.ioctl(SET_STATIC, 16, self.read, self.write)


if __name__ == "__main__":
    unittest.main()
