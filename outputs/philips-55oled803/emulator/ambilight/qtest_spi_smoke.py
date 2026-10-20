#!/usr/bin/env python3
"""Exercise actual QEMU MMIO with synthetic SPI bytes; does not boot Android."""
import argparse
import json
import os
from pathlib import Path
import select
import struct
import subprocess
import tempfile
from decode_spi import decode_record


def run(binary, output_directory):
    output_directory.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="ambilight-qtest-", dir=output_directory) as directory:
        root = Path(directory)
        capture = root / "capture.jsonl"
        env = dict(os.environ, PHILIPS_AMBILIGHT_LOG=str(capture))
        command = [str(binary.resolve()), "-machine", "virt,gic-version=2,highmem=off",
                   "-cpu", "cortex-a53,aarch64=off", "-smp", "1", "-m", "880M",
                   "-accel", "tcg", "-S", "-nodefaults", "-display", "none",
                   "-monitor", "none", "-serial", "none", "-nic", "none",
                   "-qtest", "stdio", "-qtest-log", "/dev/null"]
        with (root / "stderr.log").open("wb") as stderr:
            process = subprocess.Popen(command, env=env, stdin=subprocess.PIPE,
                                       stdout=subprocess.PIPE, stderr=stderr)
            def qtest(command):
                process.stdin.write((command + "\n").encode())
                process.stdin.flush()
                if not select.select([process.stdout], [], [], 5)[0]:
                    raise TimeoutError(f"QEMU did not answer {command}")
                line = process.stdout.readline().decode().strip()
                if not line.startswith("OK"):
                    raise RuntimeError(f"{command}: {line}")
                return line[2:].strip()
            try:
                assert int(qtest("readb 0xf002944c"), 0) & 0x20
                rgb = [(65535, 0, 0), (0, 65535, 0), (0, 0, 65535), (32768, 16384, 8192)]
                packet = bytes.fromhex("96400000") + b"".join(
                    struct.pack(">HHH", blue, green, red) for red, green, blue in rgb)
                qtest("writew 0xf0029440 0x70")  # 7 groups × 4 bytes
                qtest("writew 0xf0029442 0x40")
                qtest("writel 0xf0029400 0")
                for byte in packet:
                    qtest(f"writel 0xf0029408 {byte}")
                qtest("writeb 0xf002944c 1")
                assert int(qtest("readb 0xf002944c"), 0) == 0x20
                assert int(qtest("readw 0xf0029404"), 0) == 0
                records = [json.loads(line) for line in capture.read_text().splitlines()]
                assert len(records) == 1, records
                record = records[0]
                assert record["complete"] is True, record
                assert bytes.fromhex(record["data_hex"]) == packet, record
                decoded = list(decode_record(record))
                assert [e["rgb_raw_u16"] for e in decoded] == [list(c) for c in rgb]
                report = {
                    "result": "passed",
                    "origin": "synthetic-qtest-mmio",
                    "android_booted": False,
                    "stock_ambilight_algorithm_executed": False,
                    "qemu": str(binary.resolve()),
                    "checks": ["ready-bit", "byte FIFO via 32-bit writes", "M*N dimensions",
                               "capture exact bytes", "completion", "hardware-0 decode"],
                    "capture": record,
                    "decoded_wire_rgb_u16": [e["rgb_raw_u16"] for e in decoded],
                }
                destination = output_directory / "qtest-spi-smoke.json"
                destination.write_text(json.dumps(report, indent=2) + "\n")
                print(destination)
            finally:
                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
                if process.returncode not in (0, -15):
                    print((root / "stderr.log").read_text())


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("qemu", type=Path)
    parser.add_argument("--output-directory", type=Path, required=True)
    arguments = parser.parse_args()
    run(arguments.qemu, arguments.output_directory)
